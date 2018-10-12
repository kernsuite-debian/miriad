C**********************************************************************
c*CCHEX -- Update Cholesky factorisation.
c:LINPACK
c+
      SUBROUTINE CCHEX(R,LDR,P,K,L,Z,LDZ,NZ,C,S,JOB)
      INTEGER LDR,P,K,L,LDZ,NZ,JOB
      COMPLEX R(LDR,1),Z(LDZ,1),S(1)
      REAL C(1)
C
C     CCHEX UPDATES THE CHOLESKY FACTORIZATION
C
C		    A = CTRANS(R)*R
C
C     OF A POSITIVE DEFINITE MATRIX A OF ORDER P UNDER DIAGONAL
C     PERMUTATIONS OF THE FORM
C
C		    TRANS(E)*A*E
C
C     WHERE E IS A PERMUTATION MATRIX.	SPECIFICALLY, GIVEN
C     AN UPPER TRIANGULAR MATRIX R AND A PERMUTATION MATRIX
C     E (WHICH IS SPECIFIED BY K, L, AND JOB), CCHEX DETERMINES
C     A UNITARY MATRIX U SUCH THAT
C
C			    U*R*E = RR,
C
C     WHERE RR IS UPPER TRIANGULAR.  AT THE USERS OPTION, THE
C     TRANSFORMATION U WILL BE MULTIPLIED INTO THE ARRAY Z.
C     IF A = CTRANS(X)*X, SO THAT R IS THE TRIANGULAR PART OF THE
C     QR FACTORIZATION OF X, THEN RR IS THE TRIANGULAR PART OF THE
C     QR FACTORIZATION OF X*E, I.E. X WITH ITS COLUMNS PERMUTED.
C     FOR A LESS TERSE DESCRIPTION OF WHAT CCHEX DOES AND HOW
C     IT MAY BE APPLIED, SEE THE LINPACK GUIDE.
C
C     THE MATRIX Q IS DETERMINED AS THE PRODUCT U(L-K)*...*U(1)
C     OF PLANE ROTATIONS OF THE FORM
C
C			    (	 C(I)	    S(I) )
C			    (			 ) ,
C			    ( -CONJG(S(I))  C(I) )
C
C     WHERE C(I) IS REAL, THE ROWS THESE ROTATIONS OPERATE ON
C     ARE DESCRIBED BELOW.
C
C     THERE ARE TWO TYPES OF PERMUTATIONS, WHICH ARE DETERMINED
C     BY THE VALUE OF JOB.
C
C     1. RIGHT CIRCULAR SHIFT (JOB = 1).
C
C	  THE COLUMNS ARE REARRANGED IN THE FOLLOWING ORDER.
C
C		 1,...,K-1,L,K,K+1,...,L-1,L+1,...,P.
C
C	  U IS THE PRODUCT OF L-K ROTATIONS U(I), WHERE U(I)
C	  ACTS IN THE (L-I,L-I+1)-PLANE.
C
C     2. LEFT CIRCULAR SHIFT (JOB = 2).
C	  THE COLUMNS ARE REARRANGED IN THE FOLLOWING ORDER
C
C		 1,...,K-1,K+1,K+2,...,L,K,L+1,...,P.
C
C	  U IS THE PRODUCT OF L-K ROTATIONS U(I), WHERE U(I)
C	  ACTS IN THE (K+I-1,K+I)-PLANE.
C
C     ON ENTRY
C
C	  R	 COMPLEX(LDR,P), WHERE LDR.GE.P.
C		 R CONTAINS THE UPPER TRIANGULAR FACTOR
C		 THAT IS TO BE UPDATED.	 ELEMENTS OF R
C		 BELOW THE DIAGONAL ARE NOT REFERENCED.
C
C	  LDR	 INTEGER.
C		 LDR IS THE LEADING DIMENSION OF THE ARRAY R.
C
C	  P	 INTEGER.
C		 P IS THE ORDER OF THE MATRIX R.
C
C	  K	 INTEGER.
C		 K IS THE FIRST COLUMN TO BE PERMUTED.
C
C	  L	 INTEGER.
C		 L IS THE LAST COLUMN TO BE PERMUTED.
C		 L MUST BE STRICTLY GREATER THAN K.
C
C	  Z	 COMPLEX(LDZ,NZ), WHERE LDZ.GE.P.
C		 Z IS AN ARRAY OF NZ P-VECTORS INTO WHICH THE
C		 TRANSFORMATION U IS MULTIPLIED.  Z IS
C		 NOT REFERENCED IF NZ = 0.
C
C	  LDZ	 INTEGER.
C		 LDZ IS THE LEADING DIMENSION OF THE ARRAY Z.
C
C	  NZ	 INTEGER.
C		 NZ IS THE NUMBER OF COLUMNS OF THE MATRIX Z.
C
C	  JOB	 INTEGER.
C		 JOB DETERMINES THE TYPE OF PERMUTATION.
C			JOB = 1	 RIGHT CIRCULAR SHIFT.
C			JOB = 2	 LEFT CIRCULAR SHIFT.
C
C     ON RETURN
C
C	  R	 CONTAINS THE UPDATED FACTOR.
C
C	  Z	 CONTAINS THE UPDATED MATRIX Z.
C
C	  C	 REAL(P).
C		 C CONTAINS THE COSINES OF THE TRANSFORMING ROTATIONS.
C
C	  S	 COMPLEX(P).
C		 S CONTAINS THE SINES OF THE TRANSFORMING ROTATIONS.
C
C--
C     LINPACK. THIS VERSION DATED 08/14/78 .
C     G.W. STEWART, UNIVERSITY OF MARYLAND, ARGONNE NATIONAL LAB.
C
C     CCHEX USES THE FOLLOWING FUNCTIONS AND SUBROUTINES.
C
C     EXTENDED BLAS CROTG
C     FORTRAN MIN0
      INTEGER I,II,IL,IU,J,JJ,KM1,KP1,LMK,LM1
      COMPLEX T
