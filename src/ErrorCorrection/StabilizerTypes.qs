namespace Fermion.ErrorCorrection {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;
    open Fermion.Core;

    // Binary check matrix descriptor: H = [ H_X | H_Z ]
    struct CheckMatrix {
        NumDataQubits : Int,
        NumChecks : Int,
        XChecks : Bool[][], // size: NumChecks x NumDataQubits
        ZChecks : Bool[][]
    }

    // Syndrome extraction result vector
    struct SyndromeRecord {
        NumChecks : Int,
        SyndromeBits : Bool[],
        MeasurementCycle : Int
    }

    // Creates an empty binary check matrix for n data qubits and m check generators
    function CreateEmptyCheckMatrix(n : Int, m : Int) : CheckMatrix {
        mutable xc = [[false, size = n], size = m];
        mutable zc = [[false, size = n], size = m];
        return CheckMatrix(n, m, xc, zc);
    }

    // Verifies the CSS commutativity condition: H_X * H_Z^T == 0 mod 2
    function VerifyCSSCommutation(matrix : CheckMatrix) : Bool {
        for i in 0..matrix.NumChecks - 1 {
            for j in 0..matrix.NumChecks - 1 {
                mutable inner = 0;
                for k in 0..matrix.NumDataQubits - 1 {
                    let xVal = matrix.XChecks[i][k] ? 1 | 0;
                    let zVal = matrix.ZChecks[j][k] ? 1 | 0;
                    set inner = (inner + xVal * zVal) % 2;
                }
                if (inner != 0) {
                    return false;
                }
            }
        }
        return true;
    }

    // Extracts the syndrome bit of a single stabilizer check generator onto an ancilla qubit
    operation ExtractSingleCheckSyndrome(
        check : StabilizerCheck,
        dataRegister : Qubit[],
        ancilla : Qubit
    ) : Bool {
        H(ancilla);
        for qIdx in check.Support {
            let dataQubit = dataRegister[qIdx];
            if (check.CheckType == PauliX) {
                // Ancilla controls X on data: CNOT(ancilla, data)
                CNOT(ancilla, dataQubit);
            } elif (check.CheckType == PauliZ) {
                // Data controls X on ancilla: CNOT(data, ancilla)
                CNOT(dataQubit, ancilla);
            }
        }
        H(ancilla);
        let res = M(ancilla);
        Reset(ancilla);
        return res == One;
    }

    // Measures all stabilizer checks in a code and returns the complete syndrome vector
    operation ExtractSyndromeVector(
        checks : StabilizerCheck[],
        dataRegister : Qubit[]
    ) : Bool[] {
        let numChecks = Length(checks);
        mutable syndrome = [false, size = numChecks];
        use ancilla = Qubit();

        for idx in 0..numChecks - 1 {
            let bit = ExtractSingleCheckSyndrome(checks[idx], dataRegister, ancilla);
            set syndrome w/= idx <- bit;
        }

        return syndrome;
    }
}
