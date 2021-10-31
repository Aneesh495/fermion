namespace Fermion.ErrorCorrection {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;
    open Fermion.Core;

    // Returns the 8 stabilizer generators for the [[9, 1, 3]] Shor code
    function GetShorCodeStabilizerChecks() : StabilizerCheck[] {
        return [
            // Triad 1 bit-flip checks
            StabilizerCheck(PauliZ, 2, [0, 1], 0),
            StabilizerCheck(PauliZ, 2, [1, 2], 1),
            // Triad 2 bit-flip checks
            StabilizerCheck(PauliZ, 2, [3, 4], 2),
            StabilizerCheck(PauliZ, 2, [4, 5], 3),
            // Triad 3 bit-flip checks
            StabilizerCheck(PauliZ, 2, [6, 7], 4),
            StabilizerCheck(PauliZ, 2, [7, 8], 5),
            // Phase-flip checks comparing triads
            StabilizerCheck(PauliX, 6, [0, 1, 2, 3, 4, 5], 6),
            StabilizerCheck(PauliX, 6, [3, 4, 5, 6, 7, 8], 7)
        ];
    }

    // Encodes an arbitrary single physical qubit into the [[9, 1, 3]] Shor logical code state
    operation EncodeShorCode(dataQubits : Qubit[]) : Unit {
        if (Length(dataQubits) < 9) {
            return ();
        }

        // 1. Phase flip code encoding on qubits 0, 3, 6
        CNOT(dataQubits[0], dataQubits[3]);
        CNOT(dataQubits[0], dataQubits[6]);

        H(dataQubits[0]);
        H(dataQubits[3]);
        H(dataQubits[6]);

        // 2. Bit flip code encoding on each triad (0,1,2), (3,4,5), (6,7,8)
        CNOT(dataQubits[0], dataQubits[1]);
        CNOT(dataQubits[0], dataQubits[2]);

        CNOT(dataQubits[3], dataQubits[4]);
        CNOT(dataQubits[3], dataQubits[5]);

        CNOT(dataQubits[6], dataQubits[7]);
        CNOT(dataQubits[6], dataQubits[8]);
    }

    // Corrects bit-flip errors in a single 3-qubit triad (qubits q0, q1, q2)
    operation CorrectTriadBitFlips(q0 : Qubit, q1 : Qubit, q2 : Qubit) : Unit {
        use anc0 = Qubit();
        use anc1 = Qubit();

        // Parity checks Z_0 Z_1 and Z_1 Z_2
        H(anc0);
        CZ(anc0, q0);
        CZ(anc0, q1);
        H(anc0);
        let s0 = M(anc0) == One;

        H(anc1);
        CZ(anc1, q1);
        CZ(anc1, q2);
        H(anc1);
        let s1 = M(anc1) == One;

        Reset(anc0);
        Reset(anc1);

        if (s0 and not s1) {
            X(q0);
        } elif (s0 and s1) {
            X(q1);
        } elif (not s0 and s1) {
            X(q2);
        }
    }

    // Runs full active error correction cycle on the Shor code
    operation CorrectShorCodeErrors(dataQubits : Qubit[]) : Unit {
        // Correct bit-flips in each triad
        CorrectTriadBitFlips(dataQubits[0], dataQubits[1], dataQubits[2]);
        CorrectTriadBitFlips(dataQubits[3], dataQubits[4], dataQubits[5]);
        CorrectTriadBitFlips(dataQubits[6], dataQubits[7], dataQubits[8]);

        // Correct phase-flips across triads using X checks
        use ancPhase0 = Qubit();
        use ancPhase1 = Qubit();

        H(ancPhase0);
        for idx in 0..5 {
            CNOT(ancPhase0, dataQubits[idx]);
        }
        H(ancPhase0);
        let sp0 = M(ancPhase0) == One;

        H(ancPhase1);
        for idx in 3..8 {
            CNOT(ancPhase1, dataQubits[idx]);
        }
        H(ancPhase1);
        let sp1 = M(ancPhase1) == One;

        Reset(ancPhase0);
        Reset(ancPhase1);

        if (sp0 and not sp1) {
            Z(dataQubits[0]);
        } elif (sp0 and sp1) {
            Z(dataQubits[3]);
        } elif (not sp0 and sp1) {
            Z(dataQubits[6]);
        }
    }
}
