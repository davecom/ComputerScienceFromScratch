# NanoBASIC

NanoBASIC is a version of the [BASIC](https://en.wikipedia.org/wiki/BASIC) programming language derived from a popular dialect for 1970s microcomputers known as [TinyBASIC](https://en.wikipedia.org/wiki/Tiny_BASIC). NanoBASIC is even simpler (or smaller, if you will) than TinyBASIC, hence the Nano designation. 

## BASIC History

BASIC, originally developed in 1964 at Dartmouth College to provide non-science and math students a way to use computers, became the most popular programming language for personal computers in the 1970s through to the mid-1980s. Popular computers of the era, like the Commodore 64 and the Apple II, came with BASIC interpreters built-in. BASIC was therefore the way that many people interacted with early personal computers. For example, BASIC was Linus Torvalds first programming language on the Commodore VIC-20 in 1981.

Interestingly, Microsoft got its start in 1975 when Bill Gates and Paul Allen developed a BASIC interpreter for one of the first personal computers, the Altair 8800. Their company flourished when they ported their interpreter to other machines of the late 1970s. Microsoft BASIC was shipped with many personal computers, and became the de facto standard dialect of BASIC. Eventually Microsoft entered the operating system business with DOS in 1981 on the original IBM PC, but BASIC was the company's start. Now you'll be developing a BASIC interpreter too!

## NanoBASIC is Simple

As you've read, BASIC was intended to be easy to use for non-technical people. Hence, BASIC is a fairly simple programming language. The dialect we're developing, NanoBASIC, is imperative, but we'd barely even call it procedural. While it technically has a way of defining a "call to a subroutine" there is really nothing resembling a modern function in the sense of having parameters and return values. 

Some versions of BASIC, like TinyBASIC and NanoBASIC, not only have no sense of a function, they also do not have loops or other modern control structures. Instead, all control is handled with `GOTO`s/`GOSUB`s, which are direct jumps to a specific line number of the program. These, coupled with if-statements, serve as the only way to control a TinyBASIC/NanoBASIC program.

### Comments and Line Numbers

Comments in NanoBASIC start with the `REM` designation and can finish with any string. Comments will not be processed at all by the interpreter.

Every non-comment line in NanoBASIC begins with a line number and is followed by a statement. Line numbers should always be increasing from the top of the source file to the bottom of the source file. So, the following line numbers are valid:

```
10 PRINT "Hello"
REM This is a comment
20 PRINT "Goodbye"
30 PRINT "WOW"
```

But this version is not

```
10 PRINT "Hello"
REM This is a comment
40 PRINT "Goodbye"
30 PRINT "WOW"
```

Its behavior is undefined. Programs that have `GOTO`/`GOSUB` statements and out-of-order line numbers will not function correctly. The programmer can pick arbitrary line numbers, as long as they are all in increasing order.

There are only six ways to start a statement in NanoBASIC: `PRINT`, `IF`, `GOTO`, `GOSUB`, `RETURN`, and `LET`. If you know these six statement types, you basically know the whole language. You can learn NanoBASIC in just a few minutes if you already know another programming language.

### `LET`, Variables, and Mathematical Expressions

`LET` binds a value to a variable. Like TinyBASIC, NanoBASIC is limited to 26 single letter variable names (A-Z) and all variables only have one type—16-bit integers. The following statement sets the variable `A` to `5`.

```
10 LET A = 5
```

`LET` must be followed by a variable name (A-Z) and an equal (`=`) sign. After that, any mathematical expression can appear. NanoBASIC mathematical expressions can be composed of variables, integer literals, and the operators for addition (`+`), subtraction (`-`), multiplication (`*`), division (`/`), and parentheses (`(` and `)`). In addition, one can negate any mathematical value in NanoBASIC with the negative (`-`) sign. Note that all math takes place in the realm of 16-bit signed integers. From this point forward in the guide, we will just refer to mathematical expressions as "expressions." The following are all valid uses of `LET`:

```
20 LET B = A
30 LET C = 23 - A
40 LET D = 5 * (24 + 25)
50 LET E = -(24 + 23 - (2 * (5 + 3)))
```

### `PRINT` Statements

`PRINT` is used for output to the console. Any string literal or expression can be output to the console. As in TINYBasic, NanoBASIC string literals can only contain the characters A-Z, a-z, spaces, and 0-9. String literals are wrapped in double quote characters (`"`).

```
10 PRINT "What a nice program"
20 PRINT "Who said sit down question mark"
30 PRINT "6734 spells HELP upside down sorta"
```

As mentioned, `PRINT` can also print any expression.

```
REM This was the first thing Paul Allen ran on the Altair 8800
70 PRINT 2 + 2
```

You can also supply, a comma-separated list of items (string-literals and expressions) to `PRINT`. All items printed will have tab characters between them. `PRINT` always finishes printing by inserting a newline character.

### `IF` Statements and Boolean Expressions

`IF` statements are like if-statements in other languages, but simpler and more succinct. They can only have a single boolean expression (there is no `&&` or `||` operator for example). They have no else-clause. And finally, they can only execute a single statement if they are true. The statement to execute on truth is always preceded by the literal `THEN`.

```
500 IF N < 10 THEN PRINT "Small Number"
700 IF V >= 34 THEN GOTO 20
```

Boolean expressions are mostly what you would expect. The opreators do differ slightly however from standard C-style operators. For instance, not-equal can be either `<>` or `><` in TinyBASIC/NanoBASIC. And equal is `=` not `==`.

### GOTO, GOSUB, and RETURN statements

A GOTO directly jumps to a line number with no way to go back. A GOSUB jumps to a line number, but a matching RETURN statement will send the program back to the line just after where the GOSUB was originally called.

```
10 GOTO 50
20 LET A = 10
40 RETURN
50 LET A = 5
60 GOSUB 20
REM RETURN returns to here; we expect A to be 10
70 PRINT A
```

## NanoBASIC Style

It is generally good style to write all keywords in BASIC in all capital letters. Because TinyBASIC/NanoBASIC variable names are obtuse, it's a good idea to include comments explaining any unclear variable names. 

Unfortunately, it's normal for BASIC code to quickly become so-called "spaghetti code" full of `GOTO` statements. This is par-for-the-course and there's not much you can do about it in NanoBASIC if you want to write a program of any moderate complexity. Eventually, people becoming unhappy with the `GOTO` style of programming created the "structured programming" movement. Edsger Dijkstra famously wrote a letter called ["Go To Statement Considered Harmful"](https://en.wikipedia.org/wiki/Considered_harmful).

## Miscellaneous
- NanoBASIC is case-insensitive. This means that `LET A = 5` is the same as `let a = 5`.
- Behavior not described in this document is undefined.
- NanoBASIC does not properly handle overflows. How overflow calculations result is undefined.

## NanoBASIC is Purposely Damaged Goods

We wanted to give you a sense of what programming in TinyBASIC was like. It would've been arbitrarily easy to support all Swift string literals, or 64-bit integers in NanoBASIC, but instead you're getting the real 1970s experience.
