from typing import List, Optional

def format_surface_code_lattice(distance: int = 3, syndromes: Optional[List[bool]] = None) -> str:
    """
    Renders an ASCII/Unicode representation of a rotated surface code patch,
    displaying data qubits (D), X-stabilizers (X), and Z-stabilizers (Z),
    with detected syndrome defects highlighted.
    """
    if syndromes is None:
        syndromes = [False] * 8

    # Syndrome indicators: '*' for active syndrome violation, '.' for trivial
    s_sym = ["[*]" if bit else "[ ]" for bit in syndromes]

    diagram = f"""
    Rotated Surface Code (Distance d = {distance})
    +===========================================+
    |                                           |
    |          (D0)-------{s_sym[0]}X0-------(D1)          |
    |            |                         |            |
    |          {s_sym[4]}Z0      (D3)----{s_sym[1]}X1----(D4)     |
    |            |        |                |            |
    |          (D2)-------+              {s_sym[5]}Z1          |
    |            |                         |            |
    |          {s_sym[2]}X2----(D5)              (D7)          |
    |            |        |                |            |
    |          (D6)-------+-------{s_sym[6]}Z2-------(D8)          |
    |                     |                             |
    |                   {s_sym[3]}X3                         |
    |                                           |
    +===========================================+
    Active defects: {[i for i, b in enumerate(syndromes) if b]}
    """
    return diagram
