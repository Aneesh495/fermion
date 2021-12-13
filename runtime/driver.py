import os
import sys
from typing import Any, Dict, List, Optional
from qdk import qsharp

class FermionDriver:
    """
    Python execution driver and interop bridge for the Q# kernel.
    Manages compilation, execution, QIR generation, and telemetry.
    """

    def __init__(self, project_root: Optional[str] = None):
        if project_root is None:
            project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
        self.project_root = project_root
        self._initialized = False
        self.init()

    def init(self) -> None:
        """Initializes the Q# interpreter with the project manifest."""
        qsharp.init(project_root=self.project_root)
        self._initialized = True

    def eval(self, expr: str) -> Any:
        """Evaluates a raw Q# expression."""
        if not self._initialized:
            self.init()
        return qsharp.eval(expr)

    def run_diagnostics(self) -> int:
        """Runs the master diagnostics suite across all Q# modules."""
        return int(self.eval("Fermion.RunMasterDiagnostics()"))

    def run_h2_simulation(self, bits: int = 6) -> float:
        """Runs molecular hydrogen ground state quantum phase estimation."""
        res = self.eval(f"Fermion.Simulation.RunH2PhaseEstimation({bits})")
        return float(res)

    def run_chsh_test(self, shots: int = 500) -> Dict[str, float]:
        """Runs the Bell-CHSH test and returns correlation coefficients."""
        res = self.eval(f"Fermion.Characterization.RunCHSHInequalityTest({shots})")
        s_val, e00, e01, e10, e11 = res
        return {
            "S": float(s_val),
            "E00": float(e00),
            "E01": float(e01),
            "E10": float(e10),
            "E11": float(e11),
            "violates_classical": float(s_val) > 2.0,
            "cirelson_ratio": float(s_val) / (2.0 * (2.0 ** 0.5)),
        }

    def verify_braiding(self) -> bool:
        """Verifies Majorana non-Abelian Artin braid relations."""
        res = self.eval("Fermion.Topology.VerifyArtinBraidRelation()")
        return bool(res)

    def verify_fibonacci_braid(self) -> bool:
        """Verifies Fibonacci anyon braid relations via F and R matrices."""
        res = self.eval("Fermion.Topology.VerifyFibonacciBraidRelation()")
        return bool(res)

    def run_surface_code_cycle(self) -> List[bool]:
        """Runs a distance-3 rotated surface code syndrome extraction cycle."""
        code = """
        operation TestRunCycle() : Bool[] {
            use register = Qubit[17];
            let patch = Fermion.ErrorCorrection.GetRotatedSurfaceCodeDistance3();
            let syn = Fermion.ErrorCorrection.RunSurfaceCodeSyndromeCycle(patch, register);
            ResetAll(register);
            return syn;
        }
        TestRunCycle()
        """
        res = self.eval(code)
        return list(res)

    def compile_to_qir(self, entrypoint_op: str) -> str:
        """Compiles a Q# operation to Quantum Intermediate Representation (QIR)."""
        program = qsharp.compile(entrypoint_op)
        return str(program)