C
C     INITIALIZE
C
      KM1 = K - 1
      KP1 = K + 1
      LMK = L - K
      LM1 = L - 1
C
C     PERFORM THE APPROPRIATE TASK.
C
      GO TO (10,130), JOB
C
C     RIGHT CIRCULAR SHIFT.
C
   10 CONTINUE
C
C	 REORDER THE COLUMNS.
C
	 DO 20 I = 1, L
	    II = L - I + 1
	    S(I) = R(II,L)
   20	 CONTINUE
	 DO 40 JJ = K, LM1
	    J = LM1 - JJ + K
	    DO 30 I = 1, J
	       R(I,J+1) = R(I,J)
   30	    CONTINUE
	    R(J+1,J+1) = (0.0E0,0.0E0)
   40	 CONTINUE
	 IF (K .EQ. 1) GO TO 60
	    DO 50 I = 1, KM1
	       II = L - I + 1
	       R(I,K) = S(II)
   50	    CONTINUE
   60	 CONTINUE
C
C	 CALCULATE THE ROTATIONS.
C
	 T = S(1)
	 DO 70 I = 1, LMK
	    CALL CROTG(S(I+1),T,C(I),S(I))
	    T = S(I+1)
   70	 CONTINUE
	 R(K,K) = T
	 DO 90 J = KP1, P
	    IL = MAX0(1,L-J+1)
	    DO 80 II = IL, LMK
	       I = L - II
	       T = C(II)*R(I,J) + S(II)*R(I+1,J)
	       R(I+1,J) = C(II)*R(I+1,J) - CONJG(S(II))*R(I,J)
	       R(I,J) = T
   80	    CONTINUE
   90	 CONTINUE
C
C	 IF REQUIRED, APPLY THE TRANSFORMATIONS TO Z.
C
	 IF (NZ .LT. 1) GO TO 120
	 DO 110 J = 1, NZ
	    DO 100 II = 1, LMK
	       I = L - II
	       T = C(II)*Z(I,J) + S(II)*Z(I+1,J)
	       Z(I+1,J) = C(II)*Z(I+1,J) - CONJG(S(II))*Z(I,J)
	       Z(I,J) = T
  100	    CONTINUE
  110	 CONTINUE
  120	 CONTINUE
      GO TO 260
C
C     LEFT CIRCULAR SHIFT
C
  130 CONTINUE
C
C	 REORDER THE COLUMNS
C
	 DO 140 I = 1, K
	    II = LMK + I
	    S(II) = R(I,K)
  140	 CONTINUE
	 DO 160 J = K, LM1
	    DO 150 I = 1, J
	       R(I,J) = R(I,J+1)
  150	    CONTINUE
	    JJ = J - KM1
	    S(JJ) = R(J+1,J+1)
  160	 CONTINUE
	 DO 170 I = 1, K
	    II = LMK + I
	    R(I,L) = S(II)
  170	 CONTINUE
	 DO 180 I = KP1, L
	    R(I,L) = (0.0E0,0.0E0)
  180	 CONTINUE
C
C	 REDUCTION LOOP.
C
	 DO 220 J = K, P
	    IF (J .EQ. K) GO TO 200
C
C	       APPLY THE ROTATIONS.
C
	       IU = MIN0(J-1,L-1)
	       DO 190 I = K, IU
		  II = I - K + 1
		  T = C(II)*R(I,J) + S(II)*R(I+1,J)
		  R(I+1,J) = C(II)*R(I+1,J) - CONJG(S(II))*R(I,J)
		  R(I,J) = T
  190	       CONTINUE
  200	    CONTINUE
	    IF (J .GE. L) GO TO 210
	       JJ = J - K + 1
	       T = S(JJ)
	       CALL CROTG(R(J,J),T,C(JJ),S(JJ))
  210	    CONTINUE
  220	 CONTINUE
C
C	 APPLY THE ROTATIONS TO Z.
C
	 IF (NZ .LT. 1) GO TO 250
	 DO 240 J = 1, NZ
	    DO 230 I = K, LM1
	       II = I - KM1
	       T = C(II)*Z(I,J) + S(II)*Z(I+1,J)
	       Z(I+1,J) = C(II)*Z(I+1,J) - CONJG(S(II))*Z(I,J)
	       Z(I,J) = T
  230	    CONTINUE
  240	 CONTINUE
  250	 CONTINUE
  260 CONTINUE
      RETURN
      END
