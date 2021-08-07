namespace Fermion.Core {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;

    // Phase convention for Pauli operators:
    // PhaseZero = +1, PhaseOne = +i, PhaseTwo = -1, PhaseThree = -i
    struct PauliWord {
        Coeff : Double,
        Phase : Int,
        Ops : Pauli[],
        Qubits : Int[]
    }

    // Binary symplectic vector (x | z) in F_2^(2n) with phase indicator in Z_4
    struct SymplecticVector {
        NumQubits : Int,
        XBits : Bool[],
        ZBits : Bool[],
        Phase : Int
    }

    // Clifford stabilizer tableau for n qubits (2n generators of length 2n + 1)
    struct CliffordTableau {
        NumQubits : Int,
        Rows : SymplecticVector[]
    }

    // Fermionic spin-orbital descriptor
    struct FermionicOrbital {
        Index : Int,
        SpatialIndex : Int,
        Spin : Int, // 0 for alpha (up), 1 for beta (down)
        Energy : Double
    }

    // Second-quantized ladder operator: True for creation (a^\dagger), False for annihilation (a)
    struct LadderOp {
        Orbital : Int,
        IsCreation : Bool
    }

    // Fermionic product term: c * prod_k a_k^(dagger)
    struct FermionTerm {
        CoeffReal : Double,
        CoeffImag : Double,
        Ops : LadderOp[]
    }

    // Molecular electronic Hamiltonian representation
    struct MolecularHamiltonian {
        NumOrbitals : Int,
        NuclearRepulsion : Double,
        Terms : PauliWord[]
    }

    // Topological Majorana mode definition on a 1D superconducting wire
    struct MajoranaMode {
        Index : Int,
        WireIndex : Int,
        IsLeftBoundary : Bool
    }

    // Fibonacci anyon descriptor with topological charge
    // Charge 0 represents vacuum (1), Charge 1 represents tau anyon
    struct AnyonSite {
        Index : Int,
        Charge : Int,
        CoordinateX : Double,
        CoordinateY : Double
    }

    // Quantum error correction stabilizer generator descriptor
    struct StabilizerCheck {
        CheckType : Pauli, // PauliX for star check, PauliZ for plaquette check
        Weight : Int,
        Support : Int[],
        AncillaIndex : Int
    }

    // Planar rotated surface code patch definition
    struct SurfaceCodePatch {
        Distance : Int,
        DataQubits : Int[],
        XSyndromeQubits : Int[],
        ZSyndromeQubits : Int[],
        NumPhysicalQubits : Int
    }

    // Expectation value measurement record for state/process characterization
    struct PauliMeasurementRecord {
        Basis : Pauli[],
        Qubits : Int[],
        Expectation : Double,
        Variance : Double,
        Shots : Int
    }

    // Constructor functions for core data types

    function CreatePauliWord(coeff : Double, ops : Pauli[], qubits : Int[]) : PauliWord {
        return PauliWord(coeff, 0, ops, qubits);
    }

    function CreateSymplecticVector(n : Int) : SymplecticVector {
        mutable x = [false, size = n];
        mutable z = [false, size = n];
        return SymplecticVector(n, x, z, 0);
    }

    function IdentityPauliWord(n : Int) : PauliWord {
        mutable ops = [PauliI, size = n];
        mutable q = [0, size = n];
        for idx in 0..n - 1 {
            set q w/= idx <- idx;
        }
        return PauliWord(1.0, 0, ops, q);
    }

    function SymplecticInnerProduct(v1 : SymplecticVector, v2 : SymplecticVector) : Int {
        if (v1.NumQubits != v2.NumQubits) {
            return 0;
        }
        mutable prod = 0;
        for i in 0..v1.NumQubits - 1 {
            let x1 = v1.XBits[i] ? 1 | 0;
            let z1 = v1.ZBits[i] ? 1 | 0;
            let x2 = v2.XBits[i] ? 1 | 0;
            let z2 = v2.ZBits[i] ? 1 | 0;
            set prod = (prod + (x1 * z2 + z1 * x2)) % 2;
        }
        return prod;
    }

    function ArePauliWordsCommuting(w1 : PauliWord, w2 : PauliWord, n : Int) : Bool {
        mutable x1 = [false, size = n];
        mutable z1 = [false, size = n];
        for idx in 0..Length(w1.Qubits) - 1 {
            let q = w1.Qubits[idx];
            let op = w1.Ops[idx];
            if (op == PauliX) { set x1 w/= q <- true; }
            elif (op == PauliZ) { set z1 w/= q <- true; }
            elif (op == PauliY) { set x1 w/= q <- true; set z1 w/= q <- true; }
        }

        mutable x2 = [false, size = n];
        mutable z2 = [false, size = n];
        for idx in 0..Length(w2.Qubits) - 1 {
            let q = w2.Qubits[idx];
            let op = w2.Ops[idx];
            if (op == PauliX) { set x2 w/= q <- true; }
            elif (op == PauliZ) { set z2 w/= q <- true; }
            elif (op == PauliY) { set x2 w/= q <- true; set z2 w/= q <- true; }
        }

        mutable anticommuteCount = 0;
        for i in 0..n - 1 {
            let term = ((x1[i] ? 1 | 0) * (z2[i] ? 1 | 0) + (z1[i] ? 1 | 0) * (x2[i] ? 1 | 0)) % 2;
            set anticommuteCount = (anticommuteCount + term) % 2;
        }
        return anticommuteCount == 0;
    }
}
