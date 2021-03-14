REM Find the greatest common divisor of A & B using Euclid's algorithm
10 LET A = 350
11 LET B = 539
20 GOSUB 30
21 IF A = B THEN GOTO 40
22 GOTO 20
REM Main GCD Subroutine
30 IF A > B THEN LET A = A - B
31 IF A < B THEN LET B = B - A
33 RETURN
REM We're done, print the GCD, expecting 7
40 PRINT A