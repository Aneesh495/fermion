namespace Fermion.ErrorCorrection {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;
    open Fermion.Core;

    // Returns the 6 stabilizer checks for the canonical [[7, 1, 3]] Steane code
    // Check 0: bits with binary digit 1 in position 0 -> qubits 0, 2, 4, 6
    // Check 1: bits with binary digit 1 in position 1 -> qubits 1, 2, 5, 6
    // Check 2: bits with binary digit 1 in position 2 -> qubits 3, 4, 5, 6
    function GetSteaneStabilizerChecks() : StabilizerCheck[] {
        return [
            // X-type checks (detect Z errors)
            StabilizerCheck(PauliX, 4, [0, 2, 4, 6], 0),
            StabilizerCheck(PauliX, 4, [1, 2, 5, 6], 1),
            StabilizerCheck(PauliX, 4, [3, 4, 5, 6], 2),
            // Z-type checks (detect X errors)
            StabilizerCheck(PauliZ, 4, [0, 2, 4, 6], 3),
            StabilizerCheck(PauliZ, 4, [1, 2, 5, 6], 4),
            StabilizerCheck(PauliZ, 4, [3, 4, 5, 6], 5)
        ];
    }

    // Encodes 7 physical qubits into the logical [[7, 1, 3]] Steane code state
    operation EncodeSteaneCode(dataQubits : Qubit[]) : Unit {
        if (Length(dataQubits) < 7) {
            return ();
        }

        // Canonical CSS encoding circuit
        H(dataQubits[0]);
        H(dataQubits[1]);
        H(dataQubits[3]);

        CNOT(dataQubits[0], dataQubits[2]);
        CNOT(dataQubits[1], dataQubits[2]);

        CNOT(dataQubits[0], dataQubits[4]);
        CNOT(dataQubits[3], dataQubits[4]);

        CNOT(dataQubits[1], dataQubits[5]);
        CNOT(dataQubits[3], dataQubits[5]);

        CNOT(dataQubits[0], dataQubits[6]);
        CNOT(dataQubits[1], dataQubits[6]);
        CNOT(dataQubits[3], dataQubits[6]);
    }

    // Maps a 3-bit syndrome vector (s0, s1, s2) directly to the failing qubit index (0 to 6)
    // Returns -1 if no error is detected (all syndromes false)
    function SteaneSyndromeToErrorLocation(s0 : Bool, s1 : Bool, s2 : Bool) : Int {
        let b0 = s0 ? 1 | 0;
        let b1 = s1 ? 2 | 0;
        let b2 = s2 ? 4 | 0;
        let val = b0 + b1 + b2;

        if (val == 0) {
            return -1;
        }
        return val - 1;
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
