import os
import sys

# Ensure project root is in sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from runtime.driver import FermionDriver

def main():
    print("========================================================================")
    print("   FERMION EXAMPLE: Molecular Hydrogen Ground State QPE")
    print("========================================================================")
    driver = FermionDriver()
    print("[*] Running iterative Quantum Phase Estimation for H2 (6 precision bits)...")
    energy = driver.run_h2_simulation(bits=6)
    print(f"[+] Computed Energy:       {energy:.6f} Hartree")
    print(f"[+] Exact FCI Energy:     -1.137270 Hartree")
    print(f"[+] Nuclear Repulsion Vnn: 0.713753 Hartree")
    print("========================================================================")

if __name__ == "__main__":
    main()
