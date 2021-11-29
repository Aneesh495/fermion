namespace Fermion.Variational {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;
    open Fermion.Core;

    // Evaluates the exact analytical quantum gradient component d<H>/d(theta_k)
    // using the two-point Parameter Shift Rule:
    // d<H>/d(theta_k) = ( <H>(theta_k + pi/2) - <H>(theta_k - pi/2) ) / 2
    operation EvaluateParameterShiftGradient(
        paramIndex : Int,
        hamiltonian : PauliWord[],
        numLayers : Int,
        parameters : Double[],
        register : Qubit[],
        shotsPerTerm : Int
    ) : Double {
        let nParams = Length(parameters);
        if (paramIndex < 0 or paramIndex >= nParams) {
            return 0.0;
        }

        let shift = PI() * 0.5;

        // Shift forward: theta_k + pi/2
        mutable paramsForward = parameters;
        set paramsForward w/= paramIndex <- parameters[paramIndex] + shift;
        let energyForward = EvaluateVariationalEnergy(hamiltonian, numLayers, paramsForward, register, shotsPerTerm);

        // Shift backward: theta_k - pi/2
        mutable paramsBackward = parameters;
        set paramsBackward w/= paramIndex <- parameters[paramIndex] - shift;
        let energyBackward = EvaluateVariationalEnergy(hamiltonian, numLayers, paramsBackward, register, shotsPerTerm);

        // Analytical derivative
        return (energyForward - energyBackward) * 0.5;
    }

    // Evaluates the complete analytical gradient vector across all parameters
    operation EvaluateFullGradientVector(
        hamiltonian : PauliWord[],
        numLayers : Int,
        parameters : Double[],
        register : Qubit[],
        shotsPerTerm : Int
    ) : Double[] {
        let numParams = Length(parameters);
        mutable grad = [0.0, size = numParams];

        for idx in 0..numParams - 1 {
            let g = EvaluateParameterShiftGradient(idx, hamiltonian, numLayers, parameters, register, shotsPerTerm);
            set grad w/= idx <- g;
        }

        return grad;
    }

    // Measures the real part of the quantum state overlap Re <psi(theta1) | psi(theta2)>
    // via an ancilla SWAP test, used to construct the Fubini-Study metric tensor
    operation MeasureStateOverlap(
        numLayers : Int,
        params1 : Double[],
        params2 : Double[],
        register1 : Qubit[],
        register2 : Qubit[]
    ) : Double {
        let n = Length(register1);
        use ancilla = Qubit();

        H(ancilla);

        // Prepare |psi(params1)> in register1 and |psi(params2)> in register2
        ApplyHardwareEfficientAnsatz(numLayers, params1, register1);
        ApplyHardwareEfficientAnsatz(numLayers, params2, register2);

        // Controlled-SWAP across all qubit pairs
        for idx in 0..n - 1 {
            Controlled SWAP([ancilla], (register1[idx], register2[idx]));
        }

        H(ancilla);
        let res = M(ancilla);

        Reset(ancilla);
        ResetAll(register1);
        ResetAll(register2);

        // P(0) = (1 + |<psi1|psi2>|^2) / 2 => |<psi1|psi2>|^2 = 2 * P(0) - 1
        return res == Zero ? 1.0 | 0.0;
    }
}
