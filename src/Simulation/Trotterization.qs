namespace Fermion.Simulation {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;
    open Fermion.Core;

    // Suzuki fractal coefficient p = 1 / (4 - 4^(1/3))
    function SuzukiParameterP() : Double {
        return 0.4144907717943757;
    }

    // Helper for integer powers of Double
    function PowerDouble(baseVal : Double, exponent : Int) : Double {
        mutable res = 1.0;
        for _ in 1..exponent {
            set res *= baseVal;
        }
        return res;
    }

    // Applies a single 1st-order Lie-Trotter step: S_1(t) = prod_k exp(-i * H_k * t)
    operation ApplyLieTrotterStep(
        hamiltonian : PauliWord[],
        dt : Double,
        register : Qubit[]
    ) : Unit {
        for word in hamiltonian {
            let angle = 2.0 * word.Coeff * dt;
            ExpPauliWord(angle, word, register);
        }
    }

    // Applies a single 2nd-order symmetric Strang-Marchuk Trotter step:
    // S_2(t) = (prod_{k=1}^M exp(-i * H_k * t / 2)) * (prod_{k=M}^1 exp(-i * H_k * t / 2))
    operation ApplyStrangMarchukStep(
        hamiltonian : PauliWord[],
        dt : Double,
        register : Qubit[]
    ) : Unit {
        let numTerms = Length(hamiltonian);
        let halfDt = 0.5 * dt;

        // Forward sweep
        for idx in 0..numTerms - 1 {
            let word = hamiltonian[idx];
            let angle = 2.0 * word.Coeff * halfDt;
            ExpPauliWord(angle, word, register);
        }

        // Backward sweep
        for idx in numTerms - 1..-1..0 {
            let word = hamiltonian[idx];
            let angle = 2.0 * word.Coeff * halfDt;
            ExpPauliWord(angle, word, register);
        }
    }

    // Applies a single 4th-order Suzuki fractal product formula step:
    // S_4(t) = [S_2(p * t)]^2 * S_2((1 - 4p) * t) * [S_2(p * t)]^2
    operation ApplySuzukiFourthOrderStep(
        hamiltonian : PauliWord[],
        dt : Double,
        register : Qubit[]
    ) : Unit {
        let p = SuzukiParameterP();
        let t1 = p * dt;
        let tMiddle = (1.0 - 4.0 * p) * dt;

        ApplyStrangMarchukStep(hamiltonian, t1, register);
        ApplyStrangMarchukStep(hamiltonian, t1, register);
        ApplyStrangMarchukStep(hamiltonian, tMiddle, register);
        ApplyStrangMarchukStep(hamiltonian, t1, register);
        ApplyStrangMarchukStep(hamiltonian, t1, register);
    }

    // Simulates dynamic Hamiltonian time evolution over total time T using r Trotter steps
    // order: 1 for Lie-Trotter, 2 for Strang-Marchuk, 4 for Suzuki 4th-order
    operation SimulateHamiltonianEvolution(
        hamiltonian : PauliWord[],
        totalTime : Double,
        steps : Int,
        order : Int,
        register : Qubit[]
    ) : Unit {
        if (steps <= 0) {
            return ();
        }
        let dt = totalTime / IntAsDouble(steps);

        for _ in 1..steps {
            if (order == 1) {
                ApplyLieTrotterStep(hamiltonian, dt, register);
            } elif (order == 2) {
                ApplyStrangMarchukStep(hamiltonian, dt, register);
            } elif (order == 4) {
                ApplySuzukiFourthOrderStep(hamiltonian, dt, register);
            } else {
                ApplyStrangMarchukStep(hamiltonian, dt, register);
            }
        }
    }

    // Theoretical Trotter error bound estimate:
    // Returns estimated norm bound || e^(-i H t) - S_k(t/r)^r ||
    function EstimateTrotterErrorBound(
        hamiltonian : PauliWord[],
        totalTime : Double,
        steps : Int,
        order : Int
    ) : Double {
        if (steps <= 0) {
            return 1.0;
        }

        // 1-norm sum of Hamiltonian coefficients
        mutable oneNorm = 0.0;
        for word in hamiltonian {
            set oneNorm += AbsD(word.Coeff);
        }

        let dt = totalTime / IntAsDouble(steps);
        let rDouble = IntAsDouble(steps);

        if (order == 1) {
            // First order error bound ~ (t^2 / 2r) * ||H||^2
            return 0.5 * totalTime * totalTime * oneNorm * oneNorm / rDouble;
        } elif (order == 2) {
            // Second order error bound ~ (t^3 / 12 r^2) * ||H||^3
            return (totalTime * totalTime * totalTime * oneNorm * oneNorm * oneNorm) / (12.0 * rDouble * rDouble);
        } elif (order == 4) {
            // Fourth order error bound ~ c_4 * (t^5 / r^4) * ||H||^5
            return 0.01 * PowerDouble(totalTime * oneNorm, 5) / PowerDouble(rDouble, 4);
        }
        return 0.1 * totalTime * oneNorm / rDouble;
    }
}
