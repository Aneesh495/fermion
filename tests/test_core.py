import unittest
import numpy as np
from runtime.driver import FermionDriver

class TestCoreSubsystem(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.driver = FermionDriver()

    def test_symplectic_vector_creation(self):
        res = self.driver.eval("Fermion.Core.CreateSymplecticVector(4)")
        self.assertEqual(res.NumQubits, 4)
        self.assertEqual(len(res.XBits), 4)
        self.assertEqual(len(res.ZBits), 4)

    def test_symplectic_inner_product(self):
        res = self.driver.eval("""
        operation TestSymplectic() : Int {
            let v1 = Fermion.Core.CreateSymplecticVector(2);
            let v2 = Fermion.Core.CreateSymplecticVector(2);
            return Fermion.Core.SymplecticInnerProduct(v1, v2);
        }
        TestSymplectic()
        """)
        self.assertEqual(res, 0)

    def test_chebyshev_polynomial(self):
        # T_4(0.5) = 8*(0.5)^4 - 8*(0.5)^2 + 1 = 8*(0.0625) - 8*(0.25) + 1 = 0.5 - 2 + 1 = -0.5
        val = self.driver.eval("Fermion.Core.ChebyshevT(4, 0.5)")
        self.assertAlmostEqual(val, -0.5, places=7)

    def test_continued_fraction_expansion(self):
        res = self.driver.eval("Fermion.Core.ContinuedFractionConvergent(0.375, 100)")
        self.assertEqual(res.Numerator, 3)
        self.assertEqual(res.Denominator, 8)

    def test_pauli_words_commutation(self):
        # X0 Z1 and Z0 X1 anticommute: inner prod = (1*1 + 0*0) + (0*0 + 1*1) = 2 = 0 mod 2 => commute!
        res = self.driver.eval("""
        operation TestComm() : Bool {
            let w1 = Fermion.Core.CreatePauliWord(1.0, [PauliX, PauliZ], [0, 1]);
            let w2 = Fermion.Core.CreatePauliWord(1.0, [PauliZ, PauliX], [0, 1]);
            return Fermion.Core.ArePauliWordsCommuting(w1, w2, 2);
        }
        TestComm()
        """)
        self.assertTrue(res)

    def test_bell_state_preparation(self):
        res = self.driver.eval("""
        operation TestBell() : (Result, Result) {
            use q = Qubit[2];
            Fermion.Core.PrepareBellPhiPlus(q[0], q[1]);
            let m = (M(q[0]), M(q[1]));
            ResetAll(q);
            return m;
        }
        TestBell()
        """)
        # In Bell state |Phi+>, measurements of q0 and q1 must be strictly correlated
        self.assertEqual(res[0], res[1])

if __name__ == "__main__":
    unittest.main()
