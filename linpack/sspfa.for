C***********************************************************************
c*SSPFA -- Factor a real symmetric matrix in packed form.
c:LINPACK
c+
      SUBROUTINE SSPFA(AP,N,KPVT,INFO)
      INTEGER N,KPVT(1),INFO
      REAL AP(1)
C
C     SSPFA FACTORS A REAL SYMMETRIC MATRIX STORED IN
C     PACKED FORM BY ELIMINATION WITH SYMMETRIC PIVOTING.
C
C     TO SOLVE	A*X = B , FOLLOW SSPFA BY SSPSL.
C     TO COMPUTE  INVERSE(A)*C , FOLLOW SSPFA BY SSPSL.
C     TO COMPUTE  DETERMINANT(A) , FOLLOW SSPFA BY SSPDI.
C     TO COMPUTE  INERTIA(A) , FOLLOW SSPFA BY SSPDI.
C     TO COMPUTE  INVERSE(A) , FOLLOW SSPFA BY SSPDI.
C
C     ON ENTRY
C
C	 AP	 REAL (N*(N+1)/2)
C		 THE PACKED FORM OF A SYMMETRIC MATRIX	A .  THE
C		 COLUMNS OF THE UPPER TRIANGLE ARE STORED SEQUENTIALLY
C		 IN A ONE-DIMENSIONAL ARRAY OF LENGTH  N*(N+1)/2 .
C		 SEE COMMENTS BELOW FOR DETAILS.
C
C	 N	 INTEGER
C		 THE ORDER OF THE MATRIX  A .
C
C     OUTPUT
C
C	 AP	 A BLOCK DIAGONAL MATRIX AND THE MULTIPLIERS WHICH
C		 WERE USED TO OBTAIN IT STORED IN PACKED FORM.
C		 THE FACTORIZATION CAN BE WRITTEN  A = U*D*TRANS(U)
C		 WHERE	U  IS A PRODUCT OF PERMUTATION AND UNIT
C		 UPPER TRIANGULAR MATRICES , TRANS(U) IS THE
C		 TRANSPOSE OF  U , AND	D  IS BLOCK DIAGONAL
C		 WITH 1 BY 1 AND 2 BY 2 BLOCKS.
C
C	 KPVT	 INTEGER(N)
C		 AN INTEGER VECTOR OF PIVOT INDICES.
C
C	 INFO	 INTEGER
C		 = 0  NORMAL VALUE.
C		 = K  IF THE K-TH PIVOT BLOCK IS SINGULAR. THIS IS
C		      NOT AN ERROR CONDITION FOR THIS SUBROUTINE,
C		      BUT IT DOES INDICATE THAT SSPSL OR SSPDI MAY
C		      DIVIDE BY ZERO IF CALLED.
C
C     PACKED STORAGE
C
C	   THE FOLLOWING PROGRAM SEGMENT WILL PACK THE UPPER
C	   TRIANGLE OF A SYMMETRIC MATRIX.
C
C		 K = 0
C		 DO 20 J = 1, N
C		    DO 10 I = 1, J
C		       K = K + 1
C		       AP(K)  = A(I,J)
C	      10    CONTINUE
C	      20 CONTINUE
C
C--
C     LINPACK. THIS VERSION DATED 08/14/78 .
C     JAMES BUNCH, UNIV. CALIF. SAN DIEGO, ARGONNE NAT. LAB.
C
C     SUBROUTINES AND FUNCTIONS
C
C     BLAS SAXPY,SSWAP,ISAMAX
C     FORTRAN ABS,AMAX1,SQRT
C
C     INTERNAL VARIABLES
C
      REAL AK,AKM1,BK,BKM1,DENOM,MULK,MULKM1,T
      REAL ABSAKK,ALPHA,COLMAX,ROWMAX
      INTEGER ISAMAX,IJ,IJJ,IK,IKM1,IM,IMAX,IMAXP1,IMIM,IMJ,IMK
      INTEGER J,JJ,JK,JKM1,JMAX,JMIM,K,KK,KM1,KM1K,KM1KM1,KM2,KSTEP
      LOGICAL SWAP
