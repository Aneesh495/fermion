# Fault-Tolerant Quantum Error Correction & Lattice Surgery

This guide details the quantum error correction (QEC) architecture, syndrome extraction schedules, classical decoders, and lattice surgery protocols implemented in `fermion`.

---

## 1. Topological Surface Codes

The planar rotated surface code of distance $d$ encodes $k = 1$ logical qubit into $n = d^2$ data qubits, protected by $m = d^2 - 1$ stabilizer generators:

- $(d^2 - 1)/2$ $X$-type stabilizers (star checks)
- $(d^2 - 1)/2$ $Z$-type stabilizers (plaquette checks)

The code distance $d$ determines the minimum weight of an undetectable logical Pauli operator:

$$X_L = \bigotimes_{j=0}^{d-1} X_{\text{col}(j)}, \quad Z_L = \bigotimes_{i=0}^{d-1} Z_{\text{row}(i)}$$

The code can correct any arbitrary error of weight up to:

$$t = \left\lfloor \frac{d - 1}{2} \right\rfloor$$

For distance $d = 3$, $t = 1$: any single-qubit arbitrary Pauli error $(X, Y, \text{or } Z)$ is completely identified and eliminated.

---

## 2. Fault-Tolerant Syndrome Measurement Scheduling

A naive syndrome extraction schedule can propagate a single physical fault on an ancilla qubit into a weight-2 correlated error on data qubits parallel to the logical boundary (a hook error), reducing the effective code distance from $d$ to $\lfloor d/2 \rfloor$.

To maintain the full code distance $d$, `fermion` implements the canonical North-West-East-South (NWES) CNOT scheduling:

```
Cycle 1: North CNOT
Cycle 2: West CNOT
Cycle 3: East CNOT
Cycle 4: South CNOT
```

This ensures that single ancilla faults propagate strictly perpendicular to the code boundary, preserving fault tolerance.

---

## 3. Minimum-Weight Perfect Matching (MWPM) Decoding

Syndrome measurements generate defect endpoints in a syndrome graph $G = (V, E)$. When a physical Pauli error chain $\mathcal{C}$ occurs on data qubits, its boundary $\partial \mathcal{C}$ produces non-trivial syndrome bits $s_i = 1$.

The Minimum-Weight Perfect Matching (MWPM) decoder constructs a complete graph whose vertices are the active defect syndromes (plus virtual boundary nodes). Edge weights represent the shortest path distance:

$$w_{uv} = \mathrm{dist}(u, v)$$

Using Edmond's Blossom algorithm, the decoder computes the matching $M^*$ that minimizes the total weight:

$$M^* = \arg\min_{M} \sum_{(u, v) \in M} w_{uv}$$

The correction operator $C = \prod_{(u, v) \in M^*} \text{Path}(u, v)$ returns the code state to the stabilizer code space.

---

## 4. Fault-Tolerant Lattice Surgery

Traditional surface-code architectures implemented two-qubit logical gates by physically moving (braiding) puncture defects around one another. This incurs substantial spatial footprint and latency overhead.

`fermion` implements Lattice Surgery, replacing physical defect braiding with boundary merge and split operations:

### 4.1. Patch Merge Operation

To measure the joint logical operator $Z_L^{(1)} Z_L^{(2)}$ non-destructively:
1. Two adjacent surface code patches are bridged by turning on intermediate boundary stabilizers $M_b = Z_1 Z_2$.
2. Repeated syndrome extraction rounds project the composite system into an eigenstate of the joint parity without measuring individual patch states.

### 4.2. Patch Split Operation

To re-isolate the patches:
1. Boundary stabilizers are deactivated.
2. Interface qubits are measured in the computational basis.
3. The measurement outcomes are classical correction byproducts, restoring two independent logical patches.

Using an auxiliary routing patch, transversal logical CNOT operations are executed fault-tolerantly without physical movement of qubits.

---

## 5. Magic State Distillation Factories

By the Eastin-Knill theorem, no quantum error-correcting code can implement a universal gate set transversally. While surface codes implement Clifford operations ($H, S, CNOT$) with transversal or lattice surgery operations, non-Clifford gates (such as the $T = \text{diag}(1, e^{i\pi/4})$ gate) require magic state distillation.

The 15-to-1 Reed-Muller distillation protocol implemented in `fermion`:
1. Injects 15 raw noisy physical $|T\rangle$ states with error rate $\epsilon$.
2. Encodes them into the [[15, 1, 3]] Reed-Muller code.
3. Measures the 14 stabilizer generators.
4. If all syndromes are $+1$, the output is accepted as a purified logical $|T\rangle$ state with third-order error suppression:

$$\epsilon_{\text{out}} = 35 \epsilon^3 + O(\epsilon^4)$$

For raw injection error $\epsilon = 10^{-3}$, the distilled magic state achieves error rate $\epsilon_{\text{out}} \approx 3.5 \times 10^{-8}$, well below fault-tolerant thresholds for chemical and many-body simulations.
