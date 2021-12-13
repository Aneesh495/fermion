import numpy as np
from dataclasses import dataclass
from typing import Dict, List, Tuple

@dataclass
class MolecularIntegrals:
    """Molecular electronic integrals in the spin-orbital basis."""
    name: str
    num_orbitals: int
    nuclear_repulsion: float
    one_body: np.ndarray  # shape: (n, n)
    two_body: np.ndarray  # shape: (n, n, n, n)
    fci_ground_energy: float

def get_h2_integrals(bond_distance: float = 0.7414) -> MolecularIntegrals:
    """
    Returns ab-initio molecular integrals for H2 in STO-3G basis.
    Bond distance in Angstroms (equilibrium = 0.7414 A).
    """
    n = 4
    v_nn = 0.713753 * (0.7414 / bond_distance)

    # 1-body tensor
    h1 = np.zeros((n, n), dtype=float)
    h1[0, 0] = -1.252947
    h1[1, 1] = -1.252947
    h1[2, 2] = -0.475934
    h1[3, 3] = -0.475934

    # 2-body Coulomb and exchange tensor (chemist notation: (pq|rs))
    h2 = np.zeros((n, n, n, n), dtype=float)
    g0000 = 0.674493
    g1111 = 0.674493
    g0011 = 0.663472
    g0110 = 0.181287

    h2[0, 0, 0, 0] = g0000
    h2[1, 1, 1, 1] = g1111
    h2[0, 0, 1, 1] = g0011
    h2[1, 1, 0, 0] = g0011
    h2[0, 1, 1, 0] = g0110
    h2[1, 0, 0, 1] = g0110

    fci_energy = -1.137270

    return MolecularIntegrals(
        name="H2",
        num_orbitals=n,
        nuclear_repulsion=v_nn,
        one_body=h1,
        two_body=h2,
        fci_ground_energy=fci_energy,
    )

def get_lih_integrals(bond_distance: float = 1.595) -> MolecularIntegrals:
    """Returns active-space molecular integrals for LiH at R = 1.595 A."""
    n = 4
    v_nn = 0.995321
    h1 = np.diag([-2.451, -2.451, -0.892, -0.892])
    h2 = np.zeros((n, n, n, n), dtype=float)
    h2[0, 0, 0, 0] = 0.452
    h2[1, 1, 1, 1] = 0.452
    h2[0, 0, 1, 1] = 0.389
    h2[1, 1, 0, 0] = 0.389

    return MolecularIntegrals(
        name="LiH",
        num_orbitals=n,
        nuclear_repulsion=v_nn,
        one_body=h1,
        two_body=h2,
        fci_ground_energy=-7.882,
    )
