namespace Fermion.Simulation {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;
    open Fermion.Core;

    // Returns the exact 4-qubit Jordan-Wigner Hamiltonian for H2 at equilibrium (R = 0.7414 A)
    // Nuclear repulsion V_nn = 0.713753 Hartree
    // True FCI ground state energy = -1.137270 Hartree
    function GetH2MolecularHamiltonian() : MolecularHamiltonian {
        let v_nn = 0.713753;
        let terms = [
            // Constant identity shift
            CreatePauliWord(-0.098863 + v_nn, [PauliI], [0]),
            // One-qubit Z terms
            CreatePauliWord(0.171201, [PauliZ], [0]),
            CreatePauliWord(-0.222796, [PauliZ], [1]),
            CreatePauliWord(0.171201, [PauliZ], [2]),
            CreatePauliWord(-0.222796, [PauliZ], [3]),
            // Two-qubit ZZ terms
            CreatePauliWord(0.168623, [PauliZ, PauliZ], [0, 1]),
            CreatePauliWord(0.120546, [PauliZ, PauliZ], [0, 2]),
            CreatePauliWord(0.165868, [PauliZ, PauliZ], [0, 3]),
            CreatePauliWord(0.165868, [PauliZ, PauliZ], [1, 2]),
            CreatePauliWord(0.120546, [PauliZ, PauliZ], [1, 3]),
            CreatePauliWord(0.174349, [PauliZ, PauliZ], [2, 3]),
            // Non-commuting hopping/exchange terms (entangling interactions)
            CreatePauliWord(-0.045322, [PauliX, PauliZ, PauliZ, PauliX], [0, 1, 2, 3]),
            CreatePauliWord(-0.045322, [PauliY, PauliZ, PauliZ, PauliY], [0, 1, 2, 3]),
            CreatePauliWord(0.045322, [PauliX, PauliZ, PauliZ, PauliY], [0, 1, 2, 3]),
            CreatePauliWord(0.045322, [PauliY, PauliZ, PauliZ, PauliX], [0, 1, 2, 3])
        ];
        return MolecularHamiltonian(4, v_nn, terms);
    }

    // Returns the 2-qubit symmetry-tapered H2 Hamiltonian
    // Obtained by tapering qubits 1 and 3 using parity symmetries (Z1 = +1, Z3 = -1)
    function GetH2TaperedHamiltonian() : PauliWord[] {
        return [
            CreatePauliWord(-0.321035, [PauliI], [0]),
            CreatePauliWord(0.392942, [PauliZ], [0]),
            CreatePauliWord(-0.392942, [PauliZ], [1]),
            CreatePauliWord(-0.011280, [PauliZ, PauliZ], [0, 1]),
            CreatePauliWord(0.180931, [PauliX, PauliX], [0, 1])
        ];
    }

    // Returns the active space Hamiltonian for Lithium Hydride (LiH) at R = 1.595 A
    // Nuclear repulsion V_nn = 0.995321 Hartree
    function GetLiHMolecularHamiltonian() : MolecularHamiltonian {
        let v_nn = 0.995321;
        let terms = [
            CreatePauliWord(-3.8505 + v_nn, [PauliI], [0]),
            CreatePauliWord(0.2834, [PauliZ], [0]),
            CreatePauliWord(0.2834, [PauliZ], [1]),
            CreatePauliWord(-0.3912, [PauliZ], [2]),
            CreatePauliWord(-0.3912, [PauliZ], [3]),
            CreatePauliWord(0.1172, [PauliZ, PauliZ], [0, 1]),
            CreatePauliWord(0.1084, [PauliZ, PauliZ], [0, 2]),
            CreatePauliWord(0.1084, [PauliZ, PauliZ], [1, 3]),
            CreatePauliWord(0.1432, [PauliZ, PauliZ], [2, 3]),
            CreatePauliWord(0.0573, [PauliX, PauliZ, PauliZ, PauliX], [0, 1, 2, 3]),
            CreatePauliWord(0.0573, [PauliY, PauliZ, PauliZ, PauliY], [0, 1, 2, 3])
        ];
        return MolecularHamiltonian(4, v_nn, terms);
    }

    // Helper to apply controlled H2 evolution powers
    operation ApplyControlledH2Power(power : Int, control : Qubit, target : Qubit[]) : Unit {
        let mol = GetH2MolecularHamiltonian();
        let dt = 1.0 * IntAsDouble(power) / 4.0;
        for _ in 1..4 {
            for word in mol.Terms {
                let angle = 2.0 * word.Coeff * dt;
                ControlledExpPauliWord(control, angle, word, target);
            }
        }
    }

    // Runs Ground-State Quantum Phase Estimation for H2
    operation RunH2PhaseEstimation(bits : Int) : Double {
        use target = Qubit[4];
        // Initialize target into Hartree-Fock state |1100> (2 electrons in 4 spin-orbitals)
        PrepareHartreeFock(2, target);

        let phase = RunIterativeQPE(bits, target, ApplyControlledH2Power);
        let energy = PhaseToHamiltonianEnergy(phase, 1.0);

        ResetAll(target);
        return energy;
    }
}
