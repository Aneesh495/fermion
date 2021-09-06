namespace Fermion.Simulation {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;
    open Fermion.Core;

    // Changes basis from computational basis to parity basis across register
    // Parity basis: |p_0, p_1, ..., p_{n-1}> where p_j = sum_{k=0}^j n_k mod 2
    operation ComputationalToParityBasis(register : Qubit[]) : Unit is Adj + Ctl {
        let n = Length(register);
        for idx in 0..n - 2 {
            CNOT(register[idx], register[idx + 1]);
        }
    }

    // Inverts parity basis back to computational basis
    operation ParityToComputationalBasis(register : Qubit[]) : Unit is Adj + Ctl {
        let n = Length(register);
        for idx in n - 2..-1..0 {
            CNOT(register[idx], register[idx + 1]);
        }
    }

    // Two-qubit reduction for particle-number conserving molecular Hamiltonians:
    // Tapers the highest spin-orbital qubit for alpha electrons (index n_alpha - 1)
    // and beta electrons (index n_total - 1) using their conserved parity eigenvalues
    function TaperPauliWord(
        word : PauliWord,
        taperIndex1 : Int,
        parityValue1 : Double, // +1.0 or -1.0
        taperIndex2 : Int,
        parityValue2 : Double
    ) : PauliWord {
        mutable newOps = [];
        mutable newQubits = [];
        mutable coeffScale = 1.0;

        for idx in 0..Length(word.Qubits) - 1 {
            let q = word.Qubits[idx];
            let op = word.Ops[idx];

            if (q == taperIndex1) {
                if (op == PauliZ) {
                    set coeffScale *= parityValue1;
                }
                // PauliX and PauliY vanish in particle-conserving sector for parity qubit
            } elif (q == taperIndex2) {
                if (op == PauliZ) {
                    set coeffScale *= parityValue2;
                }
            } else {
                // Adjust index if it is beyond tapered positions
                mutable adjustedQ = q;
                if (q > taperIndex2) {
                    set adjustedQ -= 2;
                } elif (q > taperIndex1) {
                    set adjustedQ -= 1;
                }
                set newOps += [op];
                set newQubits += [adjustedQ];
            }
        }

        return PauliWord(word.Coeff * coeffScale, word.Phase, newOps, newQubits);
    }

    // Tapers an entire Hamiltonian array of Pauli words by eliminating 2 symmetry qubits
    function TaperHamiltonian(
        hamiltonian : PauliWord[],
        numOrbitals : Int,
        numAlphaElectrons : Int,
        numBetaElectrons : Int
    ) : PauliWord[] {
        let alphaTaper = numOrbitals / 2 - 1;
        let betaTaper = numOrbitals - 1;

        let parityAlpha = (numAlphaElectrons % 2 == 0) ? 1.0 | -1.0;
        let parityBeta = (numBetaElectrons % 2 == 0) ? 1.0 | -1.0;

        mutable tapered = [];
        for word in hamiltonian {
            let tw = TaperPauliWord(word, alphaTaper, parityAlpha, betaTaper, parityBeta);
            if (AbsD(tw.Coeff) > 1.0e-12) {
                set tapered += [tw];
            }
        }
        return tapered;
    }
}
