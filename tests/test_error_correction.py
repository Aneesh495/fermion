import unittest
from runtime.driver import FermionDriver
from runtime.decoders.mwpm import MWPMDecoder
from runtime.decoders.lookup import LookupTableDecoder

class TestErrorCorrectionSubsystem(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.driver = FermionDriver()
        cls.mwpm = MWPMDecoder(3)
        cls.lookup = LookupTableDecoder()

    def test_steane_check_count(self):
        checks_len = self.driver.eval("Length(Fermion.ErrorCorrection.GetSteaneStabilizerChecks())")
        self.assertEqual(checks_len, 6)

    def test_steane_active_x_error_correction(self):
        """Verifies active detection and correction of single-qubit X errors."""
        res = self.driver.eval("""
        operation TestXCorr() : (Int, Int) {
            use q = Qubit[7];
            Fermion.ErrorCorrection.EncodeSteaneCode(q);
            X(q[2]);
            let (xLoc, zLoc) = Fermion.ErrorCorrection.CorrectSteaneCodeErrors(q);
            ResetAll(q);
            return (xLoc, zLoc);
        }
        TestXCorr()
        """)
        x_loc, z_loc = res
        self.assertEqual(x_loc, 2)
        self.assertEqual(z_loc, -1)

    def test_steane_active_z_error_correction(self):
        """Verifies active detection and correction of single-qubit Z errors."""
        res = self.driver.eval("""
        operation TestZCorr() : (Int, Int) {
            use q = Qubit[7];
            Fermion.ErrorCorrection.EncodeSteaneCode(q);
            Z(q[5]);
            let (xLoc, zLoc) = Fermion.ErrorCorrection.CorrectSteaneCodeErrors(q);
            ResetAll(q);
            return (xLoc, zLoc);
        }
        TestZCorr()
        """)
        x_loc, z_loc = res
        self.assertEqual(x_loc, -1)
        self.assertEqual(z_loc, 5)

    def test_shor_code_stabilizer_count(self):
        length = self.driver.eval("Length(Fermion.ErrorCorrection.GetShorCodeStabilizerChecks())")
        self.assertEqual(length, 8)

    def test_surface_code_distance_3_checks(self):
        length = self.driver.eval("Length(Fermion.ErrorCorrection.GetSurfaceCodeD3Checks())")
        self.assertEqual(length, 8)

    def test_toric_code_star_edges(self):
        edges = self.driver.eval("Fermion.ErrorCorrection.StarStabilizerEdges(1, 1, 3)")
        self.assertEqual(len(edges), 4)

    def test_color_code_faces(self):
        length = self.driver.eval("Length(Fermion.ErrorCorrection.GetDistance3ColorCodeFaces())")
        self.assertEqual(length, 3)

    def test_mwpm_decoder_clean_syndrome(self):
        clean_syndrome = [False] * 8
        corrections = self.mwpm.decode_syndrome(clean_syndrome)
        self.assertEqual(corrections, [])

    def test_mwpm_decoder_defects(self):
        syndrome_with_defects = [True, False, True, False, False, False, False, False]
        corrections = self.mwpm.decode_syndrome(syndrome_with_defects)
        self.assertTrue(len(corrections) > 0)

    def test_lookup_decoder_steane(self):
        self.assertEqual(self.lookup.decode_steane_syndrome(True, False, False), 0)
        self.assertEqual(self.lookup.decode_steane_syndrome(True, True, True), 6)
        self.assertEqual(self.lookup.decode_steane_syndrome(False, False, False), -1)

if __name__ == "__main__":
    unittest.main()
