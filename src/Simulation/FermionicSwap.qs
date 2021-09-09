namespace Fermion.Simulation {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;
    open Fermion.Core;

    // Fermionic SWAP gate (FSWAP):
    // Exchanges two fermionic modes while introducing a -1 phase factor
    // when both modes are occupied:
    // U_FSWAP = SWAP * CZ = |00><00| + |01><10| + |10><01| - |11><11|
    operation ApplyFSWAP(q1 : Qubit, q2 : Qubit) : Unit is Adj + Ctl {
        SWAP(q1, q2);
        CZ(q1, q2);
    }

    // Applies a single parallel layer of FSWAP gates across a 1D linear chain:
    // If isOdd is false: pairs (0,1), (2,3), (4,5), ...
    // If isOdd is true:  pairs (1,2), (3,4), (5,6), ...
    operation ApplyFSWAPLayer(isOdd : Bool, register : Qubit[]) : Unit is Adj + Ctl {
        let n = Length(register);
        let start = isOdd ? 1 | 0;
        let limit = n - 2;

        if (start <= limit) {
            for idx in start..2..limit {
                ApplyFSWAP(register[idx], register[idx + 1]);
            }
        }
    }

    // Executes a complete N-depth Fermionic SWAP sorting network
    // Every pair of fermionic modes (p, q) is brought to adjacent positions
    // on a linear nearest-neighbor architecture exactly once
    operation ExecuteFSWAPNetwork(
        register : Qubit[],
        applyInteractionAtPair : (Int, Int, Qubit, Qubit) => Unit
    ) : Unit {
        let n = Length(register);
        if (n <= 1) {
            return ();
        }

        // Odd-even transposition sorting network running for n rounds
        for round in 0..n - 1 {
            let isOdd = (round % 2 == 1);
            let start = isOdd ? 1 | 0;
            let limit = n - 2;

            if (start <= limit) {
                for idx in start..2..limit {
                    // Apply the nearest-neighbor fermionic interaction at this adjacent pair
                    applyInteractionAtPair(idx, idx + 1, register[idx], register[idx + 1]);
                    // Permute modes using FSWAP
                    ApplyFSWAP(register[idx], register[idx + 1]);
                }
            }
        }
    }

    // Fermionic excitation interaction between adjacent qubits on a 1D chain:
    // exp(-i * theta * (a_p^dagger a_q + a_q^dagger a_p))
    // Because p and q are adjacent, no intermediate Z-string is needed:
    // exp(-i * theta/2 * (X_p X_q + Y_p Y_q))
    operation ApplyAdjacentFermionicInteraction(
        theta : Double,
        qP : Qubit,
        qQ : Qubit
    ) : Unit {
        // XX interaction
        H(qP);
        H(qQ);
        CNOT(qP, qQ);
        Rz(theta, qQ);
        CNOT(qP, qQ);
        H(qP);
        H(qQ);

        // YY interaction
        H(qP);
        S(qP);
        H(qQ);
        S(qQ);
        CNOT(qP, qQ);
        Rz(theta, qQ);
        CNOT(qP, qQ);
        Adjoint S(qP);
        H(qP);
        Adjoint S(qQ);
        H(qQ);
    }
}
