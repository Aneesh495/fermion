namespace Fermion.Topology {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;
    open Fermion.Core;

    // Single topological braiding operation between Majorana modes gamma_i and gamma_j:
    // B_ij = exp(pi/4 * gamma_i * gamma_j) = (1 + gamma_i * gamma_j) / sqrt(2)
    // On the encoded topological qubit (modes 0, 1, 2, 3 mapped to 1 logical qubit):
    // - Braiding (0, 1): gamma_0 gamma_1 = -i * Z_L => B_01 = exp(-i * pi/4 * Z_L) = S gate
    // - Braiding (1, 2): gamma_1 gamma_2 = -i * X_L => B_12 = exp(-i * pi/4 * X_L) = Rx(pi/2)
    // - Braiding (2, 3): gamma_2 gamma_3 = -i * Z_L => B_23 = exp(-i * pi/4 * Z_L)
    operation ApplyMajoranaBraid(modeA : Int, modeB : Int, logicalQubit : Qubit) : Unit {
        let low = modeA < modeB ? modeA | modeB;
        let high = modeA < modeB ? modeB | modeA;

        if (low == 0 and high == 1) {
            // S gate = exp(-i * pi/4 * Z) up to global phase
            Rz(PI() * 0.5, logicalQubit);
        } elif (low == 1 and high == 2) {
            // Rx(pi/2) gate = exp(-i * pi/4 * X)
            Rx(PI() * 0.5, logicalQubit);
        } elif (low == 2 and high == 3) {
            // Phase gate S
            Rz(PI() * 0.5, logicalQubit);
        } elif (low == 0 and high == 2) {
            // Ry(pi/2) gate = exp(-i * pi/4 * Y)
            Ry(PI() * 0.5, logicalQubit);
        }
    }

    // Synthesizes the logical Hadamard gate H via pure Majorana braiding:
    // H = B_01 * B_12 * B_01
    operation ApplyTopologicalHadamard(logicalQubit : Qubit) : Unit {
        ApplyMajoranaBraid(0, 1, logicalQubit);
        ApplyMajoranaBraid(1, 2, logicalQubit);
        ApplyMajoranaBraid(0, 1, logicalQubit);
    }

    // Synthesizes the logical Phase gate S via Majorana braiding:
    // S = B_01
    operation ApplyTopologicalPhaseGate(logicalQubit : Qubit) : Unit {
        ApplyMajoranaBraid(0, 1, logicalQubit);
    }

    // Synthesizes the logical Pauli X gate via Majorana braiding:
    // X = B_12^2
    operation ApplyTopologicalPauliX(logicalQubit : Qubit) : Unit {
        ApplyMajoranaBraid(1, 2, logicalQubit);
        ApplyMajoranaBraid(1, 2, logicalQubit);
    }

    // Synthesizes the logical Pauli Z gate via Majorana braiding:
    // Z = B_01^2
    operation ApplyTopologicalPauliZ(logicalQubit : Qubit) : Unit {
        ApplyMajoranaBraid(0, 1, logicalQubit);
        ApplyMajoranaBraid(0, 1, logicalQubit);
    }

    // Verifies the non-Abelian Artin braid relation:
    // B_1 B_2 B_1 == B_2 B_1 B_2
    operation VerifyArtinBraidRelation() : Bool {
        use q1 = Qubit();
        use q2 = Qubit();

        // Path 1: B_1 B_2 B_1
        ApplyMajoranaBraid(0, 1, q1);
        ApplyMajoranaBraid(1, 2, q1);
        ApplyMajoranaBraid(0, 1, q1);

        // Path 2: B_2 B_1 B_2
        ApplyMajoranaBraid(1, 2, q2);
        ApplyMajoranaBraid(0, 1, q2);
        ApplyMajoranaBraid(1, 2, q2);

        // Compare state overlaps via SWAP test
        use ancilla = Qubit();
        H(ancilla);
        Controlled SWAP([ancilla], (q1, q2));
        H(ancilla);
        let res = M(ancilla);

        Reset(q1);
        Reset(q2);
        Reset(ancilla);

        return res == Zero;
    }
}
