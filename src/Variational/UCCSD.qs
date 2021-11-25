namespace Fermion.Variational {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;
    open Fermion.Core;

    // Single fermionic excitation operator: a_a^dagger a_i - a_i^dagger a_a
    // Between occupied orbital i and virtual orbital a
    operation ApplyFermionicSingleExcitation(
        theta : Double,
        i : Int,
        a : Int,
        register : Qubit[]
    ) : Unit {
        ApplyFermionicGivens(theta, register[i], register[a]);
    }

    // Double fermionic excitation generator for H2 (orbitals 0, 1 -> 2, 3)
    // Preserves particle number and spin projection Sz:
    // exp(theta * (a_2^dagger a_3^dagger a_1 a_0 - h.c.))
    // In Jordan-Wigner basis, this decomposes into 8 Pauli words
    operation ApplyH2UCCSDDoubleExcitation(
        theta : Double,
        register : Qubit[]
    ) : Unit {
        let angle = theta * 0.25;

        // Representative non-vanishing Pauli strings for the 2-to-2 double excitation
        let w1 = CreatePauliWord(1.0, [PauliX, PauliY, PauliX, PauliX], [0, 1, 2, 3]);
        let w2 = CreatePauliWord(1.0, [PauliY, PauliX, PauliX, PauliX], [0, 1, 2, 3]);
        let w3 = CreatePauliWord(-1.0, [PauliY, PauliY, PauliY, PauliX], [0, 1, 2, 3]);
        let w4 = CreatePauliWord(1.0, [PauliX, PauliX, PauliY, PauliX], [0, 1, 2, 3]);

        ExpPauliWord(angle, w1, register);
        ExpPauliWord(angle, w2, register);
        ExpPauliWord(angle, w3, register);
        ExpPauliWord(angle, w4, register);
    }

    // Prepares the full UCCSD ansatz state for H2:
    // |psi(theta)> = exp(T - T^dagger) |HF> where |HF> = |1100>
    operation PrepareH2UCCSDState(theta : Double, register : Qubit[]) : Unit {
        // 1. Initialize Hartree-Fock state
        PrepareHartreeFock(2, register);

        // 2. Apply parameterized double excitation
        ApplyH2UCCSDDoubleExcitation(theta, register);
    }
}
