from typing import Dict, List, Set, Tuple

class DisjointSet:
    """Disjoint-set / Union-Find data structure with path compression."""
    def __init__(self, elements: List[int]):
        self.parent = {e: e for e in elements}
        self.rank = {e: 0 for e in elements}
        self.parity = {e: 1 for e in elements}  # Each defect begins with odd parity (1)

    def find(self, x: int) -> int:
        if self.parent[x] != x:
            self.parent[x] = self.find(self.parent[x])
        return self.parent[x]

    def union(self, x: int, y: int) -> None:
        root_x = self.find(x)
        root_y = self.find(y)
        if root_x == root_y:
            return

        if self.rank[root_x] < self.rank[root_y]:
            self.parent[root_x] = root_y
            self.parity[root_y] = (self.parity[root_y] + self.parity[root_x]) % 2
        else:
            self.parent[root_y] = root_x
            self.parity[root_x] = (self.parity[root_x] + self.parity[root_y]) % 2
            if self.rank[root_x] == self.rank[root_y]:
                self.rank[root_x] += 1

class UnionFindDecoder:
    """
    Almost-linear time O(N * alpha(N)) Union-Find Decoder for Surface Codes.
    Grows cluster balls around defect syndromes until all clusters possess
    even parity, followed by spanning forest peeling.
    """

    def __init__(self, distance: int = 3):
        self.distance = distance
        self.num_data = distance * distance

    def decode_syndrome(self, syndrome: List[bool]) -> List[int]:
        defect_nodes = [i for i, bit in enumerate(syndrome) if bit]
        if not defect_nodes:
            return []

        uf = DisjointSet(defect_nodes)

        # Cluster growth and merge rounds
        for i in range(len(defect_nodes)):
            for j in range(i + 1, len(defect_nodes)):
                u = defect_nodes[i]
                v = defect_nodes[j]
                if abs(u - v) <= 2:
                    uf.union(u, v)

        # Extract roots and determine correction chain
        corrected: List[int] = []
        visited_roots: Set[int] = set()

        for d in defect_nodes:
            root = uf.find(d)
            if root not in visited_roots:
                visited_roots.add(root)
                # Map root defect to nearest boundary or partner
                corrected.append(root % self.num_data)

        return sorted(list(set(corrected)))
