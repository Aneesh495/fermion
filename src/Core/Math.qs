namespace Fermion.Core {
    open Std.Intrinsic;
    open Std.Math;
    open Std.Convert;
    open Std.Arrays;

    // Complex number representation
    struct ComplexNum {
        Real : Double,
        Imag : Double
    }

    // 2x2 Unitary matrix decomposition parameters (ZYZ Euler angles)
    // U = e^(i * GlobalPhase) * Rz(Beta) * Ry(Gamma) * Rz(Delta)
    struct EulerAngles {
        GlobalPhase : Double,
        Beta : Double,
        Gamma : Double,
        Delta : Double
    }

    // Rational fraction approximation p / q
    struct RationalFraction {
        Numerator : Int,
        Denominator : Int
    }

    function ComplexZero() : ComplexNum {
        return ComplexNum(0.0, 0.0);
    }

    function ComplexOne() : ComplexNum {
        return ComplexNum(1.0, 0.0);
    }

    function ComplexI() : ComplexNum {
        return ComplexNum(0.0, 1.0);
    }

    function ComplexAdd(a : ComplexNum, b : ComplexNum) : ComplexNum {
        return ComplexNum(a.Real + b.Real, a.Imag + b.Imag);
    }

    function ComplexSub(a : ComplexNum, b : ComplexNum) : ComplexNum {
        return ComplexNum(a.Real - b.Real, a.Imag - b.Imag);
    }

    function ComplexMul(a : ComplexNum, b : ComplexNum) : ComplexNum {
        return ComplexNum(
            a.Real * b.Real - a.Imag * b.Imag,
            a.Real * b.Imag + a.Imag * b.Real
        );
    }

    function ComplexScale(c : ComplexNum, s : Double) : ComplexNum {
        return ComplexNum(c.Real * s, c.Imag * s);
    }

    function ComplexConj(c : ComplexNum) : ComplexNum {
        return ComplexNum(c.Real, -c.Imag);
    }

    function ComplexNormSq(c : ComplexNum) : Double {
        return c.Real * c.Real + c.Imag * c.Imag;
    }

    function ComplexModulus(c : ComplexNum) : Double {
        return Sqrt(ComplexNormSq(c));
    }

    function ComplexPhase(c : ComplexNum) : Double {
        return ArcTan2(c.Imag, c.Real);
    }

    // Clenshaw recurrence for evaluating Chebyshev polynomial expansions:
    // P(x) = c_0/2 + sum_{k=1}^N c_k T_k(x)
    function EvaluateChebyshev(coeffs : Double[], x : Double) : Double {
        let n = Length(coeffs);
        if (n == 0) {
            return 0.0;
        }
        if (n == 1) {
            return coeffs[0] * 0.5;
        }

        mutable b_next = 0.0;
        mutable b_curr = 0.0;
        mutable b_prev = 0.0;

        for k in n - 1..-1..1 {
            set b_prev = b_curr;
            set b_curr = 2.0 * x * b_curr - b_next + coeffs[k];
            set b_next = b_prev;
        }

        return coeffs[0] * 0.5 + x * b_curr - b_next;
    }

    // Direct computation of Chebyshev polynomial T_k(x)
    function ChebyshevT(k : Int, x : Double) : Double {
        if (k == 0) {
            return 1.0;
        }
        if (k == 1) {
            return x;
        }
        mutable t_prev = 1.0;
        mutable t_curr = x;
        for _ in 2..k {
            let t_next = 2.0 * x * t_curr - t_prev;
            set t_prev = t_curr;
            set t_curr = t_next;
        }
        return t_curr;
    }

    // Continued fraction expansion to compute rational convergents p_k / q_k
    // Used in quantum phase estimation to extract the exact eigenphase
    function ContinuedFractionConvergent(phase : Double, maxDenominator : Int) : RationalFraction {
        mutable p0 = 0;
        mutable q0 = 1;
        mutable p1 = 1;
        mutable q1 = 0;

        mutable rem = phase;
        mutable p2 = 0;
        mutable q2 = 0;

        for _ in 0..20 {
            let a = Floor(rem);
            let aInt = a;

            set p2 = aInt * p1 + p0;
            set q2 = aInt * q1 + q0;

            if (q2 > maxDenominator) {
                return RationalFraction(p1, q1);
            }

            let diff = rem - IntAsDouble(aInt);
            if (AbsD(diff) < 1.0e-12) {
                return RationalFraction(p2, q2);
            }

            set rem = 1.0 / diff;
            set p0 = p1;
            set q0 = q1;
            set p1 = p2;
            set q1 = q2;
        }

        return RationalFraction(p2, q2);
    }

    // Hamming weight (number of set bits in an integer)
    function HammingWeight(val : Int) : Int {
        mutable count = 0;
        mutable v = val;
        for _ in 0..62 {
            if ((v &&& 1) == 1) {
                set count += 1;
            }
            set v = v >>> 1;
            if (v == 0) {
                return count;
            }
        }
        return count;
    }

    // Parity of an integer (0 for even number of 1s, 1 for odd)
    function IntegerParity(val : Int) : Int {
        return HammingWeight(val) % 2;
    }

    // Binary reflected Gray code of an integer
    function GrayCode(n : Int) : Int {
        return n ^^^ (n >>> 1);
    }

    // Decomposes a general single-qubit unitary U into ZYZ Euler rotation angles
    // U = [[u00, u01], [u10, u11]]
    function DecomposeZYZ(u00 : ComplexNum, u01 : ComplexNum, u10 : ComplexNum, u11 : ComplexNum) : EulerAngles {
        let absU00 = ComplexModulus(u00);
        let gamma = 2.0 * ArcTan2(ComplexModulus(u10), absU00);

        let phase00 = ComplexPhase(u00);
        let phase10 = ComplexPhase(u10);
        let phase01 = ComplexPhase(u01);
        let phase11 = ComplexPhase(u11);

        let alpha = 0.5 * (phase00 + phase11);
        let beta = phase00 - phase10;
        let delta = phase00 - phase01;

        return EulerAngles(alpha, beta, gamma, delta);
    }

    // Givens rotation angle between two real components: theta such that
    // [ cos(theta) -sin(theta) ] [ a ] = [ sqrt(a^2 + b^2) ]
    // [ sin(theta)  cos(theta) ] [ b ]   [       0        ]
    function GivensAngle(a : Double, b : Double) : Double {
        if (AbsD(b) < 1.0e-14) {
            return 0.0;
        }
        return ArcTan2(-b, a);
    }
}
