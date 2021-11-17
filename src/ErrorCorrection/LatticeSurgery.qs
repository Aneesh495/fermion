namespace Fermion.ErrorCorrection {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;
    open Fermion.Core;

    // Boundary interface descriptor between two adjacent surface code patches
    struct LatticeSurgeryInterface {
        PatchAIndices : Int[],
        PatchBIndices : Int[],
        BoundaryCheckType : Pauli
    }

    // Executes a non-destructive fault-tolerant joint Z-parity measurement (Z_L^(1) * Z_L^(2))
    // between two surface code patches via boundary lattice surgery merge
    operation PerformLatticeSurgeryZMerge(
        patchA : Qubit[],
        patchB : Qubit[],
        boundaryQubitsA : Int[],
        boundaryQubitsB : Int[]
    ) : Result {
        let numBoundary = Length(boundaryQubitsA);
        use ancilla = Qubit();
        H(ancilla);

        // Turn on joint boundary stabilizers connecting Patch A and Patch B
        for idx in 0..numBoundary - 1 {
            let qA = patchA[boundaryQubitsA[idx]];
            let qB = patchB[boundaryQubitsB[idx]];
            CZ(ancilla, qA);
            CZ(ancilla, qB);
        }

        H(ancilla);
        let jointParityOutcome = M(ancilla);
        Reset(ancilla);

        return jointParityOutcome;
    }

    // Executes a non-destructive fault-tolerant joint X-parity measurement (X_L^(1) * X_L^(2))
    // between two surface code patches via boundary lattice surgery merge
    operation PerformLatticeSurgeryXMerge(
        patchA : Qubit[],
        patchB : Qubit[],
        boundaryQubitsA : Int[],
        boundaryQubitsB : Int[]
    ) : Result {
        let numBoundary = Length(boundaryQubitsA);
        use ancilla = Qubit();
        H(ancilla);

        for idx in 0..numBoundary - 1 {
            let qA = patchA[boundaryQubitsA[idx]];
            let qB = patchB[boundaryQubitsB[idx]];
            CNOT(ancilla, qA);
            CNOT(ancilla, qB);
        }

        H(ancilla);
        let jointParityOutcome = M(ancilla);
        Reset(ancilla);

        return jointParityOutcome;
    }

    // Executes a patch split operation:
    // Measures boundary interface qubits in the computational basis to disentangle
    // the merged patch back into two distinct logical surface code patches
    operation PerformLatticeSurgerySplit(
        boundaryQubits : Qubit[]
    ) : Result[] {
        mutable outcomes = [];
        for q in boundaryQubits {
            set outcomes += [M(q)];
            Reset(q);
        }
        return outcomes;
    }

    // Implements a logical CNOT gate between two surface code patches using lattice surgery:
    // Requires an intermediate ancilla patch initialized in |+>_L:
    // 1. Joint Z-parity measurement between Control patch and Ancilla patch: M_ZZ = PerformLatticeSurgeryZMerge
    // 2. Joint X-parity measurement between Ancilla patch and Target patch:  M_XX = PerformLatticeSurgeryXMerge
    // 3. Conditional Pauli byproduct corrections based on M_ZZ and M_XX
    operation ExecuteLatticeSurgeryCNOT(
        controlPatch : Qubit[],
        targetPatch : Qubit[],
        ancillaPatch : Qubit[]
    ) : Unit {
        // Measure joint Z_C * Z_A
        let mZZ = PerformLatticeSurgeryZMerge(controlPatch, ancillaPatch, [0, 1], [0, 1]);

        // Measure joint X_A * X_T
        let mXX = PerformLatticeSurgeryXMerge(ancillaPatch, targetPatch, [1, 2], [1, 2]);

        // Apply Pauli byproduct corrections to restore canonical CNOT state:
        // If mZZ == One, apply logical X on target patch
        if (mZZ == One) {
            ApplySurfaceCodeLogicalX(targetPatch);
        }

        // If mXX == One, apply logical Z on control patch
        if (mXX == One) {
            ApplySurfaceCodeLogicalZ(controlPatch);
        }
    }
}
