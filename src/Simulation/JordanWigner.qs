namespace Fermion.Simulation {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;
    open Fermion.Core;

    // Generates the Z-string indices between p and q (exclusive)
    function IntermediateZIndices(p : Int, q : Int) : Int[] {
        let low = p < q ? p | q;
        let high = p < q ? q | p;
        if (high - low <= 1) {
            return [];
        }
        mutable res = [];
        for idx in low + 1..high - 1 {
            set res += [idx];
        }
        return res;
    }

    // Maps a number operator n_p = a_p^dagger a_p = (I - Z_p) / 2 to Pauli words
    function JordanWignerNumberOperator(p : Int, coeff : Double) : PauliWord[] {
        let idTerm = CreatePauliWord(coeff * 0.5, [PauliI], [p]);
        let zTerm = CreatePauliWord(-coeff * 0.5, [PauliZ], [p]);
        return [idTerm, zTerm];
    }

    // Maps a 1-body hopping term: coeff * (a_p^dagger a_q + a_q^dagger a_p)
    // = coeff/2 * (X_p Z_{p+1}...Z_{q-1} X_q + Y_p Z_{p+1}...Z_{q-1} Y_q)
    function JordanWignerHopping(p : Int, q : Int, coeff : Double) : PauliWord[] {
        if (p == q) {
            return JordanWignerNumberOperator(p, coeff);
        }

        let low = p < q ? p | q;
        let high = p < q ? q | p;
        let zIndices = IntermediateZIndices(low, high);
        let numZ = Length(zIndices);

        // Term 1: X ... Z ... X
        mutable qubits1 = [low];
        mutable ops1 = [PauliX];
        for z in zIndices {
            set qubits1 += [z];
            set ops1 += [PauliZ];
        }
        set qubits1 += [high];
        set ops1 += [PauliX];

        // Term 2: Y ... Z ... Y
        mutable qubits2 = [low];
        mutable ops2 = [PauliY];
        for z in zIndices {
            set qubits2 += [z];
            set ops2 += [PauliZ];
        }
        set qubits2 += [high];
        set ops2 += [PauliY];

        let weight = coeff * 0.5;
        let term1 = CreatePauliWord(weight, ops1, qubits1);
        let term2 = CreatePauliWord(weight, ops2, qubits2);

        return [term1, term2];
    }

    // Maps a density-density interaction term: coeff * n_p n_q = coeff * (I - Z_p - Z_q + Z_p Z_q) / 4
    function JordanWignerDensityDensity(p : Int, q : Int, coeff : Double) : PauliWord[] {
        if (p == q) {
            return JordanWignerNumberOperator(p, coeff);
        }
        let w = coeff * 0.25;
        let idTerm = CreatePauliWord(w, [PauliI], [p]);
        let zpTerm = CreatePauliWord(-w, [PauliZ], [p]);
        let zqTerm = CreatePauliWord(-w, [PauliZ], [q]);
        let zzTerm = CreatePauliWord(w, [PauliZ, PauliZ], [p, q]);

        return [idTerm, zpTerm, zqTerm, zzTerm];
    }

    // Directly applies the unitary evolution exp(-i * theta * (a_p^dagger a_q + a_q^dagger a_p))
    // on a quantum register using Jordan-Wigner decomposition
    operation ApplyFermionicHoppingEvolution(
        theta : Double,
        p : Int,
        q : Int,
        register : Qubit[]
    ) : Unit {
        if (p == q) {
            // exp(-i * theta * n_p) = exp(-i * theta * (I - Z_p) / 2)
            // Global phase e^(-i * theta/2) times Rz(-theta, register[p])
            Rz(-theta, register[p]);
            return ();
        }

        let words = JordanWignerHopping(p, q, 1.0);
        for w in words {
            // Angle scaled by coefficient (w.Coeff = 0.5)
            // ExpPauliWord takes rotation angle = 2 * (theta * w.Coeff) = theta
            ExpPauliWord(theta, w, register);
        }
    }

    // Directly applies the density-density interaction evolution:
    // exp(-i * theta * n_p n_q)
    operation ApplyDensityDensityEvolution(
        theta : Double,
        p : Int,
        q : Int,
        register : Qubit[]
    ) : Unit {
        if (p == q) {
            Rz(-theta, register[p]);
            return ();
        }

        // Decomposes into single-qubit Z rotations and a two-qubit ZZ rotation:
        // exp(-i * theta * (I - Z_p - Z_q + Z_p Z_q) / 4)
        let singleAngle = theta * 0.25;
        Rz(-singleAngle, register[p]);
        Rz(-singleAngle, register[q]);

        // Two-qubit ZZ rotation with angle theta * 0.25:
        CNOT(register[p], register[q]);
        Rz(singleAngle, register[q]);
        CNOT(register[p], register[q]);
    }
}
