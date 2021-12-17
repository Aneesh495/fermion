import unittest
from runtime.driver import FermionDriver

class TestCharacterizationSubsystem(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.driver = FermionDriver()

    def test_single_qubit_state_tomography_plus_state(self):
        """State |+> should have S1 = <X> ~ 1.0, S2 = <Y> ~ 0.0, S3 = <Z> ~ 0.0."""
        res = self.driver.eval("""
        operation PrepPlus(q : Qubit) : Unit {
            H(q);
        }
        operation TestTomoPlus() : (Double, Double, Double) {
            let s = Fermion.Characterization.PerformSingleQubitTomography(PrepPlus, 500);
            return (s.S1, s.S2, s.S3);
        }
        TestTomoPlus()
        """)
        s1, s2, s3 = res
        self.assertAlmostEqual(s1, 1.0, delta=0.15)
        self.assertAlmostEqual(s2, 0.0, delta=0.15)
        self.assertAlmostEqual(s3, 0.0, delta=0.15)

    def test_single_qubit_state_tomography_zero_state(self):
        """State |0> should have S1 ~ 0.0, S2 ~ 0.0, S3 = <Z> = 1.0."""
        res = self.driver.eval("""
        operation PrepZero(q : Qubit) : Unit { }
        operation TestTomoZero() : (Double, Double, Double) {
            let s = Fermion.Characterization.PerformSingleQubitTomography(PrepZero, 500);
            return (s.S1, s.S2, s.S3);
        }
        TestTomoZero()
        """)
        s1, s2, s3 = res
        self.assertAlmostEqual(s1, 0.0, delta=0.15)
        self.assertAlmostEqual(s2, 0.0, delta=0.15)
        self.assertAlmostEqual(s3, 1.0, delta=0.15)

    def test_randomized_benchmarking_identity_recovery(self):
        """In an ideal noiseless simulator, an RB sequence of any length must return |0> with fidelity 1.0."""
        res = self.driver.eval("""
        operation TestRBZero() : Result {
            use q = Qubit();
            let seq = [1, 4, 8, 12, 16, 20, 3];
            let outcome = Fermion.Characterization.RunRandomizedBenchmarkingSequence(seq, q);
            return outcome;
        }
        TestRBZero()
        """)
        self.assertEqual(str(res), "Zero")

    def test_chsh_inequality_violation(self):
        """Verifies that quantum entanglement strictly violates the classical bound S <= 2."""
        res = self.driver.run_chsh_test(shots=500)
        s_val = res["S"]
        self.assertTrue(s_val > 2.0, f"Expected S > 2.0, got {s_val}")
        self.assertAlmostEqual(s_val, 2.828, delta=0.25)

if __name__ == "__main__":
    unittest.main()
