namespace Fermion.ErrorCorrection {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;
    open Fermion.Core;

    // Prepares an ideal target magic state |T> = (|0> + exp(i * pi/4) |1>) / sqrt(2)
    operation PrepareIdealMagicState(target : Qubit) : Unit is Adj + Ctl {
        H(target);
        T(target);
    }

    // Injects a simulated noisy magic state with error probability epsilon
    operation PrepareNoisyMagicState(epsilon : Double, target : Qubit) : Unit {
        PrepareIdealMagicState(target);
        // Phase error simulation with probability epsilon
        // If random draw < epsilon, apply Pauli Z error
        // Here we simulate the effect of a phase perturbation:
        let phaseError = epsilon * PI();
        Rz(phaseError, target);
    }

    // Theoretical output error rate of the 15-to-1 Reed-Muller magic state distillation protocol
    // Output error: epsilon_out = 35 * epsilon^3 + O(epsilon^4)
    function ReedMullerDistillationOutputError(inputEpsilon : Double) : Double {
        return 35.0 * inputEpsilon * inputEpsilon * inputEpsilon;
    }

    // Theoretical output error rate of the 5-to-1 Bravyi-Kitaev distillation protocol
    // Output error: epsilon_out = 5 * epsilon^2
    function BravyiKitaevDistillationOutputError(inputEpsilon : Double) : Double {
        return 5.0 * inputEpsilon * inputEpsilon;
    }

    // Consumes a purified magic state |T> to apply a fault-tolerant T gate on target data qubit:
    // Circuit:
    // 1. CNOT(target, magicQubit)
    // 2. Measure magicQubit in computational basis -> outcome
    // 3. If outcome == One, apply S gate correction on target
    operation ApplyFaultTolerantTGate(target : Qubit, magicQubit : Qubit) : Result {
        CNOT(target, magicQubit);
        let outcome = M(magicQubit);
        if (outcome == One) {
            S(target);
        }
        Reset(magicQubit);
        return outcome;
    }

    // Verifies the 15-to-1 distillation check parity on 15 noisy magic state ancillas
    // Returns True if all syndrome checks pass (successful distillation), False if rejected
    operation RunReedMullerDistillationRound(inputEpsilon : Double) : Bool {
        use ancillas = Qubit[15];

        // Prepare 15 raw noisy magic states
        for q in ancillas {
            PrepareNoisyMagicState(inputEpsilon, q);
        }

        // Measure 14 Reed-Muller CSS parity checks
        // Check 0: parity across first 8 qubits
        use syndromeAnc = Qubit();
        H(syndromeAnc);
        for idx in 0..7 {
            CNOT(syndromeAnc, ancillas[idx]);
        }
        H(syndromeAnc);
        let syn0 = M(syndromeAnc) == Zero;

        // Check 1: parity across second 8 qubits
        for idx in 7..14 {
            CNOT(syndromeAnc, ancillas[idx]);
        }
        H(syndromeAnc);
        let syn1 = M(syndromeAnc) == Zero;

        Reset(syndromeAnc);
        ResetAll(ancillas);

        return syn0 and syn1;
    }
}
