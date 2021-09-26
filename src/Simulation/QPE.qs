namespace Fermion.Simulation {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;
    open Fermion.Core;

    // Inverse Quantum Fourier Transform on register
    operation ApplyInverseQFT(register : Qubit[]) : Unit is Adj + Ctl {
        let n = Length(register);
        for i in n - 1..-1..0 {
            for j in n - 1..-1..i + 1 {
                let k = j - i + 1;
                let angle = -2.0 * PI() / IntAsDouble(1 <<< (k - 1));
                Controlled R1([register[j]], (angle, register[i]));
            }
            H(register[i]);
        }

        // Bit-reversal SWAP network
        for i in 0..(n / 2) - 1 {
            SWAP(register[i], register[n - 1 - i]);
        }
    }

    // Canonical Quantum Phase Estimation:
    // Estimates phase phi of unitary U|psi> = exp(2*pi*i*phi) |psi>
    // using m ancilla counting qubits
    operation RunCanonicalQPE(
        countingQubits : Qubit[],
        targetQubits : Qubit[],
        applyControlledPowerU : (Int, Qubit, Qubit[]) => Unit
    ) : Double {
        let m = Length(countingQubits);
        if (m == 0) {
            return 0.0;
        }

        // 1. Initialize counting register in uniform superposition
        for q in countingQubits {
            H(q);
        }

        // 2. Apply controlled-U^(2^k) operations
        for k in 0..m - 1 {
            let power = 1 <<< k;
            applyControlledPowerU(power, countingQubits[k], targetQubits);
        }

        // 3. Inverse QFT on counting register
        ApplyInverseQFT(countingQubits);

        // 4. Measure counting register to extract binary fraction
        mutable phaseInt = 0;
        for k in 0..m - 1 {
            let res = M(countingQubits[k]);
            if (res == One) {
                set phaseInt += (1 <<< (m - 1 - k));
            }
        }

        ResetAll(countingQubits);
        return IntAsDouble(phaseInt) / IntAsDouble(1 <<< m);
    }

    // Iterative Phase Estimation (Kitaev algorithm):
    // Uses a SINGLE ancilla qubit to extract m bits of phase with adaptive feedback
    operation RunIterativeQPE(
        bits : Int,
        targetQubits : Qubit[],
        applyControlledPowerU : (Int, Qubit, Qubit[]) => Unit
    ) : Double {
        use ancilla = Qubit();
        mutable measuredBits = [0, size = bits];

        // Process from least significant bit (bits - 1) to most significant bit (0)
        for k in bits - 1..-1..0 {
            H(ancilla);
            let power = 1 <<< k;
            applyControlledPowerU(power, ancilla, targetQubits);

            // Compute adaptive feedback angle from previously measured bits
            mutable feedbackAngle = 0.0;
            for j in k + 1..bits - 1 {
                let bitVal = measuredBits[j];
                let shift = j - k;
                set feedbackAngle += IntAsDouble(bitVal) * 2.0 * PI() / IntAsDouble(1 <<< (shift + 1));
            }

            // Apply feedback rotation
            if (AbsD(feedbackAngle) > 1.0e-12) {
                R1(-feedbackAngle, ancilla);
            }

            H(ancilla);
            let outcome = M(ancilla);
            set measuredBits w/= k <- (outcome == One ? 1 | 0);
            Reset(ancilla);
        }

        // Convert binary fraction to floating point phase
        mutable totalPhase = 0.0;
        for k in 0..bits - 1 {
            if (measuredBits[k] == 1) {
                set totalPhase += 1.0 / IntAsDouble(1 <<< (k + 1));
            }
        }

        return totalPhase;
    }

    // Converts QPE phase estimate phi to energy eigenvalue:
    // U = exp(-i * H * t) => -E * t = 2 * pi * phi => E = -2 * pi * phi / t
    function PhaseToHamiltonianEnergy(phase : Double, evolutionTime : Double) : Double {
        if (AbsD(evolutionTime) < 1.0e-14) {
            return 0.0;
        }
        mutable adjustedPhase = phase;
        if (adjustedPhase > 0.5) {
            set adjustedPhase -= 1.0;
        }
        return -2.0 * PI() * adjustedPhase / evolutionTime;
    }
}
