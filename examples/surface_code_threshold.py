import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from runtime.driver import FermionDriver
from runtime.decoders.mwpm import MWPMDecoder
from runtime.visualizer.lattice import format_surface_code_lattice

def main():
    print("========================================================================")
    print("   FERMION EXAMPLE: Distance-3 Surface Code & Blossom MWPM Decoding")
    print("========================================================================")
    driver = FermionDriver()
    print("[*] Extracting syndrome stream across 17-qubit rotated planar surface code...")
    syndromes = driver.run_surface_code_cycle()
    print(format_surface_code_lattice(3, syndromes))

    decoder = MWPMDecoder(3)
    corrections = decoder.decode_syndrome(syndromes)
    print(f"[+] Syndrome bits: {syndromes}")
    print(f"[+] Correction chain derived by Blossom MWPM: Data Qubits {corrections}")
    print("========================================================================")

if __name__ == "__main__":
    main()
