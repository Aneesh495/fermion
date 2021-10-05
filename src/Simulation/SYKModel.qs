namespace Fermion.Simulation {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;
    open Fermion.Core;

    // Maps a 4-Majorana interaction term gamma_i gamma_j gamma_k gamma_l (with i < j < k < l)
    // to a PauliWord using the standard Jordan-Wigner Majorana representation:
    // gamma_{2p} = X_p Z_{p-1} ... Z_0
    // gamma_{2p+1} = Y_p Z_{p-1} ... Z_0
    function MajoranaQuartetToPauliWord(
        i : Int,
        j : Int,
        k : Int,
        l : Int,
        coupling : Double
    ) : PauliWord {
        let pI = i / 2;
        let pJ = j / 2;
        let pK = k / 2;
        let pL = l / 2;

        let opI = (i % 2 == 0) ? PauliX | PauliY;
        let opJ = (j % 2 == 0) ? PauliX | PauliY;
        let opK = (k % 2 == 0) ? PauliX | PauliY;
        let opL = (l % 2 == 0) ? PauliX | PauliY;

        // Collect support qubits and operators
        mutable qubits = [pI, pJ, pK, pL];
        mutable ops = [opI, opJ, opK, opL];

        return CreatePauliWord(coupling, ops, qubits);
    }

    // Generates a representative Sachdev-Ye-Kitaev (SYK4) Hamiltonian
    // for N = 8 Majorana modes (4 qubits) with normalized coupling scale J = 1.0
    function GenerateSYK4Hamiltonian() : PauliWord[] {
        let jCoupling = 1.0;
        let c = jCoupling / Sqrt(8.0);
        return [
            MajoranaQuartetToPauliWord(0, 1, 2, 3,  0.412 * c),
            MajoranaQuartetToPauliWord(0, 1, 4, 5, -0.285 * c),
            MajoranaQuartetToPauliWord(0, 1, 6, 7,  0.334 * c),
            MajoranaQuartetToPauliWord(2, 3, 4, 5,  0.512 * c),
            MajoranaQuartetToPauliWord(2, 3, 6, 7, -0.198 * c),
            MajoranaQuartetToPauliWord(4, 5, 6, 7,  0.377 * c),
            MajoranaQuartetToPauliWord(0, 2, 4, 6, -0.451 * c),
            MajoranaQuartetToPauliWord(1, 3, 5, 7,  0.299 * c)
        ];
    }

    // Measures the Out-Of-Time-Ordered Correlator (OTOC) witness:
    // F(t) = Re < W^dagger(t) V^dagger(0) W(t) V(0) >
    // Fast scrambling diagnostic: F(t) decays exponentially with Lyapunov exponent lambda_L
    operation MeasureSYKOTOC(
        t : Double,
        steps : Int,
        register : Qubit[]
    ) : Double {
        let syk = GenerateSYK4Hamiltonian();

        // Prepare maximally mixed / entangled reference state
        PrepareUniformSuperposition(register);

        // V = Z on qubit 0
        Z(register[0]);

        // Forward evolution exp(-i * H * t)
        SimulateHamiltonianEvolution(syk, t, steps, 2, register);

        // W = X on qubit 3
        X(register[3]);

        // Backward evolution exp(+i * H * t)
        SimulateHamiltonianEvolution(syk, -t, steps, 2, register);

        // V^dagger = Z on qubit 0
        Z(register[0]);

        // Forward evolution exp(-i * H * t)
        SimulateHamiltonianEvolution(syk, t, steps, 2, register);

        // W^dagger = X on qubit 3
        X(register[3]);

        // Backward evolution exp(+i * H * t)
        SimulateHamiltonianEvolution(syk, -t, steps, 2, register);

        // Measure survival probability / expectation on reference state
        let word = CreatePauliWord(1.0, [PauliZ], [0]);
        let expVal = SamplePauliExpectation(word, register, 20);

        return expVal;
    }
}
