namespace Fermion.Simulation {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;
    open Fermion.Core;

    // Generates the 1D Fermi-Hubbard Hamiltonian as an array of Pauli words
    // L: number of spatial lattice sites (total qubits = 2 * L)
    // t: kinetic hopping parameter
    // u: on-site Coulomb repulsion parameter
    // mu: chemical potential
    // periodic: True for periodic boundary conditions, False for open
    function Generate1DHubbardHamiltonian(
        l : Int,
        t : Double,
        u : Double,
        mu : Double,
        periodic : Bool
    ) : PauliWord[] {
        mutable terms = [];
        let maxSite = periodic ? l - 1 | l - 2;

        // 1. Kinetic hopping terms for both spin channels (alpha=0, beta=1)
        for i in 0..maxSite {
            let nextSite = (i + 1) % l;

            // Spin-up (even indices: 2*i, 2*nextSite)
            let hopUp = JordanWignerHopping(2 * i, 2 * nextSite, -t);
            for w in hopUp {
                set terms += [w];
            }

            // Spin-down (odd indices: 2*i + 1, 2*nextSite + 1)
            let hopDown = JordanWignerHopping(2 * i + 1, 2 * nextSite + 1, -t);
            for w in hopDown {
                set terms += [w];
            }
        }

        // 2. On-site interaction U * n_{i,up} * n_{i,down}
        // and chemical potential -mu * (n_{i,up} + n_{i,down})
        for i in 0..l - 1 {
            let qUp = 2 * i;
            let qDown = 2 * i + 1;

            // On-site interaction: U/4 * (I - Z_up - Z_down + Z_up * Z_down)
            let ddTerms = JordanWignerDensityDensity(qUp, qDown, u);
            for w in ddTerms {
                set terms += [w];
            }

            // Chemical potential: -mu/2 * (I - Z_up) - mu/2 * (I - Z_down)
            if (AbsD(mu) > 1.0e-12) {
                let muUp = JordanWignerNumberOperator(qUp, -mu);
                let muDown = JordanWignerNumberOperator(qDown, -mu);
                for w in muUp { set terms += [w]; }
                for w in muDown { set terms += [w]; }
            }
        }

        return terms;
    }

    // Measures average double occupancy across lattice: D = (1/L) * sum_i <n_{i,up} n_{i,down}>
    operation MeasureDoubleOccupancy(l : Int, register : Qubit[]) : Double {
        mutable totalDoubleOcc = 0.0;
        for i in 0..l - 1 {
            let qUp = 2 * i;
            let qDown = 2 * i + 1;

            // Measure <Z_up>, <Z_down>, and <Z_up Z_down>
            let zUpWord = CreatePauliWord(1.0, [PauliZ], [qUp]);
            let zDownWord = CreatePauliWord(1.0, [PauliZ], [qDown]);
            let zzWord = CreatePauliWord(1.0, [PauliZ, PauliZ], [qUp, qDown]);

            let expUp = SamplePauliExpectation(zUpWord, register, 20);
            let expDown = SamplePauliExpectation(zDownWord, register, 20);
            let expZZ = SamplePauliExpectation(zzWord, register, 20);

            // <n_up n_down> = (1 - <Z_up> - <Z_down> + <ZZ>) / 4
            let siteOcc = (1.0 - expUp - expDown + expZZ) * 0.25;
            set totalDoubleOcc += siteOcc;
        }
        return totalDoubleOcc / IntAsDouble(l);
    }
}
