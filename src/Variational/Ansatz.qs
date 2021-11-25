namespace Fermion.Variational {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;
    open Fermion.Core;

    // Hardware-efficient variational ansatz:
    // Applies L layers of parameterized Ry-Rz single-qubit rotations
    // interleaved with nearest-neighbor entangling CNOT gates
    operation ApplyHardwareEfficientAnsatz(
        numLayers : Int,
        parameters : Double[], // length must be 2 * numLayers * numQubits
        register : Qubit[]
    ) : Unit {
        let n = Length(register);
        if (n == 0 or numLayers <= 0) {
            return ();
        }

        mutable paramIdx = 0;
        let totalParams = Length(parameters);

        for _ in 0..numLayers - 1 {
            // 1. Single-qubit rotation layer: Ry(theta) followed by Rz(phi)
            for q in 0..n - 1 {
                if (paramIdx < totalParams) {
                    Ry(parameters[paramIdx], register[q]);
                    set paramIdx += 1;
                }
                if (paramIdx < totalParams) {
                    Rz(parameters[paramIdx], register[q]);
                    set paramIdx += 1;
                }
            }

            // 2. Entangling CNOT chain
            if (n > 1) {
                for q in 0..n - 2 {
                    CNOT(register[q], register[q + 1]);
                }
                // Optional ring closure
                CNOT(register[n - 1], register[0]);
            }
        }
    }

    // Evaluates the total Hamiltonian expectation value <psi(theta)| H |psi(theta)>
    // for a variational state prepared by the ansatz
    operation EvaluateVariationalEnergy(
        hamiltonian : PauliWord[],
        numLayers : Int,
        parameters : Double[],
        register : Qubit[],
        shotsPerTerm : Int
    ) : Double {
        mutable totalEnergy = 0.0;

        for word in hamiltonian {
            // Prepare variational state
            ApplyHardwareEfficientAnsatz(numLayers, parameters, register);

            // Measure Pauli term expectation value
            let expVal = SamplePauliExpectation(word, register, shotsPerTerm);
            set totalEnergy += word.Coeff * expVal;

            ResetAll(register);
        }

        return totalEnergy;
    }
}
