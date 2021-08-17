namespace Fermion.Core {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;

    // Prepares the 2-qubit Bell state |Phi+> = (|00> + |11>) / sqrt(2)
    operation PrepareBellPhiPlus(q0 : Qubit, q1 : Qubit) : Unit is Adj + Ctl {
        H(q0);
        CNOT(q0, q1);
    }

    // Prepares the 2-qubit Bell state |Psi+> = (|01> + |10>) / sqrt(2)
    operation PrepareBellPsiPlus(q0 : Qubit, q1 : Qubit) : Unit is Adj + Ctl {
        H(q0);
        X(q1);
        CNOT(q0, q1);
    }

    // Prepares the n-qubit Greenberger-Horne-Zeilinger (GHZ) state
    // |GHZ_n> = (|00...0> + |11...1>) / sqrt(2)
    operation PrepareGHZ(register : Qubit[]) : Unit is Adj + Ctl {
        let n = Length(register);
        if (n > 0) {
            H(register[0]);
            for idx in 0..n - 2 {
                CNOT(register[idx], register[idx + 1]);
            }
        }
    }

    // Prepares the n-qubit W state |W_n> = (|10...0> + |01...0> + ... + |0...01>) / sqrt(n)
    // Uses recursive deterministic controlled rotations
    operation PrepareWState(register : Qubit[]) : Unit {
        let n = Length(register);
        if (n == 0) {
            return ();
        }
        if (n == 1) {
            X(register[0]);
            return ();
        }

        // Initialize first qubit to |1>
        X(register[0]);

        for k in 0..n - 2 {
            let remaining = n - k;
            let theta = 2.0 * ArcSin(1.0 / Sqrt(IntAsDouble(remaining)));
            // Controlled rotation transferring amplitude from register[k] to register[k+1]
            Controlled Ry([register[k]], (theta, register[k + 1]));
            CNOT(register[k + 1], register[k]);
        }
    }

    // Prepares the Hartree-Fock state for a molecular system with numElectrons occupied spin-orbitals
    // |HF> = |1...1 0...0>
    operation PrepareHartreeFock(numElectrons : Int, register : Qubit[]) : Unit is Adj + Ctl {
        let n = Length(register);
        let limit = numElectrons < n ? numElectrons | n;
        for idx in 0..limit - 1 {
            X(register[idx]);
        }
    }

    // Prepares a computational basis state corresponding to an integer bitstring
    operation PrepareBasisState(bitstring : Int, register : Qubit[]) : Unit is Adj + Ctl {
        let n = Length(register);
        for idx in 0..n - 1 {
            if (((bitstring >>> idx) &&& 1) == 1) {
                X(register[idx]);
            }
        }
    }

    // Applies a single-particle Givens rotation between orbitals p and q:
    // exp(theta * (a_p^dagger a_q - a_q^dagger a_p))
    // In qubit basis via Jordan-Wigner for adjacent qubits:
    // exp(-i * theta/2 * (X_p Y_q - Y_p X_q))
    operation ApplyFermionicGivens(theta : Double, qP : Qubit, qQ : Qubit) : Unit {
        CNOT(qP, qQ);
        Controlled Ry([qQ], (-2.0 * theta, qP));
        CNOT(qP, qQ);
    }

    // Prepares a single-excitation Dicke state |D_1^n> which is identical to |W_n>
    operation PrepareDickeOne(register : Qubit[]) : Unit {
        PrepareWState(register);
    }

    // Uniform superposition across n qubits |+>^n
    operation PrepareUniformSuperposition(register : Qubit[]) : Unit is Adj + Ctl {
        for q in register {
            H(q);
        }
    }
}
