import unittest
from runtime.driver import FermionDriver

class TestVariationalSubsystem(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.driver = FermionDriver()

    def test_ansatz_state_preparation(self):
        res = self.driver.eval("""
        operation TestAnsatz() : Result[] {
            use q = Qubit[2];
            let params = [0.0, 0.0, 0.0, 0.0];
            Fermion.Variational.ApplyHardwareEfficientAnsatz(1, params, q);
            let m = [M(q[0]), M(q[1])];
            ResetAll(q);
            return m;
        }
        TestAnsatz()
        """)
        self.assertEqual(str(res[0]), "Zero")
        self.assertEqual(str(res[1]), "Zero")

    def test_parameter_shift_gradient_at_minimum(self):
        """At theta = 0, expectation of Z on |0> is at a maximum with derivative 0."""
        grad = self.driver.eval("""
        operation TestGradZero() : Double {
            use q = Qubit[2];
            let h = [Fermion.Core.CreatePauliWord(1.0, [PauliZ], [0])];
            let params = [0.0, 0.0, 0.0, 0.0];
            let g = Fermion.Variational.EvaluateParameterShiftGradient(0, h, 1, params, q, 20);
            ResetAll(q);
            return g;
        }
        TestGradZero()
        """)
        self.assertAlmostEqual(grad, 0.0, places=1)

    def test_uccsd_h2_state_initialization(self):
        res = self.driver.eval("""
        operation TestUCCSD() : Result[] {
            use q = Qubit[4];
            Fermion.Variational.PrepareH2UCCSDState(0.0, q);
            let m = [M(q[0]), M(q[1]), M(q[2]), M(q[3])];
            ResetAll(q);
            return m;
        }
        TestUCCSD()
        """)
        # At theta = 0, state is pure Hartree-Fock |1100>
        self.assertEqual(str(res[0]), "One")
        self.assertEqual(str(res[1]), "One")
        self.assertEqual(str(res[2]), "Zero")
        self.assertEqual(str(res[3]), "Zero")

if __name__ == "__main__":
    unittest.main()
