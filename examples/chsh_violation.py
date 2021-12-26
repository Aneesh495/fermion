import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from runtime.driver import FermionDriver

def main():
    print("========================================================================")
    print("   FERMION EXAMPLE: Quantum Non-Locality & Bell-CHSH Violation")
    print("========================================================================")
    driver = FermionDriver()
    print("[*] Sampling 1000 shots across 4 mutually unbiased measurement bases...")
    res = driver.run_chsh_test(shots=1000)
    print(f"[+] Correlation E(A0, B0): {res['E00']:+.4f}")
    print(f"[+] Correlation E(A0, B1): {res['E01']:+.4f}")
    print(f"[+] Correlation E(A1, B0): {res['E10']:+.4f}")
    print(f"[+] Correlation E(A1, B1): {res['E11']:+.4f}")
    print(f"[+] CHSH S-parameter:     {res['S']:+.4f}")
    print(f"[+] Classical Local Limit: 2.0000")
    print(f"[+] Cirel'son Bound:       2.8284")
    print(f"[+] Excess above Limit:   {res['S'] - 2.0:+.4f} ({((res['S'] - 2.0)/2.0)*100.0:.2f}%)")
    print("========================================================================")

if __name__ == "__main__":
    main()
