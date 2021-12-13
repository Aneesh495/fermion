from typing import List, Tuple

def format_ascii_circuit(num_qubits: int, gates: List[Tuple[str, List[int]]]) -> str:
    """
    Renders an ASCII circuit diagram in the terminal.
    gates: list of tuples (gate_name, [qubit_indices])
    """
    lines = [f"q_{idx}: " for idx in range(num_qubits)]

    for gate_name, targets in gates:
        col_width = max(len(gate_name) + 2, 5)
        if len(targets) == 1:
            t = targets[0]
            for q in range(num_qubits):
                if q == t:
                    lines[q] += f"-[{gate_name}]-"
                else:
                    lines[q] += "-" * (len(gate_name) + 4)
        elif len(targets) == 2:
            c, t = targets[0], targets[1]
            low, high = min(c, t), max(c, t)
            for q in range(num_qubits):
                if q == c:
                    lines[q] += "--*--"
                elif q == t:
                    lines[q] += f"-({gate_name[0] if gate_name != 'CNOT' else 'X'})-"
                elif low < q < high:
                    lines[q] += "--|--"
                else:
                    lines[q] += "-----"

    for q in range(num_qubits):
        lines[q] += "-[ M ]->"

    return "\n".join(lines)
