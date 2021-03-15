# NanoBASIC/nodes.py
# From Fun Computer Science Projects in Python
# Copyright 2021 David Kopec
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
from dataclasses import dataclass
from typing import Union
from tokenizer import TokenType


# All statements in NanoBASIC have a line number identifier
# that the programmer puts in before the statement (*line_id*)
# This is a little confusing because there's also the "physical"
# line number (line_num), that actual count of how many lines down
# in the file where the statement occurs
# The column range is for debugging purposes
@dataclass(frozen=True)
class Statement:
    line_id: int
    line_num: int
    col_start: int
    col_end: int


# There are a couple places in the program where we will need multiple
# statements together, and it's nice to have a type alias for that
StatementList = list[Statement]


# A numeric expression is something that can be computed into a number
# We keep track of where all numeric expressions occurred in the program
# for debugging purposes
@dataclass(frozen=True)
class NumericExpression:
    line_num: int
    col_start: int
    col_end: int


# Represents a LET statement, setting *name* to *value*
@dataclass(frozen=True)
class LetStatement(Statement):
    name: str
    value: NumericExpression


# Represents a GOTO statement, transferring control to *goto_line_id*
@dataclass(frozen=True)
class GoToStatement(Statement):
    goto_line_id: NumericExpression


# Represents a GOSUB statement, transferring control to *goto_line_id*
# Return line_id is not saved here, it will be maintained by a stack
@dataclass(frozen=True)
class GoSubStatement(Statement):
    goto_line_id: NumericExpression


# Represents a RETURN statement, transferring control to the line after
# the last GOSUB statement
@dataclass(frozen=True)
class ReturnStatement(Statement):
    pass


# A PRINT statement with all the things that it is meant to print (comma separated)
@dataclass(frozen=True)
class PrintStatement(Statement):
    printables: list[Union[str, NumericExpression]]


# A boolean expression can be computed to a true or false value
# It takes two numeric expressions, *left* and *right*, and compares
# them using a boolean *operator*
@dataclass(frozen=True)
class BooleanExpression:
    operator: TokenType
    left: NumericExpression
    right: NumericExpression
    line_num: int
    col_start: int
    col_end: int

    def __repr__(self) -> str:
        return f"{self.left} {self.operator} {self.right}"


# An IF statement
# *then_statement* is what statement will be executed if the
# *boolean_expression* is true
@dataclass(frozen=True)
class IfStatement(Statement):
    boolean_expression: BooleanExpression
    then_statement: Statement


# A numeric expression with two operands like +, -, *, and /
@dataclass(frozen=True)
class BinaryOperation(NumericExpression):
    operator: TokenType
    left: NumericExpression
    right: NumericExpression

    def __repr__(self) -> str:
        return f"{self.left} {self.operator} {self.right}"


# A numeric expression with one operands like -
@dataclass(frozen=True)
class UnaryOperation(NumericExpression):
    operator: TokenType
    value: NumericExpression

    def __repr__(self) -> str:
        return f"{self.operator}{self.value}"


# An integer written out in NanoBASIC code
@dataclass(frozen=True)
class NumberLiteral(NumericExpression):
    number: int


# A variable *name* that will have its value retrieved
@dataclass(frozen=True)
class VarRetrieve(NumericExpression):
    name: str
