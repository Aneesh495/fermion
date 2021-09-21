namespace Fermion.Simulation {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;
    open Fermion.Core;

    // Ancilla reflection operator R = 2|0><0| - I
    // Inverts phase of all states orthogonal to |0...0>
    operation ApplyAncillaReflection(ancillaRegister : Qubit[]) : Unit {
        let n = Length(ancillaRegister);
        if (n == 0) {
            return ();
        }
        if (n == 1) {
            Z(ancillaRegister[0]);
            return ();
        }

        // Multi-controlled Z gate using X framing
        for q in ancillaRegister {
            X(q);
        }
        Controlled Z(ancillaRegister[0..n - 2], ancillaRegister[n - 1]);
        for q in ancillaRegister {
            X(q);
        }
    }

    // Applies a single step of the Qubitized Quantum Walk operator:
    // W = R_ancilla * (PREPARE^dagger * SELECT * PREPARE)
    // Eigenvalues of W are exp(+/- i * arccos(E_k / lambda))
    operation ApplyQubitizedWalkStep(
        hamiltonian : PauliWord[],
        lambda : Double,
        ancillaRegister : Qubit[],
        systemRegister : Qubit[]
    ) : Unit {
        // 1. Prepare linear combination weights on ancilla
        mutable weights = [];
        for w in hamiltonian {
            set weights += [w.Coeff / lambda];
        }
        ApplyLCUPrepare(weights, ancillaRegister);

        // 2. Select conditional unitary
        ApplyLCUSelect(hamiltonian, ancillaRegister, systemRegister);

        // 3. Unprepare ancilla (Adjoint PREPARE)
        // For symmetric/Hadamard trees, PREPARE is self-adjoint
        ApplyLCUPrepare(weights, ancillaRegister);

        // 4. Ancilla reflection R_ancilla
        ApplyAncillaReflection(ancillaRegister);
    }

    // Computes the Hamiltonian 1-norm lambda = sum_k |c_k|
    function ComputeHamiltonianOneNorm(hamiltonian : PauliWord[]) : Double {
        mutable norm = 0.0;
        for w in hamiltonian {
            set norm += AbsD(w.Coeff);
        }
        return norm;
    }

    // Converts quantum walk eigenphase phi into energy eigenvalue E = lambda * cos(phi)
    function WalkPhaseToEnergy(phase : Double, lambda : Double) : Double {
        return lambda * Cos(phase);
    }
}
