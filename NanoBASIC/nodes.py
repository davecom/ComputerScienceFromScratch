# NanoBASIC/nodes.py
# From Fun Computer Science Projects in Python
# Copyright 2024 David Kopec
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
#
# DESCRIPTION
# This file defines the nodes that the parser can create. Nodes are meaningful
# chunks of a program for the interpreter to interpret. For example, generally
# each statement will become a node.
from dataclasses import dataclass
from NanoBASIC.tokenizer import TokenType


# For debug purposes, we'll need to know the locations of all Nodes
@dataclass(frozen=True)
class Node:
    line_num: int
    col_start: int
    col_end: int


# All statements in NanoBASIC have a line number identifier
# that the programmer puts in before the statement (*line_id*)
# This is a little confusing because there's also the "physical"
# line number (*line_num*), that actual count of how many lines down
# in the file where the statement occurs
@dataclass(frozen=True)
class Statement(Node):
    line_id: int


# A numeric expression is something that can be computed into a number
# This is a super class of literals, variables & simple arithmetic operations
@dataclass(frozen=True)
class NumericExpression(Node):
    pass


# A numeric expression with two operands like +, -, *, and /
@dataclass(frozen=True)
class BinaryOperation(NumericExpression):
    operator: TokenType
    left_expr: NumericExpression
    right_expr: NumericExpression

    def __repr__(self) -> str:
        return f"{self.left_expr} {self.operator} {self.right_expr}"


# A numeric expression with one operand like -
@dataclass(frozen=True)
class UnaryOperation(NumericExpression):
    operator: TokenType
    expr: NumericExpression

    def __repr__(self) -> str:
        return f"{self.operator}{self.expr}"


# An integer written out in NanoBASIC code
@dataclass(frozen=True)
class NumberLiteral(NumericExpression):
    number: int


# A variable *name* that will have its value retrieved
@dataclass(frozen=True)
class VarRetrieve(NumericExpression):
    name: str


# A boolean expression can be computed to a true or false value
# It takes two numeric expressions, *left_expr* and *right_expr*, and compares
# them using a boolean *operator*
@dataclass(frozen=True)
class BooleanExpression(Node):
    operator: TokenType
    left_expr: NumericExpression
    right_expr: NumericExpression

    def __repr__(self) -> str:
        return f"{self.left_expr} {self.operator} {self.right_expr}"


# Represents a LET statement, setting *name* to *expr*
@dataclass(frozen=True)
class LetStatement(Statement):
    name: str
    expr: NumericExpression


# Represents a GOTO statement, transferring control to *line_expr*
@dataclass(frozen=True)
class GoToStatement(Statement):
    line_expr: NumericExpression


# Represents a GOSUB statement, transferring control to *line_expr*
# Return line_id is not saved here, it will be maintained by a stack
@dataclass(frozen=True)
class GoSubStatement(Statement):
    line_expr: NumericExpression


# Represents a RETURN statement, transferring control to the line after
# the last GOSUB statement
@dataclass(frozen=True)
class ReturnStatement(Statement):
    pass


# A PRINT statement with all that it is meant to print (comma separated)
@dataclass(frozen=True)
class PrintStatement(Statement):
    printables: list[str | NumericExpression]


# An IF statement
# *then_statement* is what statement will be executed if the
# *boolean_expression* is true
@dataclass(frozen=True)
class IfStatement(Statement):
    boolean_expr: BooleanExpression
    then_statement: Statement
