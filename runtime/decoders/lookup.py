from typing import Dict, List, Optional, Tuple

class LookupTableDecoder:
    """
    Precomputed Syndrome Lookup Table Decoder for Small Codes (Steane, d=3 Surface).
    Provides instant O(1) error location extraction.
    """

    def __init__(self):
        # Steane syndrome table: 3-bit syndrome -> error qubit
        self.steane_syndromes: Dict[Tuple[bool, bool, bool], int] = {
            (False, False, False): -1,
            (True, False, False): 0,
            (False, True, False): 4,
            (True, True, False): 1,
            (False, False, True): 6,
            (True, False, True): 3,
            (False, True, True): 5,
            (True, True, True): 2,
        }

    def decode_steane_syndrome(self, s0: bool, s1: bool, s2: bool) -> int:
        return self.steane_syndromes.get((s0, s1, s2), -1)