C
C
C     INITIALIZE
C
C     ALPHA IS USED IN CHOOSING PIVOT BLOCK SIZE.
      ALPHA = (1.0E0 + SQRT(17.0E0))/8.0E0
C
      INFO = 0
C
C     MAIN LOOP ON K, WHICH GOES FROM N TO 1.
C
      K = N
      IK = (N*(N - 1))/2
   10 CONTINUE
C
C	 LEAVE THE LOOP IF K=0 OR K=1.
C
C     ...EXIT
	 IF (K .EQ. 0) GO TO 200
	 IF (K .GT. 1) GO TO 20
	    KPVT(1) = 1
	    IF (AP(1) .EQ. 0.0E0) INFO = 1
C     ......EXIT
	    GO TO 200
   20	 CONTINUE
C
C	 THIS SECTION OF CODE DETERMINES THE KIND OF
C	 ELIMINATION TO BE PERFORMED.  WHEN IT IS COMPLETED,
C	 KSTEP WILL BE SET TO THE SIZE OF THE PIVOT BLOCK, AND
C	 SWAP WILL BE SET TO .TRUE. IF AN INTERCHANGE IS
C	 REQUIRED.
C
	 KM1 = K - 1
	 KK = IK + K
	 ABSAKK = ABS(AP(KK))
C
C	 DETERMINE THE LARGEST OFF-DIAGONAL ELEMENT IN
C	 COLUMN K.
C
	 IMAX = ISAMAX(K-1,AP(IK+1),1)
	 IMK = IK + IMAX
	 COLMAX = ABS(AP(IMK))
	 IF (ABSAKK .LT. ALPHA*COLMAX) GO TO 30
	    KSTEP = 1
	    SWAP = .FALSE.
	 GO TO 90
   30	 CONTINUE
C
C	    DETERMINE THE LARGEST OFF-DIAGONAL ELEMENT IN
C	    ROW IMAX.
C
	    ROWMAX = 0.0E0
	    IMAXP1 = IMAX + 1
	    IM = IMAX*(IMAX - 1)/2
	    IMJ = IM + 2*IMAX
	    DO 40 J = IMAXP1, K
	       ROWMAX = AMAX1(ROWMAX,ABS(AP(IMJ)))
	       IMJ = IMJ + J
   40	    CONTINUE
	    IF (IMAX .EQ. 1) GO TO 50
	       JMAX = ISAMAX(IMAX-1,AP(IM+1),1)
	       JMIM = JMAX + IM
	       ROWMAX = AMAX1(ROWMAX,ABS(AP(JMIM)))
   50	    CONTINUE
	    IMIM = IMAX + IM
	    IF (ABS(AP(IMIM)) .LT. ALPHA*ROWMAX) GO TO 60
	       KSTEP = 1
	       SWAP = .TRUE.
	    GO TO 80
   60	    CONTINUE
	    IF (ABSAKK .LT. ALPHA*COLMAX*(COLMAX/ROWMAX)) GO TO 70
	       KSTEP = 1
	       SWAP = .FALSE.
	    GO TO 80
   70	    CONTINUE
	       KSTEP = 2
	       SWAP = IMAX .NE. KM1
   80	    CONTINUE
   90	 CONTINUE
	 IF (AMAX1(ABSAKK,COLMAX) .NE. 0.0E0) GO TO 100
C
C	    COLUMN K IS ZERO.  SET INFO AND ITERATE THE LOOP.
C
	    KPVT(K) = K
	    INFO = K
	 GO TO 190
  100	 CONTINUE
	 IF (KSTEP .EQ. 2) GO TO 140
