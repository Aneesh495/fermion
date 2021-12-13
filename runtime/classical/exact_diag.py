import numpy as np
import scipy.linalg as la
from typing import List, Tuple

# Single-qubit Pauli matrices
I_MAT = np.eye(2, dtype=complex)
X_MAT = np.array([[0, 1], [1, 0]], dtype=complex)
Y_MAT = np.array([[0, -1j], [1j, 0]], dtype=complex)
Z_MAT = np.array([[1, 0], [0, -1]], dtype=complex)

PAULI_DICT = {
    "PauliI": I_MAT,
    "PauliX": X_MAT,
    "PauliY": Y_MAT,
    "PauliZ": Z_MAT,
}

class ExactDiagonalizationSolver:
    """
    Classical Full Configuration Interaction (FCI) Exact Diagonalization Solver.
    Constructs the dense matrix representation of arbitrary multi-qubit
    Hamiltonians and solves the eigensystem via Hermitian diagonalization.
    """

    def __init__(self, num_qubits: int):
        self.num_qubits = num_qubits
        self.dim = 1 << num_qubits

    def build_pauli_matrix(self, ops: List[str], qubits: List[int]) -> np.ndarray:
        """Kronecker product of Pauli operators over n qubits."""
        full_ops = [I_MAT] * self.num_qubits
        for op_name, q in zip(ops, qubits):
            full_ops[q] = PAULI_DICT.get(op_name, I_MAT)

        mat = full_ops[0]
        for idx in range(1, self.num_qubits):
            mat = np.kron(mat, full_ops[idx])
        return mat

    def build_hamiltonian_matrix(self, terms: List[Tuple[float, List[str], List[int]]]) -> np.ndarray:
        """Assembles total Hamiltonian matrix from Pauli term tuples: (coeff, ops, qubits)."""
        h_mat = np.zeros((self.dim, self.dim), dtype=complex)
        for coeff, ops, qubits in terms:
            term_mat = self.build_pauli_matrix(ops, qubits)
            h_mat += coeff * term_mat
        return h_mat

    def solve_ground_state(self, h_mat: np.ndarray) -> Tuple[float, np.ndarray]:
        """Diagonalizes the Hamiltonian and returns the ground state energy and state vector."""
        eigenvalues, eigenvectors = la.eigh(h_mat)
        return float(eigenvalues[0]), eigenvectors[:, 0]

    def solve_full_spectrum(self, h_mat: np.ndarray) -> np.ndarray:
        """Returns all sorted eigenvalues."""
        eigenvalues = la.eigvalsh(h_mat)
        return np.sort(eigenvalues)
