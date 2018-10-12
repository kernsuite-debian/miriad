C***********************************************************************
c*CSROT -- Complex plane rotation.
c:BLAS
c+
      SUBROUTINE  CSROT (N,CX,INCX,CY,INCY,C,S)
C
C     APPLIES A PLANE ROTATION, WHERE THE COS AND SIN (C AND S) ARE REAL
C     AND THE VECTORS CX AND CY ARE COMPLEX.
C     JACK DONGARRA, LINPACK, 3/11/78.
C
C--
      COMPLEX CX(1),CY(1),CTEMP
      REAL C,S
      INTEGER I,INCX,INCY,IX,IY,N
C
      IF(N.LE.0)RETURN
      IF(INCX.EQ.1.AND.INCY.EQ.1)GO TO 20
C
C	CODE FOR UNEQUAL INCREMENTS OR EQUAL INCREMENTS NOT EQUAL
C	  TO 1
C
      IX = 1
      IY = 1
      IF(INCX.LT.0)IX = (-N+1)*INCX + 1
      IF(INCY.LT.0)IY = (-N+1)*INCY + 1
      DO 10 I = 1,N
	CTEMP = C*CX(IX) + S*CY(IY)
	CY(IY) = C*CY(IY) - S*CX(IX)
	CX(IX) = CTEMP
	IX = IX + INCX
	IY = IY + INCY
   10 CONTINUE
      RETURN
C
C	CODE FOR BOTH INCREMENTS EQUAL TO 1
C
   20 DO 30 I = 1,N
	CTEMP = C*CX(I) + S*CY(I)
	CY(I) = C*CY(I) - S*CX(I)
	CX(I) = CTEMP
   30 CONTINUE
      RETURN
      END