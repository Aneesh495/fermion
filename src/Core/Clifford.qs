namespace Fermion.Core {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;

    // Single-qubit Phase gate S = diag(1, i)
    operation ApplyS(target : Qubit) : Unit is Adj + Ctl {
        S(target);
    }

    // Single-qubit Phase dagger gate S^dagger = diag(1, -i)
    operation ApplySAdj(target : Qubit) : Unit is Adj + Ctl {
        Adjoint S(target);
    }

    // Controlled-Z gate between control and target
    operation ApplyCZ(control : Qubit, target : Qubit) : Unit is Adj + Ctl {
        CZ(control, target);
    }

    // Two-qubit SWAP gate
    operation ApplySWAP(q1 : Qubit, q2 : Qubit) : Unit is Adj + Ctl {
        SWAP(q1, q2);
    }

    // Classical symplectic update for Hadamard gate applied to qubit q:
    // (x | z) -> (z | x) with phase update r' = (r + 2 * (x_q * z_q)) mod 4
    function UpdateSymplecticHadamard(vec : SymplecticVector, q : Int) : SymplecticVector {
        let xq = vec.XBits[q];
        let zq = vec.ZBits[q];
        mutable newX = vec.XBits;
        mutable newZ = vec.ZBits;

        set newX w/= q <- zq;
        set newZ w/= q <- xq;

        let phaseDelta = (xq and zq) ? 2 | 0;
        let newPhase = (vec.Phase + phaseDelta) % 4;

        return SymplecticVector(vec.NumQubits, newX, newZ, newPhase);
    }

    // Classical symplectic update for Phase gate S applied to qubit q:
    // (x | z) -> (x | x ^ z) with phase update r' = (r + (x_q * (1 - 2*z_q))) mod 4
    function UpdateSymplecticPhase(vec : SymplecticVector, q : Int) : SymplecticVector {
        let xq = vec.XBits[q];
        let zq = vec.ZBits[q];
        mutable newZ = vec.ZBits;

        set newZ w/= q <- xq != zq;

        let phaseDelta = xq ? (zq ? 3 | 1) | 0;
        let newPhase = (vec.Phase + phaseDelta) % 4;

        return SymplecticVector(vec.NumQubits, vec.XBits, newZ, newPhase);
    }

    // Classical symplectic update for CNOT gate with control c and target t:
    // x_t -> x_t ^ x_c, z_c -> z_c ^ z_t
    function UpdateSymplecticCNOT(vec : SymplecticVector, c : Int, t : Int) : SymplecticVector {
        let xc = vec.XBits[c];
        let zc = vec.ZBits[c];
        let xt = vec.XBits[t];
        let zt = vec.ZBits[t];

        mutable newX = vec.XBits;
        mutable newZ = vec.ZBits;

        set newX w/= t <- xt != xc;
        set newZ w/= c <- zc != zt;

        let phaseDelta = (xc and zt and (not (xt != zc))) ? 2 | 0;
        let newPhase = (vec.Phase + phaseDelta) % 4;

        return SymplecticVector(vec.NumQubits, newX, newZ, newPhase);
    }

    // Measures a stabilizer generator non-destructively onto an ancilla
    // Returns Result (Zero for +1 eigenvalue, One for -1 eigenvalue)
    operation MeasureStabilizerGenerator(
        pauliOps : Pauli[],
        qubitIndices : Int[],
        register : Qubit[],
        ancilla : Qubit
    ) : Result {
        H(ancilla);
        let n = Length(pauliOps);
        for idx in 0..n - 1 {
            let p = pauliOps[idx];
            let q = register[qubitIndices[idx]];
            if (p == PauliX) {
                Controlled X([ancilla], q);
            } elif (p == PauliY) {
                Controlled Y([ancilla], q);
            } elif (p == PauliZ) {
                Controlled Z([ancilla], q);
            }
        }
        H(ancilla);
        let res = M(ancilla);
        Reset(ancilla);
        return res;
    }

    // Applies a Clifford circuit sequence specified as gate descriptors
    operation ApplyCliffordSequence(
        gateTypes : Int[], // 0: H, 1: S, 2: CNOT
        targets : Int[],
        controls : Int[],
        register : Qubit[]
    ) : Unit {
        let numGates = Length(gateTypes);
        for idx in 0..numGates - 1 {
            let g = gateTypes[idx];
            let t = targets[idx];
            if (g == 0) {
                H(register[t]);
            } elif (g == 1) {
                S(register[t]);
            } elif (g == 2) {
                let c = controls[idx];
                CNOT(register[c], register[t]);
            }
        }
    }
}
