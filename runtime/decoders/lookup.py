from typing import Dict, List, Optional, Tuple

class LookupTableDecoder:
    """
    Precomputed Syndrome Lookup Table Decoder for Small Codes (Steane, d=3 Surface).
    Provides instant O(1) error location extraction.
    """

    def __init__(self):
        # Steane syndrome table: 3-bit syndrome (s0, s1, s2) -> error qubit (0 to 6)
        # val = s0*1 + s1*2 + s2*4; qubit = val - 1
        self.steane_syndromes: Dict[Tuple[bool, bool, bool], int] = {
            (False, False, False): -1,
            (True, False, False): 0,   # val 1 -> qubit 0
            (False, True, False): 1,   # val 2 -> qubit 1
            (True, True, False): 2,    # val 3 -> qubit 2
            (False, False, True): 3,   # val 4 -> qubit 3
            (True, False, True): 4,    # val 5 -> qubit 4
            (False, True, True): 5,    # val 6 -> qubit 5
            (True, True, True): 6,     # val 7 -> qubit 6
        }

    def decode_steane_syndrome(self, s0: bool, s1: bool, s2: bool) -> int:
        return self.steane_syndromes.get((s0, s1, s2), -1)
