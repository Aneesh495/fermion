namespace Fermion.Topology {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;
    open Fermion.Core;
    open Fermion.Simulation;

    // Generates the 1D Kitaev p-wave superconducting wire Hamiltonian
    // in the spinless fermionic basis mapped to qubits via Jordan-Wigner:
    // H = -w sum (c_j^dagger c_{j+1} + h.c.) - mu sum c_j^dagger c_j + Delta sum (c_j c_{j+1} + h.c.)
    function GenerateKitaevWireHamiltonian(
        numSites : Int,
        hoppingW : Double,
        deltaPairing : Double,
        chemicalMu : Double
    ) : PauliWord[] {
        mutable terms = [];

        // 1. Kinetic hopping -w (c_j^dagger c_{j+1} + h.c.)
        for j in 0..numSites - 2 {
            let hopTerms = JordanWignerHopping(j, j + 1, -hoppingW);
            for w in hopTerms {
                set terms += [w];
            }
        }

        // 2. p-wave superconducting pairing: Delta (c_j c_{j+1} + h.c.)
        // In Jordan-Wigner: Delta/2 * (-X_j X_{j+1} + Y_j Y_{j+1})
        for j in 0..numSites - 2 {
            let xxWord = CreatePauliWord(-deltaPairing * 0.5, [PauliX, PauliX], [j, j + 1]);
            let yyWord = CreatePauliWord(deltaPairing * 0.5, [PauliY, PauliY], [j, j + 1]);
            set terms += [xxWord, yyWord];
        }

        // 3. Chemical potential -mu c_j^dagger c_j
        if (AbsD(chemicalMu) > 1.0e-12) {
            for j in 0..numSites - 1 {
                let numTerms = JordanWignerNumberOperator(j, -chemicalMu);
                for w in numTerms {
                    set terms += [w];
                }
            }
        }

        return terms;
    }

    // Evaluates whether the parameters place the wire in the non-trivial topological phase
    // Topological condition: |mu| < 2 * |w| and Delta > 0
    function IsWireTopological(hoppingW : Double, chemicalMu : Double, deltaPairing : Double) : Bool {
        return (AbsD(chemicalMu) < 2.0 * AbsD(hoppingW)) and (AbsD(deltaPairing) > 1.0e-12);
    }

    // Topological ground-state parity operator:
    // P = i * gamma_1 * gamma_{2N}
    // In Jordan-Wigner, this corresponds to the non-local string: Z_0 Z_1 ... Z_{N-1}
    function WireTopologicalParityOperator(numSites : Int) : PauliWord {
        mutable ops = [PauliZ, size = numSites];
        mutable qubits = [0, size = numSites];
        for j in 0..numSites - 1 {
            set qubits w/= j <- j;
        }
        return CreatePauliWord(1.0, ops, qubits);
    }

    // Measures the topological ground-state parity of the Kitaev wire
    operation MeasureWireParity(numSites : Int, register : Qubit[]) : Result {
        let parityOp = WireTopologicalParityOperator(numSites);
        return MeasurePauliWord(parityOp, register);
    }
}
