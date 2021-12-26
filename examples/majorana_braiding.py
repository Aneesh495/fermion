import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from runtime.driver import FermionDriver

def main():
    print("========================================================================")
    print("   FERMION EXAMPLE: Non-Abelian Majorana & Fibonacci Anyon Braiding")
    print("========================================================================")
    driver = FermionDriver()
    print("[*] Verifying Artin Braid Group B_n relations on Majorana zero modes...")
    artin_ok = driver.verify_braiding()
    print(f"[+] Majorana Braid Relation (B1 B2 B1 == B2 B1 B2): {'CONFIRMED' if artin_ok else 'FAILED'}")

    print("[*] Verifying universal Fibonacci anyon pentagon/hexagon braiding...")
    fib_ok = driver.verify_fibonacci_braid()
    print(f"[+] Fibonacci Braid Relation (s1 s2 s1 == s2 s1 s2): {'CONFIRMED' if fib_ok else 'FAILED'}")
    print("========================================================================")

if __name__ == "__main__":
    main()
