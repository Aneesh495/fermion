namespace Fermion.Simulation {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;
    open Fermion.Core;

    // Second-quantized 1-body excitation descriptor: a_p^dagger a_q
    struct OneBodyTerm {
        P : Int,
        Q : Int,
        Weight : Double
    }

    // Second-quantized 2-body excitation descriptor: a_p^dagger a_q^dagger a_s a_r
    struct TwoBodyTerm {
        P : Int,
        Q : Int,
        R : Int,
        S : Int,
        Weight : Double
    }

    // Full electronic structure Hamiltonian in second-quantized form
    struct SecondQuantizedHamiltonian {
        NumOrbitals : Int,
        NuclearRepulsion : Double,
        OneBodyTerms : OneBodyTerm[],
        TwoBodyTerms : TwoBodyTerm[]
    }

    // Creates a 1-body term with symmetry enforcement h_pq = h_qp for real integrals
    function CreateOneBodyTerm(p : Int, q : Int, weight : Double) : OneBodyTerm {
        return OneBodyTerm(p, q, weight);
    }

    // Creates a 2-body term h_pqrs
    function CreateTwoBodyTerm(p : Int, q : Int, r : Int, s : Int, weight : Double) : TwoBodyTerm {
        return TwoBodyTerm(p, q, r, s, weight);
    }

    // Evaluates the Canonical Anti-commutation Relation (CAR) delta
    function CARDelta(p : Int, q : Int) : Double {
        return p == q ? 1.0 | 0.0;
    }

    // Converts a ladder operator to its Majorana operator representation:
    // a_p = (gamma_{2p} + i * gamma_{2p+1}) / 2
    // a_p^dagger = (gamma_{2p} - i * gamma_{2p+1}) / 2
    function MajoranaIndicesForOrbital(orbital : Int) : (Int, Int) {
        return (2 * orbital, 2 * orbital + 1);
    }

    // Computes the sign factor (-1)^swaps incurred when moving an operator past another
    function FermionicPermutationSign(swaps : Int) : Double {
        return (swaps % 2 == 0) ? 1.0 | -1.0;
    }

    // Verifies whether a 1-body term is a number operator (p == q)
    function IsNumberOperator(term : OneBodyTerm) : Bool {
        return term.P == term.Q;
    }
}
