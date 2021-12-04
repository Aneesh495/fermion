namespace Fermion.Characterization {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;
    open Fermion.Core;

    // Single-qubit state tomography record (Stokes vector)
    // S0 = 1, S1 = <X>, S2 = <Y>, S3 = <Z>
    struct StokesParameters {
        S1 : Double,
        S2 : Double,
        S3 : Double,
        Purity : Double
    }

    // 2-qubit state tomography correlation record: 15 non-trivial Pauli expectation values
    struct TwoQubitTomographyRecord {
        Expectations : Double[],
        Purity : Double
    }

    // Measures the Stokes parameters (S1=<X>, S2=<Y>, S3=<Z>) of a single-qubit state
    // prepared by the given state preparation operation
    operation PerformSingleQubitTomography(
        prepareState : (Qubit) => Unit,
        shots : Int
    ) : StokesParameters {
        use q = Qubit();

        // 1. Measure <X>
        prepareState(q);
        H(q);
        let mx = M(q);
        Reset(q);
        let s1 = (mx == Zero ? 1.0 | -1.0);

        // 2. Measure <Y>
        prepareState(q);
        Adjoint S(q);
        H(q);
        let my = M(q);
        Reset(q);
        let s2 = (my == Zero ? 1.0 | -1.0);

        // 3. Measure <Z>
        prepareState(q);
        let mz = M(q);
        Reset(q);
        let s3 = (mz == Zero ? 1.0 | -1.0);

        // Purity gamma = (1 + S1^2 + S2^2 + S3^2) / 2
        let purity = (1.0 + s1 * s1 + s2 * s2 + s3 * s3) * 0.5;

        return StokesParameters(s1, s2, s3, purity);
    }

    // Measures all 15 non-trivial Pauli expectation values for a 2-qubit state:
    // IX, IY, IZ, XI, XX, XY, XZ, YI, YX, YY, YZ, ZI, ZX, ZY, ZZ
    operation PerformTwoQubitTomography(
        prepareState : (Qubit[]) => Unit,
        shots : Int
    ) : TwoQubitTomographyRecord {
        let pauliList = [PauliX, PauliY, PauliZ];
        mutable exps = [];
        mutable sumSq = 0.0;

        use q = Qubit[2];

        // 3 single-qubit terms on qubit 0 (P x I)
        for p in pauliList {
            prepareState(q);
            let word = CreatePauliWord(1.0, [p], [0]);
            let val = SamplePauliExpectation(word, q, shots);
            set exps += [val];
            set sumSq += val * val;
            ResetAll(q);
        }

        // 3 single-qubit terms on qubit 1 (I x P)
        for p in pauliList {
            prepareState(q);
            let word = CreatePauliWord(1.0, [p], [1]);
            let val = SamplePauliExpectation(word, q, shots);
            set exps += [val];
            set sumSq += val * val;
            ResetAll(q);
        }

        // 9 two-qubit correlation terms (P1 x P2)
        for p1 in pauliList {
            for p2 in pauliList {
                prepareState(q);
                let word = CreatePauliWord(1.0, [p1, p2], [0, 1]);
                let val = SamplePauliExpectation(word, q, shots);
                set exps += [val];
                set sumSq += val * val;
                ResetAll(q);
            }
        }

        // 2-qubit purity: Tr(rho^2) = (1 + sum_k <P_k>^2) / 4
        let purity = (1.0 + sumSq) * 0.25;

        return TwoQubitTomographyRecord(exps, purity);
    }
}
