import unittest
from runtime.driver import FermionDriver

class TestTopologySubsystem(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.driver = FermionDriver()

    def test_kitaev_wire_topological_condition(self):
        # |mu| < 2|w| and Delta > 0 is topological
        self.assertTrue(self.driver.eval("Fermion.Topology.IsWireTopological(1.0, 0.5, 0.8)"))
        # |mu| > 2|w| is topologically trivial
        self.assertFalse(self.driver.eval("Fermion.Topology.IsWireTopological(1.0, 2.5, 0.8)"))

    def test_majorana_artin_braid_relation(self):
        # B1 B2 B1 == B2 B1 B2
        self.assertTrue(self.driver.verify_braiding())

    def test_fibonacci_pentagon_hexagon_braid_relation(self):
        # s1 s2 s1 == s2 s1 s2 on Fibonacci fusion space
        self.assertTrue(self.driver.verify_fibonacci_braid())

    def test_topological_hadamard_braid_word_length(self):
        length = self.driver.eval("Length(Fermion.Topology.GetTopologicalHadamardBraidWord())")
        self.assertEqual(length, 11)

    def test_topological_t_gate_braid_word_length(self):
        length = self.driver.eval("Length(Fermion.Topology.GetTopologicalTBraidWord())")
        self.assertEqual(length, 12)

if __name__ == "__main__":
    unittest.main()
