namespace Fermion.Characterization {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;
    open Fermion.Core;

    // Evaluates a single correlation setting <A_a * B_b> for the Bell-CHSH inequality test
    // On the maximally entangled Bell pair |Phi+> = (|00> + |11>) / sqrt(2):
    // Alice's bases: a=0 -> Z (no rotation), a=1 -> X (Hadamard H)
    // Bob's bases:   b=0 -> (Z + X) / sqrt(2) (Ry(-pi/4)), b=1 -> (Z - X) / sqrt(2) (Ry(pi/4))
    operation MeasureCHSHCorrelation(
        aliceSetting : Int,
        bobSetting : Int,
        shots : Int
    ) : Double {
        mutable totalProduct = 0.0;
        let bobAngle = (bobSetting == 0) ? -PI() * 0.25 | PI() * 0.25;

        for _ in 1..shots {
            use qA = Qubit();
            use qB = Qubit();

            // Prepare maximally entangled Bell pair
            PrepareBellPhiPlus(qA, qB);

            // Alice's measurement basis rotation
            if (aliceSetting == 1) {
                H(qA); // Measure X
            }

            // Bob's measurement basis rotation
            Ry(bobAngle, qB);

            let mA = (M(qA) == Zero ? 1.0 | -1.0);
            let mB = (M(qB) == Zero ? 1.0 | -1.0);

            set totalProduct += mA * mB;

            Reset(qA);
            Reset(qB);
        }

        return totalProduct / IntAsDouble(shots);
    }

    // Runs the complete Bell-CHSH inequality test:
    // S = <A0 B0> + <A0 B1> + <A1 B0> - <A1 B1>
    // Classical bound: |S| <= 2
    // Quantum Cirel'son bound: S = 2 * sqrt(2) ~ 2.828427
    operation RunCHSHInequalityTest(shotsPerSetting : Int) : (Double, Double, Double, Double, Double) {
        let e00 = MeasureCHSHCorrelation(0, 0, shotsPerSetting);
        let e01 = MeasureCHSHCorrelation(0, 1, shotsPerSetting);
        let e10 = MeasureCHSHCorrelation(1, 0, shotsPerSetting);
        let e11 = MeasureCHSHCorrelation(1, 1, shotsPerSetting);

        let sVal = e00 + e01 + e10 - e11;
        return (sVal, e00, e01, e10, e11);
    }

    // Evaluates the 3-qubit GHZ state entanglement witness:
    // W = I/2 - |GHZ><GHZ|
    // A negative expectation value <W> < 0 rigorously certifies genuine multipartite entanglement
    operation EvaluateGHZWitness(shots : Int) : Double {
        use q = Qubit[3];

        // Prepare GHZ state
        PrepareGHZ(q);

        // Measure projector |GHZ><GHZ| via inversion and zero-state projection
        Adjoint PrepareGHZ(q);

        let m0 = M(q[0]);
        let m1 = M(q[1]);
        let m2 = M(q[2]);

        let isAllZero = (m0 == Zero and m1 == Zero and m2 == Zero);
        let projectorVal = isAllZero ? 1.0 | 0.0;

        ResetAll(q);

        // <W> = 0.5 - <|GHZ><GHZ|>
        return 0.5 - projectorVal;
    }
}
