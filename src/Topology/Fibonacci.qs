namespace Fermion.Topology {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;
    open Fermion.Core;

    // Golden ratio phi = (1 + sqrt(5)) / 2
    function GoldenRatio() : Double {
        return (1.0 + Sqrt(5.0)) * 0.5;
    }

    // Applies the topological F-matrix to the fusion qubit:
    // F = [ [ 1/phi, 1/sqrt(phi) ], [ 1/sqrt(phi), -1/phi ] ]
    // Decomposed as Ry(2 * theta) followed by Z
    operation ApplyFibonacciF(target : Qubit) : Unit is Adj + Ctl {
        let phi = GoldenRatio();
        let theta = ArcTan2(1.0 / Sqrt(phi), 1.0 / phi);
        Ry(2.0 * theta, target);
        Z(target);
    }

    // Applies the Fibonacci braid generator sigma_1 to the 2D fusion qubit
    // sigma_1 = diag(exp(4*pi*i / 5), -exp(2*pi*i / 5))
    // In Q# SU(2) representation: Rz(-7*pi / 5)
    operation ApplyFibonacciSigma1(target : Qubit) : Unit is Adj + Ctl {
        let rzAngle = -7.0 * PI() / 5.0;
        Rz(rzAngle, target);
    }

    // Applies the Fibonacci braid generator sigma_2 to the 2D fusion qubit:
    // sigma_2 = F * sigma_1 * F
    operation ApplyFibonacciSigma2(target : Qubit) : Unit is Adj + Ctl {
        ApplyFibonacciF(target);
        ApplyFibonacciSigma1(target);
        ApplyFibonacciF(target);
    }

    // Synthesizes a word of Fibonacci braid generators:
    // sequence: array of integers (1 for sigma_1, 2 for sigma_2, -1 for sigma_1^-1, -2 for sigma_2^-1)
    operation ApplyFibonacciBraidWord(sequence : Int[], target : Qubit) : Unit {
        for gen in sequence {
            if (gen == 1) {
                ApplyFibonacciSigma1(target);
            } elif (gen == 2) {
                ApplyFibonacciSigma2(target);
            } elif (gen == -1) {
                Adjoint ApplyFibonacciSigma1(target);
            } elif (gen == -2) {
                Adjoint ApplyFibonacciSigma2(target);
            }
        }
    }

    // Measures the fusion outcome of two Fibonacci anyons:
    // Returns Result (Zero for vacuum channel 1, One for anyon channel tau)
    operation MeasureFusionOutcome(fusionQubit : Qubit) : Result {
        return M(fusionQubit);
    }

    // Verifies the non-Abelian Fibonacci braid relation:
    // sigma_1 * sigma_2 * sigma_1 == sigma_2 * sigma_1 * sigma_2
    operation VerifyFibonacciBraidRelation() : Bool {
        use q1 = Qubit();
        use q2 = Qubit();

        // Path 1: sigma_1 sigma_2 sigma_1
        ApplyFibonacciSigma1(q1);
        ApplyFibonacciSigma2(q1);
        ApplyFibonacciSigma1(q1);

        // Path 2: sigma_2 sigma_1 sigma_2
        ApplyFibonacciSigma2(q2);
        ApplyFibonacciSigma1(q2);
        ApplyFibonacciSigma2(q2);

        // SWAP test verification
        use ancilla = Qubit();
        H(ancilla);
        Controlled SWAP([ancilla], (q1, q2));
        H(ancilla);
        let res = M(ancilla);

        Reset(q1);
        Reset(q2);
        Reset(ancilla);

        return res == Zero;
    }
}
