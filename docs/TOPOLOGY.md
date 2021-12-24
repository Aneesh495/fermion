# Topological Quantum Computing & Anyonic Braiding

This document details the topological quantum mechanics, Majorana zero mode operator algebras, non-Abelian braiding representations, and Fibonacci anyon models implemented in `fermion`.

---

## 1. Majorana Zero Modes in 1D Superconductors

Majorana fermions are self-conjugate fermionic quasiparticles satisfying:

$$\gamma_j^\dagger = \gamma_j, \quad \{\gamma_j, \gamma_k\} = 2 \delta_{jk} I$$

In a 1D Kitaev wire with $N$ lattice sites, $2N$ Majorana operators describe the physical system:

$$\gamma_{2j-1} = c_j + c_j^\dagger, \quad \gamma_{2j} = -i(c_j - c_j^\dagger)$$

At the topological boundary $|\mu| < 2w$, two unpaired Majorana zero modes (MZMs) $\gamma_1$ and $\gamma_{2N}$ localize at the wire ends with spatial wavefunctions decaying exponentially into the bulk:

$$\psi(x) \sim e^{-x / \xi}$$

where $\xi = \hbar v_F / \Delta$ is the superconducting coherence length.

These boundary modes form a non-local complex Dirac fermion:

$$d = \frac{1}{2} (\gamma_1 + i \gamma_{2N})$$

The fermion parity operator $P = i \gamma_1 \gamma_{2N} = 2 d^\dagger d - 1$ defines a degenerate two-level system. Because the state is stored non-locally across the ends of the macroscopic wire, any local perturbation $V = \sum_j v_j c_j^\dagger c_j$ has matrix elements between $|0\rangle$ and $|1\rangle$ suppressed exponentially:

$$|\langle 0 | V | 1 \rangle| \le C e^{-L / \xi}$$

This provides hardware-level topological protection against environmental dephasing.

---

## 2. Non-Abelian Braiding Dynamics

When two Majorana zero modes $\gamma_i$ and $\gamma_j$ are exchanged adiabatically in a two-dimensional network (such as a T-junction), the quantum state undergoes a unitary transformation:

$$B_{ij} = \exp\left( \frac{\pi}{4} \gamma_i \gamma_j \right) = \frac{1}{\sqrt{2}} (1 + \gamma_i \gamma_j)$$

Under clockwise exchange:

$$\gamma_i \mapsto B_{ij}^\dagger \gamma_i B_{ij} = \gamma_j$$

$$\gamma_j \mapsto B_{ij}^\dagger \gamma_j B_{ij} = -\gamma_i$$

Because $B_{12}$ and $B_{23}$ do not commute ($[B_{12}, B_{23}] \ne 0$), Majorana zero modes obey non-Abelian exchange statistics. They realize a projective representation of the Artin Braid Group $B_n$, satisfying:

$$B_i B_{i+1} B_i = B_{i+1} B_i B_{i+1}$$

$$B_i B_j = B_j B_i \quad \text{for } |i - j| \ge 2$$

---

## 3. Universal Topological Quantum Computing: Fibonacci Anyons

Majorana braiding alone is not universal: it generates the Clifford group, which can be efficiently simulated classically by the Gottesman-Knill theorem.

To achieve universal topological quantum computation without physical error distillation, `fermion` implements the Fibonacci Anyon model:

### 3.1. Quantum Dimensions & Fusion Rules

Fibonacci anyons have two superselection sectors: the vacuum $\mathbf{1}$ and the non-Abelian anyon $\tau$.

$$\mathbf{1} \times \mathbf{1} = \mathbf{1}, \quad \mathbf{1} \times \tau = \tau, \quad \tau \times \tau = \mathbf{1} + \tau$$

The quantum dimension of $\tau$ is the golden ratio $\phi = (1 + \sqrt{5})/2 \approx 1.6180339887$.

### 3.2. Pentagon and Hexagon Equations

Associativity between fusion trees is mediated by the topological $F$-matrix:

$$F_{\tau}^{\tau\tau\tau} = \begin{pmatrix} \phi^{-1} & \phi^{-1/2} \\ \phi^{-1/2} & -\phi^{-1} \end{pmatrix}$$

Braiding of two adjacent anyons is governed by the topological $R$-matrix:

$$R_{\mathbf{1}}^{\tau\tau} = e^{4\pi i / 5}, \quad R_{\tau}^{\tau\tau} = -e^{2\pi i / 5}$$

The braid generators in the 2D fusion space of 3 anyons are:

$$\sigma_1 = R, \quad \sigma_2 = F \sigma_1 F$$

They satisfy the non-Abelian Yang-Baxter braid equation:

$$\sigma_1 \sigma_2 \sigma_1 = \sigma_2 \sigma_1 \sigma_2$$

---

## 4. Solovay-Kitaev Topological Gate Compilation

The braid generators $\sigma_1$ and $\sigma_2$ generate a dense subgroup of $SU(2)$. Arbitrary single-qubit rotations $U \in SU(2)$ can be approximated to precision $\epsilon$ using braid words of length $O(\log^c(1/\epsilon))$.

The Solovay-Kitaev compiler operates recursively:
1. Base net lookup identifies an initial approximation $U_0$ with error $\epsilon_0$.
2. The error matrix $\Delta = U U_k^\dagger$ is decomposed into a group commutator $\Delta \approx V W V^\dagger W^\dagger$.
3. Sub-unitaries $V$ and $W$ are compiled recursively to error $\epsilon_k^{3/2}$.
4. The synthesized braid word converges super-exponentially to the target quantum gate.
