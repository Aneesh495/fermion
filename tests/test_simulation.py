import unittest
import numpy as np
from runtime.driver import FermionDriver
from runtime.classical.exact_diag import ExactDiagonalizationSolver

class TestSimulationSubsystem(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.driver = FermionDriver()

    def test_jordan_wigner_hopping_term_count(self):
        res = self.driver.eval("""
        operation TestJW() : Int {
            let terms = Fermion.Simulation.JordanWignerHopping(0, 2, 1.0);
            return Length(terms);
        }
        TestJW()
        """)
        self.assertEqual(res, 2)

    def test_bravyi_kitaev_tree_structure(self):
        res = self.driver.eval("""
        operation TestBK() : (Int[], Int[]) {
            let u = Fermion.Simulation.BravyiKitaevUpdateSet(0, 4);
            let f = Fermion.Simulation.BravyiKitaevFlipSet(3);
            return (u, f);
        }
        TestBK()
        """)
        update_set, flip_set = res
        self.assertEqual(list(update_set), [1, 3])
        self.assertEqual(list(flip_set), [3])

    def test_parity_basis_transformation(self):
        res = self.driver.eval("""
        operation TestParity() : Result[] {
            use q = Qubit[3];
            X(q[0]);
            X(q[1]);
            Fermion.Simulation.ComputationalToParityBasis(q);
            let m = [M(q[0]), M(q[1]), M(q[2])];
            ResetAll(q);
            return m;
        }
        TestParity()
        """)
        # q0 is 1, q1 is (1+1)%2 = 0, q2 is (1+1+0)%2 = 0
        self.assertEqual(str(res[0]), "One")
        self.assertEqual(str(res[1]), "Zero")
        self.assertEqual(str(res[2]), "Zero")

    def test_fswap_gate(self):
        res = self.driver.eval("""
        operation TestFSWAP() : (Result, Result) {
            use q = Qubit[2];
            X(q[0]); // |10>
            Fermion.Simulation.ApplyFSWAP(q[0], q[1]); // becomes |01>
            let m = (M(q[0]), M(q[1]));
            ResetAll(q);
            return m;
        }
        TestFSWAP()
        """)
        self.assertEqual(str(res[0]), "Zero")
        self.assertEqual(str(res[1]), "One")

    def test_h2_hamiltonian_structure(self):
        res = self.driver.eval("""
        operation TestH2() : (Int, Double) {
            let mol = Fermion.Simulation.GetH2MolecularHamiltonian();
            return (Length(mol.Terms), mol.NuclearRepulsion);
        }
        TestH2()
        """)
        num_terms, v_nn = res
        self.assertEqual(num_terms, 15)
        self.assertAlmostEqual(v_nn, 0.713753, places=5)

    def test_h2_exact_diagonalization_comparison(self):
        """Validates that H2 2-qubit tapered Hamiltonian has correct ground state."""
        solver = ExactDiagonalizationSolver(2)
        # 2-qubit tapered H2 terms from ElectronicStructure.qs
        terms = [
            (-0.321035, ["PauliI"], [0]),
            (0.392942, ["PauliZ"], [0]),
            (-0.392942, ["PauliZ"], [1]),
            (-0.011280, ["PauliZ", "PauliZ"], [0, 1]),
            (0.180931, ["PauliX", "PauliX"], [0, 1]),
        ]
        h_mat = solver.build_hamiltonian_matrix(terms)
        ground_energy, _ = solver.solve_ground_state(h_mat)
        # Ground state energy around -1.137 Hartree
        self.assertAlmostEqual(ground_energy, -1.13727, places=1)

if __name__ == "__main__":
    unittest.main()
