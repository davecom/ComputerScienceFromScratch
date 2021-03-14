10 LET A = 5 REM factorial that we want to calculate
15 LET B = A
16 LET B = B - 1
20 LET A = A * B
30 IF B = 1 THEN GOTO 40
35 GOTO 16
40 PRINT A REM expect 120