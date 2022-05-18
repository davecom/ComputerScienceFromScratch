# NanoBASIC/interpreter.py
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
#
# DESCRIPTION
# The interpreter is responsible for processing the nodes that come
# from the parser. In many interpreters, this structure will be represented as
# an abstract syntax tree. In NanoBASIC, the data structure that the interpreter receives is
# just an array of statement nodes; each node is something of a tree in itself. The interpreter
# translates the meaning of each statement node into Python code that can be run "live."
from __future__ import annotations  # can delete in 3.9
from NanoBASIC.nodes import *
from collections import deque
from typing import cast, Optional, Union


class Interpreter:
    class InterpreterError(Exception):
        def __init__(self, message: str, statement_or_expression: Union[Statement, NumericExpression]):
            self.message = message
            self.line_num = statement_or_expression.line_num
            self.column = statement_or_expression.col_start

        def __str__(self):
            return f"{self.message} Occurred at line {self.line_num} and column {self.column}"

    def __init__(self, statements: list[Statement]):
        self.statements = statements
        self.variable_table: dict[str, int] = {}
        self.statement_index: int = 0
        self.subroutine_stack: deque[int] = deque()

    @property
    def current(self) -> Statement:
        return self.statements[self.statement_index]

    # Returns the index of a *line_id* using a binary search, or None if not found
    # Assumes the statements list is sorted
    def find_line_index(self, line_id: int) -> Optional[int]:
        low: int = 0
        high: int = len(self.statements) - 1
        while low <= high:
            mid: int = (low + high) // 2
            if self.statements[mid].line_id < line_id:
                low = mid + 1
            elif self.statements[mid].line_id > line_id:
                high = mid - 1
            else:
                return mid
        return None

    def run(self):
        while self.statement_index < len(self.statements):
            self.interpret(self.current)

    def interpret(self, statement: Statement):
        if isinstance(statement, LetStatement):
            let_statement = cast(LetStatement, statement)
            value = self.evaluate_numeric(let_statement.value)
            self.variable_table[let_statement.name] = value
            self.statement_index += 1
        elif isinstance(statement, GoToStatement):
            goto_statement = cast(GoToStatement, statement)
            go_to_line_id = self.evaluate_numeric(goto_statement.goto_line_id)
            if (line_index := self.find_line_index(go_to_line_id)) is not None:
                self.statement_index = line_index
            else:
                raise Interpreter.InterpreterError("Couldn't find goto line id.", self.current)
        elif isinstance(statement, GoSubStatement):
            gosub_statement = cast(GoSubStatement, statement)
            go_to_line_id = self.evaluate_numeric(gosub_statement.goto_line_id)
            if (line_index := self.find_line_index(go_to_line_id)) is not None:
                self.subroutine_stack.append(self.statement_index + 1)  # Setup for RETURN
                self.statement_index = line_index
            else:
                raise Interpreter.InterpreterError("Couldn't find gosub line id.", self.current)
        elif isinstance(statement, ReturnStatement):
            if not self.subroutine_stack:  # Check if the stack is empty
                raise Interpreter.InterpreterError("Return with no prior corresponding gosub.", self.current)
            self.statement_index = self.subroutine_stack.pop()
        elif isinstance(statement, PrintStatement):
            print_statement = cast(PrintStatement, statement)
            accumulated_string: str = ""
            for index, printable in enumerate(print_statement.printables):
                if index > 0:  # Put tabs between items in the list
                    accumulated_string += "\t"
                if isinstance(printable, NumericExpression):
                    accumulated_string += str(self.evaluate_numeric(printable))
                else:  # Otherwise it's a string, because that's the only other thing we allow
                    accumulated_string += str(printable)
            print(accumulated_string)
            self.statement_index += 1
        elif isinstance(statement, IfStatement):
            if_statement = cast(IfStatement, statement)
            if self.evaluate_boolean(if_statement.boolean_expression):
                self.interpret(if_statement.then_statement)
            else:
                self.statement_index += 1
        else:
            raise Interpreter.InterpreterError(f"Unexpected item {self.current} in statement list.", self.current)

    def evaluate_numeric(self, numeric_expression: NumericExpression) -> int:
        if isinstance(numeric_expression, NumberLiteral):
            number_literal = cast(NumberLiteral, numeric_expression)
            return number_literal.number
        elif isinstance(numeric_expression, VarRetrieve):
            var_retrieve = cast(VarRetrieve, numeric_expression)
            if var_retrieve.name in self.variable_table:
                return self.variable_table[var_retrieve.name]
            else:
                raise Interpreter.InterpreterError(f"Var {var_retrieve.name} used before initialized.", var_retrieve)
        elif isinstance(numeric_expression, UnaryOperation):
            unary_operation = cast(UnaryOperation, numeric_expression)
            if unary_operation.operator is TokenType.MINUS:
                return -self.evaluate_numeric(unary_operation.value)
            else:
                raise Interpreter.InterpreterError(f"Expected - but got {unary_operation.operator}.", unary_operation)
        elif isinstance(numeric_expression, UnaryOperation):
            unary_operation = cast(UnaryOperation, numeric_expression)
            if unary_operation.operator is TokenType.MINUS:
                return -self.evaluate_numeric(unary_operation.value)
            else:
                raise Interpreter.InterpreterError(f"Expected - but got {unary_operation.operator}.", unary_operation)
        elif isinstance(numeric_expression, BinaryOperation):
            binary_operation = cast(BinaryOperation, numeric_expression)
            if binary_operation.operator is TokenType.PLUS:
                return self.evaluate_numeric(binary_operation.left) \
                       + self.evaluate_numeric(binary_operation.right)
            elif binary_operation.operator is TokenType.MINUS:
                return self.evaluate_numeric(binary_operation.left) \
                       - self.evaluate_numeric(binary_operation.right)
            elif binary_operation.operator is TokenType.MULTIPLY:
                return self.evaluate_numeric(binary_operation.left) \
                       * self.evaluate_numeric(binary_operation.right)
            elif binary_operation.operator is TokenType.DIVIDE:
                return self.evaluate_numeric(binary_operation.left) \
                       // self.evaluate_numeric(binary_operation.right)
            else:
                raise Interpreter.InterpreterError(f"Unexpected binary operator {binary_operation.operator}.", binary_operation)
        else:
            raise Interpreter.InterpreterError("Expected numeric expression, got something else.", numeric_expression)

    def evaluate_boolean(self, boolean_expression: BooleanExpression) -> bool:
        if boolean_expression.operator is TokenType.LESS:
            return self.evaluate_numeric(boolean_expression.left) \
                   < self.evaluate_numeric(boolean_expression.right)
        elif boolean_expression.operator is TokenType.LESS_EQUAL:
            return self.evaluate_numeric(boolean_expression.left) \
                   <= self.evaluate_numeric(boolean_expression.right)
        elif boolean_expression.operator is TokenType.GREATER:
            return self.evaluate_numeric(boolean_expression.left) \
                   > self.evaluate_numeric(boolean_expression.right)
        elif boolean_expression.operator is TokenType.GREATER_EQUAL:
            return self.evaluate_numeric(boolean_expression.left) \
                   >= self.evaluate_numeric(boolean_expression.right)
        elif boolean_expression.operator is TokenType.EQUAL:
            return self.evaluate_numeric(boolean_expression.left) \
                   == self.evaluate_numeric(boolean_expression.right)
        elif boolean_expression.operator is TokenType.NOT_EQUAL:
            return self.evaluate_numeric(boolean_expression.left) \
                   != self.evaluate_numeric(boolean_expression.right)
        else:
            raise Interpreter.InterpreterError(f"Unexpected boolean operator {boolean_expression.operator}.",
                                               boolean_expression)

