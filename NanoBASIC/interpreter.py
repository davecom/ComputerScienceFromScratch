# NanoBASIC/interpreter.py
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
# The interpreter is responsible for processing the nodes that come
# from the parser. In many interpreters, this structure will be represented as
# an abstract syntax tree. In NanoBASIC, the root of the AST is
# just an array of statement nodes; each node is something of a tree in itself. The interpreter
# translates the meaning of each statement node into Python code that can be run "live."
from NanoBASIC.nodes import *
from NanoBASIC.errors import InterpreterError
from collections import deque


class Interpreter:
    def __init__(self, statements: list[Statement]):
        self.statements = statements
        self.variable_table: dict[str, int] = {}
        self.statement_index: int = 0
        self.subroutine_stack: deque[int] = deque()

    @property
    def current(self) -> Statement:
        return self.statements[self.statement_index]

    # Returns the index of a *line_id* using a binary search,
    # or None if not found; Assumes the statements list is sorted
    def find_line_index(self, line_id: int) -> int | None:
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
        match statement:
            case LetStatement(name=name, expr=expr):
                value = self.evaluate_numeric(expr)
                self.variable_table[name] = value
                self.statement_index += 1
            case GoToStatement(line_expr=line_expr):
                go_to_line_id = self.evaluate_numeric(line_expr)
                if (line_index := self.find_line_index(go_to_line_id)) is not None:
                    self.statement_index = line_index
                else:
                    raise InterpreterError("No GOTO line id.", self.current)
            case GoSubStatement(line_expr=line_expr):
                go_sub_line_id = self.evaluate_numeric(line_expr)
                if (line_index := self.find_line_index(go_sub_line_id)) is not None:
                    self.subroutine_stack.append(self.statement_index + 1)  # Setup for RETURN
                    self.statement_index = line_index
                else:
                    raise InterpreterError("No GOSUB line id.", self.current)
            case ReturnStatement():
                if not self.subroutine_stack:  # Check if the stack is empty
                    raise InterpreterError("RETURN without GOSUB.", self.current)
                self.statement_index = self.subroutine_stack.pop()
            case PrintStatement(printables=printables):
                accumulated_string: str = ""
                for index, printable in enumerate(printables):
                    if index > 0:  # Put tabs between items in the list
                        accumulated_string += "\t"
                    if isinstance(printable, NumericExpression):
                        accumulated_string += str(self.evaluate_numeric(printable))
                    else:  # Otherwise, it's a string
                        accumulated_string += str(printable)
                print(accumulated_string)
                self.statement_index += 1
            case IfStatement(boolean_expr=boolean_expr, then_statement=then_statement):
                if self.evaluate_boolean(boolean_expr):
                    self.interpret(then_statement)
                else:
                    self.statement_index += 1
            case _:
                raise InterpreterError(f"Unexpected item {self.current} "
                                       f"in statement list.", self.current)

    def evaluate_numeric(self, numeric_expression: NumericExpression) -> int:
        match numeric_expression:
            case NumberLiteral(number=number):
                return number
            case VarRetrieve(name=name):
                if name in self.variable_table:
                    return self.variable_table[name]
                else:
                    raise InterpreterError(f"Var {name} used "
                                           f"before initialized.", numeric_expression)
            case UnaryOperation(operator=operator, expr=expr):
                if operator is TokenType.MINUS:
                    return -self.evaluate_numeric(expr)
                else:
                    raise InterpreterError(f"Expected - "
                                           f"but got {operator}.", numeric_expression)
            case BinaryOperation(operator=operator, left_expr=left, right_expr=right):
                if operator is TokenType.PLUS:
                    return self.evaluate_numeric(left) + self.evaluate_numeric(right)
                elif operator is TokenType.MINUS:
                    return self.evaluate_numeric(left) - self.evaluate_numeric(right)
                elif operator is TokenType.MULTIPLY:
                    return self.evaluate_numeric(left) * self.evaluate_numeric(right)
                elif operator is TokenType.DIVIDE:
                    return self.evaluate_numeric(left) // self.evaluate_numeric(right)
                else:
                    raise InterpreterError(f"Unexpected binary operator "
                                           f"{operator}.", numeric_expression)
            case _:
                raise InterpreterError("Expected numeric expression.",
                                       numeric_expression)

    def evaluate_boolean(self, boolean_expression: BooleanExpression) -> bool:
        left = self.evaluate_numeric(boolean_expression.left_expr)
        right = self.evaluate_numeric(boolean_expression.right_expr)
        match boolean_expression.operator:
            case TokenType.LESS:
                return left < right
            case TokenType.LESS_EQUAL:
                return left <= right
            case TokenType.GREATER:
                return left > right
            case TokenType.GREATER_EQUAL:
                return left >= right
            case TokenType.EQUAL:
                return left == right
            case TokenType.NOT_EQUAL:
                return left != right
            case _:
                raise InterpreterError(f"Unexpected boolean operator "
                                       f"{boolean_expression.operator}.", boolean_expression)
