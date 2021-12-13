import networkx as nx
from typing import Dict, List, Set, Tuple

class MWPMDecoder:
    """
    Minimum-Weight Perfect Matching (MWPM) Decoder for Surface Codes.
    Constructs defect graphs and solves for the optimal error recovery
    chains using Edmond's Blossom algorithm.
    """

    def __init__(self, distance: int = 3):
        self.distance = distance
        self.num_data = distance * distance
        # Coordinates for 3x3 data qubits
        self.data_coords = {
            idx: (idx % distance, idx // distance)
            for idx in range(self.num_data)
        }
        # Check locations for distance 3 surface code:
        # X-checks (stars)
        self.x_checks = {
            0: [(0, 1)],
            1: [(1, 2), (4, 5)],
            2: [(3, 4), (6, 7)],
            3: [(7, 8)],
        }
        # Z-checks (plaquettes)
        self.z_checks = {
            0: [(0, 3)],
            1: [(1, 4), (2, 5)],
            2: [(3, 6), (4, 7)],
            3: [(5, 8)],
        }

    def decode_syndrome(self, syndrome: List[bool], check_type: str = "X") -> List[int]:
        """
        Given a list of syndrome bits, identifies defect nodes, builds
        the complete bipartite distance graph, and returns the list of
        data qubit indices that require Pauli correction.
        """
        defect_nodes = [i for i, bit in enumerate(syndrome) if bit]
        if not defect_nodes:
            return []

        # If odd number of defects, match to nearest virtual boundary node
        g = nx.Graph()
        n_defects = len(defect_nodes)

        for i in range(n_defects):
            for j in range(i + 1, n_defects):
                u = defect_nodes[i]
                v = defect_nodes[j]
                dist = abs(u - v) + 1
                g.add_edge(f"d_{u}", f"d_{v}", weight=dist)

        # Boundary virtual nodes
        for i, u in enumerate(defect_nodes):
            b_dist = 1  # distance to code boundary
            g.add_edge(f"d_{u}", f"b_{u}", weight=b_dist)

        for i in range(n_defects):
            for j in range(i + 1, n_defects):
                u = defect_nodes[i]
                v = defect_nodes[j]
                g.add_edge(f"b_{u}", f"b_{v}", weight=0)

        # Compute minimum weight perfect matching via Blossom algorithm
        matching = nx.algorithms.matching.min_weight_matching(g, weight="weight")

        corrected_qubits: List[int] = []
        for u_str, v_str in matching:
            if u_str.startswith("d_") and v_str.startswith("d_"):
                u = int(u_str.split("_")[1])
                v = int(v_str.split("_")[1])
                # Invert data qubit along the path between defects u and v
                corrected_qubits.append((u + v) % self.num_data)
            elif u_str.startswith("d_") and v_str.startswith("b_"):
                u = int(u_str.split("_")[1])
                corrected_qubits.append(u)
            elif v_str.startswith("d_") and u_str.startswith("b_"):
                v = int(v_str.split("_")[1])
                corrected_qubits.append(v)

        return sorted(list(set(corrected_qubits)))
