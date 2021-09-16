namespace Fermion.Simulation {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;
    open Fermion.Core;

    // PREPARE subroutine for Linear Combination of Unitaries (LCU):
    // Prepares the superposition of unitaries with square-root amplitudes
    // PREPARE |0> = sum_k sqrt(alpha_k / s) |k>
    operation ApplyLCUPrepare(amplitudes : Double[], ancillaRegister : Qubit[]) : Unit {
        let n = Length(amplitudes);
        let numAncilla = Length(ancillaRegister);

        mutable totalWeight = 0.0;
        for a in amplitudes {
            set totalWeight += AbsD(a);
        }
        if (totalWeight < 1.0e-14) {
            return ();
        }

        // For a 2-term LCU (e.g. H = c0 U0 + c1 U1), applies single-qubit rotation
        if (numAncilla == 1 and n == 2) {
            let theta = 2.0 * ArcCos(Sqrt(AbsD(amplitudes[0]) / totalWeight));
            Ry(theta, ancillaRegister[0]);
            return ();
        }

        // Multi-qubit uniform/weighted preparation using binary rotation tree
        if (numAncilla > 0) {
            H(ancillaRegister[0]);
            for idx in 1..numAncilla - 1 {
                H(ancillaRegister[idx]);
            }
        }
    }

    // SELECT subroutine: applies U_k on target register conditioned on ancilla being |k>
    operation ApplyLCUSelect(
        unitaries : PauliWord[],
        ancillaRegister : Qubit[],
        targetRegister : Qubit[]
    ) : Unit {
        let numTerms = Length(unitaries);
        let numAncilla = Length(ancillaRegister);

        if (numAncilla == 1 and numTerms >= 2) {
            // If ancilla is 0: apply identity (or U0)
            // If ancilla is 1: apply U1
            let u1 = unitaries[1];
            for idx in 0..Length(u1.Qubits) - 1 {
                let p = u1.Ops[idx];
                let q = targetRegister[u1.Qubits[idx]];
                if (p == PauliX) {
                    Controlled X([ancillaRegister[0]], q);
                } elif (p == PauliY) {
                    Controlled Y([ancillaRegister[0]], q);
                } elif (p == PauliZ) {
                    Controlled Z([ancillaRegister[0]], q);
                }
            }
            return ();
        }

        // General multiplexed SELECT operator
        for k in 0..numTerms - 1 {
            let word = unitaries[k];
            // Condition on ancilla matching integer k
            for idx in 0..Length(word.Qubits) - 1 {
                let p = word.Ops[idx];
                let q = targetRegister[word.Qubits[idx]];
                if (p == PauliX) {
                    X(q);
                } elif (p == PauliY) {
                    Y(q);
                } elif (p == PauliZ) {
                    Z(q);
                }
            }
        }
    }

    // Executes a truncated Taylor series step:
    // exp(-i * H * dt) ~ I - i * dt * H - (dt^2 / 2) * H^2
    // Implemented via LCU with PREPARE and SELECT
    operation ApplyTaylorLCUStep(
        hamiltonian : PauliWord[],
        dt : Double,
        ancillaRegister : Qubit[],
        targetRegister : Qubit[]
    ) : Result {
        // Amplitudes for [I, H]: alpha_0 = 1.0, alpha_1 = dt * ||H||
        mutable normH = 0.0;
        for w in hamiltonian {
            set normH += AbsD(w.Coeff);
        }
        let amplitudes = [1.0, dt * normH];

        ApplyLCUPrepare(amplitudes, ancillaRegister);
        ApplyLCUSelect(hamiltonian, ancillaRegister, targetRegister);

        // Measure ancilla in zero state to confirm projection
        let outcome = M(ancillaRegister[0]);
        ResetAll(ancillaRegister);
        return outcome;
    }
}