C
C	    1 X 1 PIVOT BLOCK.
C
	    IF (.NOT.SWAP) GO TO 120
C
C	       PERFORM AN INTERCHANGE.
C
	       CALL SSWAP(IMAX,AP(IM+1),1,AP(IK+1),1)
	       IMJ = IK + IMAX
	       DO 110 JJ = IMAX, K
		  J = K + IMAX - JJ
		  JK = IK + J
		  T = AP(JK)
		  AP(JK) = AP(IMJ)
		  AP(IMJ) = T
		  IMJ = IMJ - (J - 1)
  110	       CONTINUE
  120	    CONTINUE
C
C	    PERFORM THE ELIMINATION.
C
	    IJ = IK - (K - 1)
	    DO 130 JJ = 1, KM1
	       J = K - JJ
	       JK = IK + J
	       MULK = -AP(JK)/AP(KK)
	       T = MULK
	       CALL SAXPY(J,T,AP(IK+1),1,AP(IJ+1),1)
	       IJJ = IJ + J
	       AP(JK) = MULK
	       IJ = IJ - (J - 1)
  130	    CONTINUE
C
C	    SET THE PIVOT ARRAY.
C
	    KPVT(K) = K
	    IF (SWAP) KPVT(K) = IMAX
	 GO TO 190
  140	 CONTINUE
C
C	    2 X 2 PIVOT BLOCK.
C
	    KM1K = IK + K - 1
	    IKM1 = IK - (K - 1)
	    IF (.NOT.SWAP) GO TO 160
C
C	       PERFORM AN INTERCHANGE.
C
	       CALL SSWAP(IMAX,AP(IM+1),1,AP(IKM1+1),1)
	       IMJ = IKM1 + IMAX
	       DO 150 JJ = IMAX, KM1
		  J = KM1 + IMAX - JJ
		  JKM1 = IKM1 + J
		  T = AP(JKM1)
		  AP(JKM1) = AP(IMJ)
		  AP(IMJ) = T
		  IMJ = IMJ - (J - 1)
  150	       CONTINUE
	       T = AP(KM1K)
	       AP(KM1K) = AP(IMK)
	       AP(IMK) = T
  160	    CONTINUE
C
C	    PERFORM THE ELIMINATION.
C
	    KM2 = K - 2
	    IF (KM2 .EQ. 0) GO TO 180
	       AK = AP(KK)/AP(KM1K)
	       KM1KM1 = IKM1 + K - 1
	       AKM1 = AP(KM1KM1)/AP(KM1K)
	       DENOM = 1.0E0 - AK*AKM1
	       IJ = IK - (K - 1) - (K - 2)
	       DO 170 JJ = 1, KM2
		  J = KM1 - JJ
		  JK = IK + J
		  BK = AP(JK)/AP(KM1K)
		  JKM1 = IKM1 + J
		  BKM1 = AP(JKM1)/AP(KM1K)
		  MULK = (AKM1*BK - BKM1)/DENOM
		  MULKM1 = (AK*BKM1 - BK)/DENOM
		  T = MULK
		  CALL SAXPY(J,T,AP(IK+1),1,AP(IJ+1),1)
		  T = MULKM1
		  CALL SAXPY(J,T,AP(IKM1+1),1,AP(IJ+1),1)
		  AP(JK) = MULK
		  AP(JKM1) = MULKM1
		  IJJ = IJ + J
		  IJ = IJ - (J - 1)
  170	       CONTINUE
  180	    CONTINUE
C
C	    SET THE PIVOT ARRAY.
C
	    KPVT(K) = 1 - K
	    IF (SWAP) KPVT(K) = -IMAX
	    KPVT(K-1) = KPVT(K)
  190	 CONTINUE
	 IK = IK - (K - 1)
	 IF (KSTEP .EQ. 2) IK = IK - (K - 2)
	 K = K - KSTEP
      GO TO 10
  200 CONTINUE
      RETURN
      END
