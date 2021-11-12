namespace Fermion.ErrorCorrection {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;
    open Fermion.Core;

    // Face color classification for 2D color code
    // 0: Red, 1: Green, 2: Blue
    struct ColorCodeFace {
        Color : Int,
        SupportQubits : Int[]
    }

    // Returns the 3 colored faces for the distance-3 triangular color code on 7 qubits
    function GetDistance3ColorCodeFaces() : ColorCodeFace[] {
        return [
            ColorCodeFace(0, [0, 1, 2, 3]), // Red face
            ColorCodeFace(1, [1, 2, 4, 5]), // Green face
            ColorCodeFace(2, [2, 3, 5, 6])  // Blue face
        ];
    }

    // In a 2D color code, each face supports BOTH an X-type and a Z-type stabilizer
    function GetColorCodeStabilizerChecks() : StabilizerCheck[] {
        let faces = GetDistance3ColorCodeFaces();
        return [
            // X-type stabilizers
            StabilizerCheck(PauliX, 4, faces[0].SupportQubits, 0),
            StabilizerCheck(PauliX, 4, faces[1].SupportQubits, 1),
            StabilizerCheck(PauliX, 4, faces[2].SupportQubits, 2),
            // Z-type stabilizers
            StabilizerCheck(PauliZ, 4, faces[0].SupportQubits, 3),
            StabilizerCheck(PauliZ, 4, faces[1].SupportQubits, 4),
            StabilizerCheck(PauliZ, 4, faces[2].SupportQubits, 5)
        ];
    }

    // The entire Clifford group is transversal on 2D color codes:
    // Transversal logical Hadamard: H_L = prod_k H_k
    operation ApplyColorCodeHadamard(dataQubits : Qubit[]) : Unit is Adj + Ctl {
        for q in dataQubits {
            H(q);
        }
    }

    // Transversal logical Phase gate S: S_L = prod_k S_k
    operation ApplyColorCodePhase(dataQubits : Qubit[]) : Unit is Adj + Ctl {
        for q in dataQubits {
            S(q);
        }
    }

    // Transversal logical CNOT: CNOT_L = prod_k CNOT(control_k, target_k)
    operation ApplyColorCodeCNOT(controlBlock : Qubit[], targetBlock : Qubit[]) : Unit is Adj + Ctl {
        let n = Length(controlBlock);
        for idx in 0..n - 1 {
            CNOT(controlBlock[idx], targetBlock[idx]);
        }
    }
}
