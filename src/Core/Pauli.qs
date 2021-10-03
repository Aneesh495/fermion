namespace Fermion.Core {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;

    // Changes basis from computational (Z) to the eigenbasis of the given Pauli
    operation RotateFromZBasis(p : Pauli, target : Qubit) : Unit is Adj + Ctl {
        if (p == PauliX) {
            H(target);
        } elif (p == PauliY) {
            H(target);
            S(target);
        }
    }

    // Applies single Pauli operator to target qubit
    operation ApplyPauli(p : Pauli, target : Qubit) : Unit is Adj + Ctl {
        if (p == PauliX) {
            X(target);
        } elif (p == PauliY) {
            Y(target);
        } elif (p == PauliZ) {
            Z(target);
        }
    }

    // Applies a multi-qubit Pauli word: P = prod_k P_k^(q_k)
    operation ApplyPauliWord(word : PauliWord, register : Qubit[]) : Unit {
        for idx in 0..Length(word.Qubits) - 1 {
            let q = word.Qubits[idx];
            let p = word.Ops[idx];
            ApplyPauli(p, register[q]);
        }
    }

    // Synthesizes the unitary evolution exp(-i * theta * P / 2) for an arbitrary Pauli string P
    // Using standard CNOT parity trees and single-qubit basis changes
    operation ExpPauliWord(theta : Double, word : PauliWord, register : Qubit[]) : Unit {
        let numOps = Length(word.Ops);
        if (numOps == 0) {
            return ();
        }

        // Filter out identity operators
        mutable activeQubits = [];
        mutable activeOps = [];
        for idx in 0..numOps - 1 {
            if (word.Ops[idx] != PauliI) {
                set activeQubits += [word.Qubits[idx]];
                set activeOps += [word.Ops[idx]];
            }
        }

        let numActive = Length(activeQubits);
        if (numActive == 0) {
            return ();
        }

        if (numActive == 1) {
            let q = register[activeQubits[0]];
            let p = activeOps[0];
            if (p == PauliX) {
                Rx(theta, q);
            } elif (p == PauliY) {
                Ry(theta, q);
            } elif (p == PauliZ) {
                Rz(theta, q);
            }
            return ();
        }

        // Multi-qubit Pauli exponential evolution:
        // 1. Basis change to Z eigenbasis
        for idx in 0..numActive - 1 {
            RotateFromZBasis(activeOps[idx], register[activeQubits[idx]]);
        }

        // 2. Parity network using CNOT ladder
        for idx in 0..numActive - 2 {
            CNOT(register[activeQubits[idx]], register[activeQubits[idx + 1]]);
        }

        // 3. Central phase rotation on the accumulator qubit
        let accumulator = register[activeQubits[numActive - 1]];
        Rz(theta, accumulator);

        // 4. Invert parity network
        for idx in numActive - 2..-1..0 {
            CNOT(register[activeQubits[idx]], register[activeQubits[idx + 1]]);
        }

        // 5. Invert basis changes
        for idx in 0..numActive - 1 {
            Adjoint RotateFromZBasis(activeOps[idx], register[activeQubits[idx]]);
        }
    }

    // Controlled multi-qubit Pauli exponential evolution:
    // Controls the central Rz rotation using the control qubit
    operation ControlledExpPauliWord(
        control : Qubit,
        theta : Double,
        word : PauliWord,
        register : Qubit[]
    ) : Unit {
        let numOps = Length(word.Ops);
        if (numOps == 0) {
            return ();
        }

        mutable activeQubits = [];
        mutable activeOps = [];
        for idx in 0..numOps - 1 {
            if (word.Ops[idx] != PauliI) {
                set activeQubits += [word.Qubits[idx]];
                set activeOps += [word.Ops[idx]];
            }
        }

        let numActive = Length(activeQubits);
        if (numActive == 0) {
            // Identity operator with phase theta/2: applies R1(-theta, control)
            R1(-theta * 0.5, control);
            return ();
        }

        if (numActive == 1) {
            let q = register[activeQubits[0]];
            let p = activeOps[0];
            RotateFromZBasis(p, q);
            Controlled Rz([control], (theta, q));
            Adjoint RotateFromZBasis(p, q);
            return ();
        }

        // Multi-qubit controlled evolution
        for idx in 0..numActive - 1 {
            RotateFromZBasis(activeOps[idx], register[activeQubits[idx]]);
        }

        for idx in 0..numActive - 2 {
            CNOT(register[activeQubits[idx]], register[activeQubits[idx + 1]]);
        }

        let accumulator = register[activeQubits[numActive - 1]];
        Controlled Rz([control], (theta, accumulator));

        for idx in numActive - 2..-1..0 {
            CNOT(register[activeQubits[idx]], register[activeQubits[idx + 1]]);
        }

        for idx in 0..numActive - 1 {
            Adjoint RotateFromZBasis(activeOps[idx], register[activeQubits[idx]]);
        }
    }

    // Adjoint of ExpPauliWord: exp(i * theta * P / 2) = exp(-i * (-theta) * P / 2)
    operation AdjExpPauliWord(theta : Double, word : PauliWord, register : Qubit[]) : Unit {
        ExpPauliWord(-theta, word, register);
    }

    // Measures the parity of an arbitrary Pauli word on the register
    // Returns Result (Zero for +1 eigenvalue, One for -1 eigenvalue)
    operation MeasurePauliWord(word : PauliWord, register : Qubit[]) : Result {
        let numOps = Length(word.Ops);
        mutable activeQubits = [];
        mutable activeOps = [];
        for idx in 0..numOps - 1 {
            if (word.Ops[idx] != PauliI) {
                set activeQubits += [word.Qubits[idx]];
                set activeOps += [word.Ops[idx]];
            }
        }

        let numActive = Length(activeQubits);
        if (numActive == 0) {
            return Zero;
        }

        // Single qubit measurement
        if (numActive == 1) {
            let q = register[activeQubits[0]];
            let p = activeOps[0];
            RotateFromZBasis(p, q);
            let res = M(q);
            Adjoint RotateFromZBasis(p, q);
            return res;
        }

        // Ancilla-assisted non-destructive parity measurement
        use ancilla = Qubit();
        H(ancilla);

        for idx in 0..numActive - 1 {
            let q = register[activeQubits[idx]];
            let p = activeOps[idx];
            if (p == PauliX) {
                Controlled X([ancilla], q);
            } elif (p == PauliY) {
                Controlled Y([ancilla], q);
            } elif (p == PauliZ) {
                Controlled Z([ancilla], q);
            }
        }

        H(ancilla);
        let outcome = M(ancilla);
        Reset(ancilla);
        return outcome;
    }

    // Multi-shot statistical expectation value of a Pauli string
    operation SamplePauliExpectation(word : PauliWord, register : Qubit[], shots : Int) : Double {
        if (shots <= 0) {
            return 0.0;
        }
        mutable plusCount = 0;
        for _ in 1..shots {
            let outcome = MeasurePauliWord(word, register);
            if (outcome == Zero) {
                set plusCount += 1;
            }
        }
        let p0 = IntAsDouble(plusCount) / IntAsDouble(shots);
        // Expectation = P(+1) - P(-1) = 2 * P(+1) - 1
        return 2.0 * p0 - 1.0;
    }
}
