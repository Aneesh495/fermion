namespace Fermion.ErrorCorrection {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;
    open Fermion.Core;

    // Returns the 6 stabilizer checks for the [[7, 1, 3]] Steane code
    // 3 X-type stabilizers and 3 Z-type stabilizers
    function GetSteaneStabilizerChecks() : StabilizerCheck[] {
        return [
            // X checks (Hamming parity checks)
            StabilizerCheck(PauliX, 4, [0, 1, 2, 3], 0),
            StabilizerCheck(PauliX, 4, [1, 2, 4, 5], 1),
            StabilizerCheck(PauliX, 4, [2, 3, 5, 6], 2),
            // Z checks
            StabilizerCheck(PauliZ, 4, [0, 1, 2, 3], 3),
            StabilizerCheck(PauliZ, 4, [1, 2, 4, 5], 4),
            StabilizerCheck(PauliZ, 4, [2, 3, 5, 6], 5)
        ];
    }

    // Encodes a single physical qubit (at index 0) and 6 auxiliary data qubits (initialized to |0>)
    // into the logical [[7, 1, 3]] Steane code state
    operation EncodeSteaneCode(dataQubits : Qubit[]) : Unit {
        // Verification of register size
        if (Length(dataQubits) < 7) {
            return ();
        }

        // Steane encoding circuit using transversal Hadamard and CNOT gates
        H(dataQubits[4]);
        H(dataQubits[5]);
        H(dataQubits[6]);

        CNOT(dataQubits[6], dataQubits[1]);
        CNOT(dataQubits[6], dataQubits[2]);
        CNOT(dataQubits[5], dataQubits[0]);
        CNOT(dataQubits[5], dataQubits[2]);
        CNOT(dataQubits[4], dataQubits[0]);
        CNOT(dataQubits[4], dataQubits[1]);

        CNOT(dataQubits[0], dataQubits[3]);
        CNOT(dataQubits[1], dataQubits[3]);
        CNOT(dataQubits[2], dataQubits[3]);
    }

    // Maps a 3-bit syndrome vector (s0, s1, s2) to the failing qubit index (0 to 6)
    // Returns -1 if no error is detected (all syndromes false)
    function SteaneSyndromeToErrorLocation(s0 : Bool, s1 : Bool, s2 : Bool) : Int {
        let b0 = s0 ? 1 | 0;
        let b1 = s1 ? 2 | 0;
        let b2 = s2 ? 4 | 0;
        let val = b0 + b1 + b2;

        if (val == 0) { return -1; }
        if (val == 1) { return 0; } // S0 only: qubit 0
        if (val == 2) { return 4; } // S1 only: qubit 4
        if (val == 3) { return 1; } // S0 and S1: qubit 1
        if (val == 4) { return 6; } // S2 only: qubit 6
        if (val == 5) { return 3; } // S0 and S2: qubit 3
        if (val == 6) { return 5; } // S1 and S2: qubit 5
        if (val == 7) { return 2; } // S0, S1, and S2: qubit 2
        return -1;
    }

    // Runs a full syndrome measurement and active correction cycle on the Steane code register
    operation CorrectSteaneCodeErrors(dataQubits : Qubit[]) : (Int, Int) {
        let checks = GetSteaneStabilizerChecks();
        use ancilla = Qubit();

        // 1. Measure 3 X-stabilizers (detects Z errors)
        let sx0 = ExtractSingleCheckSyndrome(checks[0], dataQubits, ancilla);
        let sx1 = ExtractSingleCheckSyndrome(checks[1], dataQubits, ancilla);
        let sx2 = ExtractSingleCheckSyndrome(checks[2], dataQubits, ancilla);
        let zErrorLocation = SteaneSyndromeToErrorLocation(sx0, sx1, sx2);

        // Apply Pauli Z correction
        if (zErrorLocation >= 0 and zErrorLocation < 7) {
            Z(dataQubits[zErrorLocation]);
        }

        // 2. Measure 3 Z-stabilizers (detects X errors)
        let sz0 = ExtractSingleCheckSyndrome(checks[3], dataQubits, ancilla);
        let sz1 = ExtractSingleCheckSyndrome(checks[4], dataQubits, ancilla);
        let sz2 = ExtractSingleCheckSyndrome(checks[5], dataQubits, ancilla);
        let xErrorLocation = SteaneSyndromeToErrorLocation(sz0, sz1, sz2);

        // Apply Pauli X correction
        if (xErrorLocation >= 0 and xErrorLocation < 7) {
            X(dataQubits[xErrorLocation]);
        }

        return (xErrorLocation, zErrorLocation);
    }

    // Transversal logical Hadamard operation on the Steane code
    operation ApplyLogicalHadamard(dataQubits : Qubit[]) : Unit is Adj + Ctl {
        for idx in 0..6 {
            H(dataQubits[idx]);
        }
    }

    // Transversal logical Pauli X operation on the Steane code
    operation ApplyLogicalPauliX(dataQubits : Qubit[]) : Unit is Adj + Ctl {
        for idx in 0..6 {
            X(dataQubits[idx]);
        }
    }

    // Transversal logical Pauli Z operation on the Steane code
    operation ApplyLogicalPauliZ(dataQubits : Qubit[]) : Unit is Adj + Ctl {
        for idx in 0..6 {
            Z(dataQubits[idx]);
        }
    }

    // Transversal logical CNOT gate between two Steane code blocks
    operation ApplyLogicalCNOT(controlBlock : Qubit[], targetBlock : Qubit[]) : Unit is Adj + Ctl {
        for idx in 0..6 {
            CNOT(controlBlock[idx], targetBlock[idx]);
        }
    }
}
