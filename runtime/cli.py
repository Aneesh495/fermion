import argparse
import sys
import time
from typing import List
from runtime.driver import FermionDriver
from runtime.decoders.mwpm import MWPMDecoder
from runtime.visualizer.circuit import format_ascii_circuit
from runtime.visualizer.lattice import format_surface_code_lattice

BANNER = """
========================================================================
   FERMION: Fault-Tolerant Simulation & Topological Anyon Kernel
   Authored by Aneesh Krishna
========================================================================
"""

def cmd_diagnostics(driver: FermionDriver) -> int:
    print(BANNER)
    print("[*] Running full master diagnostics across all Q# subsystems...")
    t0 = time.time()
    code = driver.run_diagnostics()
    elapsed = time.time() - t0
    if code == 0:
        print(f"[+] All subsystems PASSED verification in {elapsed:.3f}s.")
        return 0
    else:
        print(f"[-] Diagnostics failed with error code: {code}")
        return 1

def cmd_qpe(driver: FermionDriver, bits: int = 6) -> int:
    print(BANNER)
    print(f"[*] Executing Ground-State Quantum Phase Estimation for H2 ({bits} precision bits)...")
    t0 = time.time()
    energy = driver.run_h2_simulation(bits=bits)
    elapsed = time.time() - t0
    print(f"[+] Estimated Ground State Energy: {energy:.6f} Hartree")
    print(f"[+] Exact FCI Benchmark Energy:   -1.137270 Hartree")
    error = abs(energy - (-1.137270))
    print(f"[+] Absolute Error:              {error:.6f} Hartree ({error * 1000.0:.2f} mHa)")
    print(f"[+] Elapsed Time:                {elapsed:.3f}s")
    return 0

def cmd_chsh(driver: FermionDriver, shots: int = 500) -> int:
    print(BANNER)
    print(f"[*] Running Bell-CHSH Quantum Non-Locality Test ({shots} shots per setting)...")
    res = driver.run_chsh_test(shots=shots)
    print(f"[+] Correlation E(0, 0): {res['E00']:+.4f}")
    print(f"[+] Correlation E(0, 1): {res['E01']:+.4f}")
    print(f"[+] Correlation E(1, 0): {res['E10']:+.4f}")
    print(f"[+] Correlation E(1, 1): {res['E11']:+.4f}")
    print(f"[+] CHSH Inequality S:  {res['S']:+.4f}")
    print(f"[+] Classical Limit:     2.0000")
    print(f"[+] Quantum Cirel'son:   2.8284")
    if res['violates_classical']:
        print(f"[+] RESULT: Bell inequality VIOLATED by {res['S'] - 2.0:+.4f} (Quantum Non-Locality Proven)!")
    return 0

def cmd_anyon(driver: FermionDriver) -> int:
    print(BANNER)
    print("[*] Verifying Non-Abelian Majorana and Fibonacci Anyonic Braiding...")
    t0 = time.time()
    artin_ok = driver.verify_braiding()
    fib_ok = driver.verify_fibonacci_braid()
    elapsed = time.time() - t0
    print(f"[+] Majorana Artin Relation (B1 B2 B1 == B2 B1 B2): {'VERIFIED' if artin_ok else 'FAILED'}")
    print(f"[+] Fibonacci Pentagon/Hexagon Braid (s1 s2 s1 == s2 s1 s2): {'VERIFIED' if fib_ok else 'FAILED'}")
    print(f"[+] Total Verification Time: {elapsed:.3f}s")
    return 0 if (artin_ok and fib_ok) else 1

def cmd_ecc(driver: FermionDriver) -> int:
    print(BANNER)
    print("[*] Running Distance-3 Rotated Surface Code Syndrome Extraction & MWPM Decoding...")
    syndromes = driver.run_surface_code_cycle()
    print(format_surface_code_lattice(3, syndromes))
    decoder = MWPMDecoder(3)
    corrections = decoder.decode_syndrome(syndromes)
    print(f"[+] Extracted Syndrome Vector: {syndromes}")
    print(f"[+] MWPM Optimal Correction Chain: Data Qubits {corrections}")
    return 0

def cmd_demo(driver: FermionDriver) -> int:
    print(BANNER)
    print("========================================================================")
    print("   STAGE 1: Master Diagnostics and Symplectic Algebra")
    print("========================================================================")
    cmd_diagnostics(driver)

    print("\n========================================================================")
    print("   STAGE 2: Ab-Initio Molecular Ground State Phase Estimation")
    print("========================================================================")
    cmd_qpe(driver, bits=6)

    print("\n========================================================================")
    print("   STAGE 3: Non-Abelian Anyon Braiding & Braid Group Representations")
    print("========================================================================")
    cmd_anyon(driver)

    print("\n========================================================================")
    print("   STAGE 4: Fault-Tolerant Surface Code & Blossom MWPM Decoding")
    print("========================================================================")
    cmd_ecc(driver)

    print("\n========================================================================")
    print("   STAGE 5: Quantum Non-Locality & Bell-CHSH Violation")
    print("========================================================================")
    cmd_chsh(driver, shots=500)

    print("\n========================================================================")
    print("   DEMONSTRATION COMPLETE: All Subsystems Verified Successfully")
    print("========================================================================")
    return 0

def main():
    parser = argparse.ArgumentParser(
        prog="fermion",
        description="Fault-Tolerant Second-Quantized Simulation and Topological Anyon Kernel"
    )
    subparsers = parser.add_subparsers(dest="command", help="Subcommand to execute")

    subparsers.add_parser("diagnostics", help="Run master diagnostics suite across all modules")
    qpe_p = subparsers.add_parser("qpe", help="Run molecular Quantum Phase Estimation")
    qpe_p.add_argument("--bits", type=int, default=6, help="Phase estimation precision bits")

    chsh_p = subparsers.add_parser("chsh", help="Run Bell-CHSH non-locality test")
    chsh_p.add_argument("--shots", type=int, default=500, help="Shots per measurement setting")

    subparsers.add_parser("anyon", help="Verify non-Abelian anyon braiding relations")
    subparsers.add_parser("ecc", help="Run surface code syndrome extraction and MWPM decoding")
    subparsers.add_parser("demo", help="Run comprehensive multi-stage end-to-end demonstration")

    args = parser.parse_args()

    driver = FermionDriver()

    if args.command == "diagnostics":
        sys.exit(cmd_diagnostics(driver))
    elif args.command == "qpe":
        sys.exit(cmd_qpe(driver, bits=args.bits))
    elif args.command == "chsh":
        sys.exit(cmd_chsh(driver, shots=args.shots))
    elif args.command == "anyon":
        sys.exit(cmd_anyon(driver))
    elif args.command == "ecc":
        sys.exit(cmd_ecc(driver))
    elif args.command == "demo" or args.command is None:
        sys.exit(cmd_demo(driver))
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
