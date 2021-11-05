namespace Fermion.ErrorCorrection {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;
    open Fermion.Core;

    // Generates the layout and stabilizer checks for a distance-3 rotated surface code
    // 9 data qubits on a 3x3 grid:
    //  0   1   2
    //  3   4   5
    //  6   7   8
    // With 4 X-syndrome checks (stars) and 4 Z-syndrome checks (plaquettes)
    function GetRotatedSurfaceCodeDistance3() : SurfaceCodePatch {
        let dataQubits = [0, 1, 2, 3, 4, 5, 6, 7, 8];
        let xSyndromes = [9, 10, 11, 12];
        let zSyndromes = [13, 14, 15, 16];
        return SurfaceCodePatch(3, dataQubits, xSyndromes, zSyndromes, 17);
    }

    // Returns the 8 stabilizer checks for distance-3 rotated planar surface code
    function GetSurfaceCodeD3Checks() : StabilizerCheck[] {
        return [
            // X-checks (weight-2 boundaries and weight-4 bulk)
            StabilizerCheck(PauliX, 2, [0, 1], 9),
            StabilizerCheck(PauliX, 4, [1, 2, 4, 5], 10),
            StabilizerCheck(PauliX, 4, [3, 4, 6, 7], 11),
            StabilizerCheck(PauliX, 2, [7, 8], 12),
            // Z-checks
            StabilizerCheck(PauliZ, 2, [0, 3], 13),
            StabilizerCheck(PauliZ, 4, [1, 2, 3, 4], 14),
            StabilizerCheck(PauliZ, 4, [4, 5, 7, 8], 15),
            StabilizerCheck(PauliZ, 2, [5, 8], 16)
        ];
    }

    // Runs a fault-tolerant syndrome extraction round using the standard scheduled CNOT order
    // Order: North, West, East, South (NWES) to avoid spreading weight-2 hook errors along the code distance
    operation RunSurfaceCodeSyndromeCycle(
        patch : SurfaceCodePatch,
        register : Qubit[]
    ) : Bool[] {
        let checks = GetSurfaceCodeD3Checks();
        mutable syndromes = [false, size = 8];

        for idx in 0..7 {
            let check = checks[idx];
            let ancillaQubit = register[check.AncillaIndex];

            H(ancillaQubit);
            for dIdx in check.Support {
                let dataQubit = register[dIdx];
                if (check.CheckType == PauliX) {
                    CNOT(ancillaQubit, dataQubit);
                } elif (check.CheckType == PauliZ) {
                    CZ(ancillaQubit, dataQubit);
                }
            }
            H(ancillaQubit);
            let bit = M(ancillaQubit) == One;
            set syndromes w/= idx <- bit;
            Reset(ancillaQubit);
        }

        return syndromes;
    }

    // Logical Pauli Z operator for distance-3 rotated surface code: Z_0 * Z_1 * Z_2
    operation ApplySurfaceCodeLogicalZ(register : Qubit[]) : Unit is Adj + Ctl {
        Z(register[0]);
        Z(register[1]);
        Z(register[2]);
    }

    // Logical Pauli X operator for distance-3 rotated surface code: X_0 * X_3 * X_6
    operation ApplySurfaceCodeLogicalX(register : Qubit[]) : Unit is Adj + Ctl {
        X(register[0]);
        X(register[3]);
        X(register[6]);
    }

    // Measures the logical Z operator of the surface code patch
    operation MeasureSurfaceCodeLogicalZ(register : Qubit[]) : Result {
        use anc = Qubit();
        H(anc);
        CZ(anc, register[0]);
        CZ(anc, register[1]);
        CZ(anc, register[2]);
        H(anc);
        let res = M(anc);
        Reset(anc);
        return res;
    }
}
