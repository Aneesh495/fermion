namespace Fermion {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;
    open Fermion.Core;
    open Fermion.Simulation;
    open Fermion.Topology;
    open Fermion.ErrorCorrection;
    open Fermion.Variational;
    open Fermion.Characterization;

    // Master diagnostics operation running smoke tests across all subsystems
    // Returns 0 on complete success, negative code on failure
    operation RunMasterDiagnostics() : Int {
        // 1. Core: Symplectic inner product
        let v1 = CreateSymplecticVector(2);
        let v2 = CreateSymplecticVector(2);
        let inner = SymplecticInnerProduct(v1, v2);
        if (inner != 0) {
            return -1;
        }

        // 2. Topology: Artin braid relation
        let braidOk = VerifyArtinBraidRelation();
        if (not braidOk) {
            return -2;
        }

        // 3. Topology: Fibonacci braid relation
        let fibOk = VerifyFibonacciBraidRelation();
        if (not fibOk) {
            return -3;
        }

        // 4. Error Correction: Steane check commutation
        let steaneChecks = GetSteaneStabilizerChecks();
        if (Length(steaneChecks) != 6) {
            return -4;
        }

        // 5. Error Correction: Surface code d=3 patch
        let surf = GetRotatedSurfaceCodeDistance3();
        if (surf.Distance != 3) {
            return -5;
        }

        return 0;
    }

    // High-level end-to-end multi-stage pipeline coordinator
    operation RunFullPipeline() : (Double, Double, Bool, (Int, Int)) {
        // 1. Molecular Ground State QPE on H2
        let h2Energy = RunH2PhaseEstimation(6);

        // 2. Bell-CHSH Violation
        let (sVal, _, _, _, _) = RunCHSHInequalityTest(100);

        // 3. Non-Abelian Braiding Artin relation
        let artinValid = VerifyArtinBraidRelation();

        // 4. Active Steane Error Correction
        use q = Qubit[7];
        EncodeSteaneCode(q);
        X(q[1]); // Inject bit-flip error on qubit 1
        let (xErr, zErr) = CorrectSteaneCodeErrors(q);
        ResetAll(q);

        return (h2Energy, sVal, artinValid, (xErr, zErr));
    }
}
