namespace Fermion.ErrorCorrection {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;
    open Fermion.Core;

    // Toric code descriptor on an L x L square lattice torus:
    // Total physical qubits = 2 * L^2 (L^2 horizontal edges + L^2 vertical edges)
    // Stores 2 topologically protected logical qubits
    struct ToricCodeLattice {
        L : Int,
        NumPhysicalQubits : Int
    }

    // Edge index mapping on L x L torus:
    // Horizontal edge at site (x, y) has index: 2 * (y * L + x)
    // Vertical edge at site (x, y) has index:   2 * (y * L + x) + 1
    function HorizontalEdgeIndex(x : Int, y : Int, l : Int) : Int {
        let xMod = (x % l + l) % l;
        let yMod = (y % l + l) % l;
        return 2 * (yMod * l + xMod);
    }

    function VerticalEdgeIndex(x : Int, y : Int, l : Int) : Int {
        let xMod = (x % l + l) % l;
        let yMod = (y % l + l) % l;
        return 2 * (yMod * l + xMod) + 1;
    }

    // Returns the 4 edge indices for star stabilizer A_s at vertex (x, y)
    // Star consists of edges touching vertex (x, y):
    // Horizontal edges: (x, y) and (x-1, y)
    // Vertical edges:   (x, y) and (x, y-1)
    function StarStabilizerEdges(x : Int, y : Int, l : Int) : Int[] {
        return [
            HorizontalEdgeIndex(x, y, l),
            HorizontalEdgeIndex(x - 1, y, l),
            VerticalEdgeIndex(x, y, l),
            VerticalEdgeIndex(x, y - 1, l)
        ];
    }

    // Returns the 4 edge indices for plaquette stabilizer B_p at face (x, y)
    // Plaquette consists of boundary edges around face (x, y):
    // Horizontal edges: (x, y) and (x, y+1)
    // Vertical edges:   (x, y) and (x+1, y)
    function PlaquetteStabilizerEdges(x : Int, y : Int, l : Int) : Int[] {
        return [
            HorizontalEdgeIndex(x, y, l),
            HorizontalEdgeIndex(x, y + 1, l),
            VerticalEdgeIndex(x, y, l),
            VerticalEdgeIndex(x + 1, y, l)
        ];
    }

    // Applies logical non-contractible Wilson loop operator W_X^(1):
    // Horizontal loop of Pauli X operators wrapping around the torus along y = 0
    operation ApplyToricLogicalX1(l : Int, register : Qubit[]) : Unit is Adj + Ctl {
        for x in 0..l - 1 {
            let e = HorizontalEdgeIndex(x, 0, l);
            X(register[e]);
        }
    }

    // Applies logical non-contractible Wilson loop operator W_Z^(1):
    // Vertical dual loop of Pauli Z operators wrapping around the torus along x = 0
    operation ApplyToricLogicalZ1(l : Int, register : Qubit[]) : Unit is Adj + Ctl {
        for y in 0..l - 1 {
            let e = VerticalEdgeIndex(0, y, l);
            Z(register[e]);
        }
    }

    // Applies logical non-contractible Wilson loop operator W_X^(2):
    // Vertical loop of Pauli X operators wrapping around the torus along x = 0
    operation ApplyToricLogicalX2(l : Int, register : Qubit[]) : Unit is Adj + Ctl {
        for y in 0..l - 1 {
            let e = VerticalEdgeIndex(0, y, l);
            X(register[e]);
        }
    }

    // Applies logical non-contractible Wilson loop operator W_Z^(2):
    // Horizontal dual loop of Pauli Z operators wrapping around the torus along y = 0
    operation ApplyToricLogicalZ2(l : Int, register : Qubit[]) : Unit is Adj + Ctl {
        for x in 0..l - 1 {
            let e = HorizontalEdgeIndex(x, 0, l);
            Z(register[e]);
        }
    }

    // Measures a star stabilizer check A_s at vertex (x, y)
    operation MeasureStarStabilizer(x : Int, y : Int, l : Int, register : Qubit[], ancilla : Qubit) : Result {
        let edges = StarStabilizerEdges(x, y, l);
        H(ancilla);
        for e in edges {
            CNOT(ancilla, register[e]);
        }
        H(ancilla);
        let res = M(ancilla);
        Reset(ancilla);
        return res;
    }

    // Measures a plaquette stabilizer check B_p at face (x, y)
    operation MeasurePlaquetteStabilizer(x : Int, y : Int, l : Int, register : Qubit[], ancilla : Qubit) : Result {
        let edges = PlaquetteStabilizerEdges(x, y, l);
        H(ancilla);
        for e in edges {
            CZ(ancilla, register[e]);
        }
        H(ancilla);
        let res = M(ancilla);
        Reset(ancilla);
        return res;
    }
}
