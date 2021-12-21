import json
import os
import sys
import time

# Ensure project root is in sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from typing import Dict, Any
from runtime.driver import FermionDriver
from runtime.decoders.mwpm import MWPMDecoder

def benchmark_trotter_scaling(driver: FermionDriver) -> Dict[str, Any]:
    """Measures execution latency for 1st, 2nd, and 4th order Trotter steps."""
    orders = [1, 2, 4]
    step_counts = [2, 4, 8, 16]
    results = {}

    for order in orders:
        order_key = f"order_{order}"
        results[order_key] = {}
        for steps in step_counts:
            code = f"""
            operation BenchTrotter() : Unit {{
                use q = Qubit[2];
                let h = [
                    Fermion.Core.CreatePauliWord(1.0, [PauliX], [0]),
                    Fermion.Core.CreatePauliWord(0.5, [PauliZ, PauliZ], [0, 1])
                ];
                Fermion.Simulation.SimulateHamiltonianEvolution(h, 1.0, {steps}, {order}, q);
                ResetAll(q);
            }}
            BenchTrotter()
            """
            # Warmup
            driver.eval(code)
            # Timed iterations
            n_iter = 50
            t0 = time.perf_counter()
            for _ in range(n_iter):
                driver.eval(code)
            elapsed_us = ((time.perf_counter() - t0) / n_iter) * 1e6
            results[order_key][f"steps_{steps}"] = round(elapsed_us, 2)

    return results

def benchmark_qpe(driver: FermionDriver) -> Dict[str, Any]:
    """Measures molecular H2 QPE time and energy convergence."""
    bits_list = [4, 6, 8]
    results = {}
    for bits in bits_list:
        t0 = time.perf_counter()
        energy = driver.run_h2_simulation(bits=bits)
        elapsed_ms = (time.perf_counter() - t0) * 1e3
        results[f"bits_{bits}"] = {
            "energy_hartree": round(energy, 6),
            "latency_ms": round(elapsed_ms, 2),
        }
    return results

def benchmark_mwpm(distance: int = 3) -> Dict[str, Any]:
    """Measures Blossom MWPM decoding throughput on surface code syndromes."""
    decoder = MWPMDecoder(distance)
    syndromes = [
        [False] * 8,
        [True, False, False, False, False, False, False, False],
        [True, False, True, False, False, False, False, False],
        [True, False, True, False, True, False, True, False],
    ]
    results = {}
    for idx, syn in enumerate(syndromes):
        n_defects = sum(syn)
        n_iter = 200
        t0 = time.perf_counter()
        for _ in range(n_iter):
            decoder.decode_syndrome(syn)
        elapsed_us = ((time.perf_counter() - t0) / n_iter) * 1e6
        throughput_ops = int(1e6 / elapsed_us) if elapsed_us > 0 else 0
        results[f"defects_{n_defects}"] = {
            "latency_us": round(elapsed_us, 2),
            "throughput_decodes_per_sec": throughput_ops,
        }
    return results

def main():
    print("========================================================================")
    print("   FERMION BENCHMARK HARNESS: Scalability and Quantum Latency Profiling")
    print("========================================================================")

    driver = FermionDriver()

    print("[*] Benchmarking Trotter-Suzuki product formulas (latency per step in microseconds)...")
    trotter_res = benchmark_trotter_scaling(driver)
    print("    Order 1 (Lie-Trotter):   ", trotter_res["order_1"])
    print("    Order 2 (Strang-Marchuk):", trotter_res["order_2"])
    print("    Order 4 (Suzuki Fractal):", trotter_res["order_4"])

    print("\n[*] Benchmarking Quantum Phase Estimation (H2 molecule)...")
    qpe_res = benchmark_qpe(driver)
    for k, v in qpe_res.items():
        print(f"    {k}: {v}")

    print("\n[*] Benchmarking Blossom MWPM Syndrome Decoding...")
    mwpm_res = benchmark_mwpm(3)
    for k, v in mwpm_res.items():
        print(f"    {k}: {v}")

    all_results = {
        "trotter_scaling": trotter_res,
        "qpe_convergence": qpe_res,
        "mwpm_decoding": mwpm_res,
    }

    out_path = os.path.join(os.path.dirname(__file__), "results.json")
    with open(out_path, "w") as f:
        json.dump(all_results, f, indent=2)

    print(f"\n[+] Benchmark metrics saved to: {out_path}")
    print("========================================================================")

if __name__ == "__main__":
    main()
