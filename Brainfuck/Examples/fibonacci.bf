+++++++++++ number of digits to output
> #1
+ initial number
>>>> #5
++++++++++++++++++++++++++++++++++++++++++++ (comma)
> #6
++++++++++++++++++++++++++++++++ (space)
<<<<<< #0
[
  > #1
  copy #1 to #7
  [>>>>>>+>+<<<<<<<-]>>>>>>>[<<<<<<<+>>>>>>>-]

  <
  divide #7 by 10 (begins in #7)
  [
    >
    ++++++++++  set the divisor #8
    [
      subtract from the dividend and divisor
      -<-
      if dividend reaches zero break out
        copy dividend to #9
        [>>+>+<<<-]>>>[<<<+>>>-]
        set #10
        +
        if #9 clear #10
        <[>[-]<[-]]
        if #10 move remaining divisor to #11
        >[<<[>>>+<<<-]>>[-]]
      jump back to #8 (divisor possition)
      <<
    ]
    if #11 is empty (no remainder) increment the quotient #12
    >>> #11
    copy to #13
    [>>+>+<<<-]>>>[<<<+>>>-]
    set #14
    +
    if #13 clear #14
    <[>[-]<[-]]
    if #14 increment quotient
    >[<<+>>[-]]
    <<<<<<< #7
  ]

  quotient is in #12 and remainder is in #11
  >>>>> #12
  if #12 output value plus offset to ascii 0
  [++++++++++++++++++++++++++++++++++++++++++++++++.[-]]
  subtract #11 from 10
  ++++++++++  #12 is now 10
  < #11
  [->-<]
  > #12
  output #12 even if it's zero
  ++++++++++++++++++++++++++++++++++++++++++++++++.[-]
  <<<<<<<<<<< #1

  check for final number
  copy #0 to #3
  <[>>>+>+<<<<-]>>>>[<<<<+>>>>-]
  <- #3
  if #3 output (comma) and (space)
  [>>.>.<<<[-]]
  << #1

  [>>+>+<<<-]>>>[<<<+>>>-]<<[<+>-]>[<+>-]<<<-
]

