namespace Fermion.Simulation {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;
    open Fermion.Core;

    // Computes the Fenwick tree lowbit: isolation of the lowest set bit (x & -x)
    function FenwickLowBit(x : Int) : Int {
        if (x <= 0) {
            return 0;
        }
        return x &&& (-x);
    }

    // Parity set P(j): indices of qubits that compute the cumulative parity for orbital j
    // In Bravyi-Kitaev, P(j) is obtained by traversing the binary tree from j down to 0
    function BravyiKitaevParitySet(j : Int) : Int[] {
        if (j <= 0) {
            return [];
        }
        mutable res = [];
        mutable curr = j;
        for _ in 0..30 {
            if (curr <= 0) {
                return res;
            }
            let low = FenwickLowBit(curr);
            let parent = curr - low;
            if (parent >= 0 and parent != curr) {
                set res += [parent];
            }
            set curr = parent;
        }
        return res;
    }

    // Update set U(j): indices of qubits whose parity is affected when orbital j changes occupancy
    function BravyiKitaevUpdateSet(j : Int, numOrbitals : Int) : Int[] {
        mutable res = [];
        mutable curr = j + 1; // 1-based indexing for Fenwick traversal
        for _ in 0..30 {
            let low = FenwickLowBit(curr);
            let nextVal = curr + low;
            if (nextVal <= numOrbitals) {
                set res += [nextVal - 1]; // convert back to 0-based
                set curr = nextVal;
            } else {
                return res;
            }
        }
        return res;
    }

    // Flip set F(j): indices of qubits that determine orbital occupancy without cumulative parity
    function BravyiKitaevFlipSet(j : Int) : Int[] {
        let low = FenwickLowBit(j + 1);
        if (low <= 1) {
            return [];
        }
        mutable res = [];
        mutable curr = j;
        let limit = j + 1 - low;
        for _ in 0..30 {
            if (curr < limit) {
                return res;
            }
            set res += [curr];
            let cLow = FenwickLowBit(curr + 1);
            set curr = curr - cLow;
        }
        return res;
    }

    // Maps a number operator n_j in the Bravyi-Kitaev basis
    // n_j = (I - Z_j * prod_{k in F(j)} Z_k) / 2
    function BravyiKitaevNumberOperator(j : Int, coeff : Double) : PauliWord[] {
        let flip = BravyiKitaevFlipSet(j);
        mutable qubits = [j];
        mutable ops = [PauliZ];
        for f in flip {
            set qubits += [f];
            set ops += [PauliZ];
        }

        let idTerm = CreatePauliWord(coeff * 0.5, [PauliI], [j]);
        let zTerm = CreatePauliWord(-coeff * 0.5, ops, qubits);
        return [idTerm, zTerm];
    }

    // Maps a 1-body hopping term between orbitals p and q in the Bravyi-Kitaev basis
    function BravyiKitaevHopping(p : Int, q : Int, numOrbitals : Int, coeff : Double) : PauliWord[] {
        if (p == q) {
            return BravyiKitaevNumberOperator(p, coeff);
        }

        let low = p < q ? p | q;
        let high = p < q ? q | p;

        let uLow = BravyiKitaevUpdateSet(low, numOrbitals);
        let pHigh = BravyiKitaevParitySet(high);

        // Term 1: X_low (prod_u X_u) Z_high (prod_p Z_p)
        mutable q1 = [low];
        mutable o1 = [PauliX];
        for u in uLow {
            set q1 += [u];
            set o1 += [PauliX];
        }
        for pr in pHigh {
            set q1 += [pr];
            set o1 += [PauliZ];
        }
        set q1 += [high];
        set o1 += [PauliX];

        // Term 2: Y_low (prod_u X_u) Z_high (prod_p Z_p)
        mutable q2 = [low];
        mutable o2 = [PauliY];
        for u in uLow {
            set q2 += [u];
            set o2 += [PauliX];
        }
        for pr in pHigh {
            set q2 += [pr];
            set o2 += [PauliZ];
        }
        set q2 += [high];
        set o2 += [PauliY];

        let weight = coeff * 0.5;
        let term1 = CreatePauliWord(weight, o1, q1);
        let term2 = CreatePauliWord(weight, o2, q2);

        return [term1, term2];
    }
}
