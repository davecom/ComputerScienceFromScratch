# NanoBASIC/parser.py
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
# The parser takes the tokens from the tokenizer and tries to convert them
# into structures that are meaningful for interpreting the program. The
# particular parsing technique being used in parser.py is recursive descent.
# In recursive descent, generally each non-terminal defined in the grammar becomes
# a function. That function is responsible for checking that the tokens it is
# analyzing follow a production rule specified in the grammar. In other words,
# generally one recursive descent function = one production rule from the grammar.
# The parser checks the tokens by looking at them sequentially. If the token that
# is being analyzed is expected to be a part of another production rule, the
# recursive descent parser just calls the function representing that other production rule.
# The recursive descent functions return respective nodes when they are successful.
from NanoBASIC.tokenizer import Token
from typing import cast
from NanoBASIC.nodes import *


class Parser:
    class ParserError(Exception):
        def __init__(self, message: str, token: Token):
            self.message = message
            self.line_num = token.line_num
            self.column = token.col_start

        def __str__(self):
            return f"{self.message} Occurred at line {self.line_num} and column {self.column}"

    def __init__(self, tokens: list[Token]):
        self.tokens = tokens
        self.token_index: int = 0

    @property
    def out_of_tokens(self) -> bool:
        return self.token_index >= len(self.tokens)

    @property
    def current(self) -> Token:
        if self.out_of_tokens:
            raise (Parser.ParserError(f"Ran out of tokens after {self.previous.kind}.", self.previous))
        return self.tokens[self.token_index]

    @property
    def previous(self) -> Token:
        return self.tokens[self.token_index - 1]

    def consume(self, kind: TokenType) -> Token:
        if self.current.kind is kind:
            self.token_index += 1
            return self.previous
        raise Parser.ParserError(f"Expected {kind} after {self.previous}"
                                 f"but got {self.current}.", self.current)

    def parse(self) -> list[Statement]:
        statements: list[Statement] = []
        while not self.out_of_tokens:
            statement = self.parse_line()
            statements.append(statement)
        return statements

    def parse_line(self) -> Statement:
        number = self.consume(TokenType.NUMBER)
        return self.parse_statement(cast(int, number.associated_value))

    def parse_statement(self, line_id: int) -> Statement:
        match self.current.kind:
            case TokenType.PRINT:
                return self.parse_print(line_id)
            case TokenType.IF_T:
                return self.parse_if(line_id)
            case TokenType.LET:
                return self.parse_let(line_id)
            case TokenType.GOTO:
                return self.parse_goto(line_id)
            case TokenType.GOSUB:
                return self.parse_gosub(line_id)
            case TokenType.RETURN_T:
                return self.parse_return(line_id)
        raise Parser.ParserError("Expected to find start of statement.", self.current)

    # PRINT "COMMA",SEPARATED,7154
    def parse_print(self, line_id: int) -> PrintStatement:
        print_token = self.consume(TokenType.PRINT)
        printables: list[str | NumericExpression] = []
        last_col: int = print_token.col_end
        while True:  # Keep finding things to print
            if self.current.kind is TokenType.STRING:
                string = self.consume(TokenType.STRING)
                printables.append(cast(str, string.associated_value))
                last_col = string.col_end
            elif (expression := self.parse_numeric_expression()) is not None:
                printables.append(expression)
                last_col = expression.col_end
            else:
                raise Parser.ParserError("Only strings and numeric expressions allowed in print list.", self.current)
            if not self.out_of_tokens and self.current.kind is TokenType.COMMA:  # Comma means there's more
                self.consume(TokenType.COMMA)
                continue
            break
        return PrintStatement(line_id=line_id, line_num=print_token.line_num,
                              col_start=print_token.col_start, col_end=last_col,
                              printables=printables)

    # IF BOOLEAN_EXPRESSION THEN STATEMENT
    def parse_if(self, line_id: int) -> IfStatement:
        if_token = self.consume(TokenType.IF_T)
        boolean_expression = self.parse_boolean_expression()
        self.consume(TokenType.THEN)
        statement = self.parse_statement(line_id)
        return IfStatement(line_id=line_id, line_num=if_token.line_num,
                           col_start=if_token.col_start, col_end=statement.col_end,
                           boolean_expr=boolean_expression, then_statement=statement)

    # LET VARIABLE = VALUE
    def parse_let(self, line_id: int) -> LetStatement:
        let_token = self.consume(TokenType.LET)
        variable = self.consume(TokenType.VARIABLE)
        self.consume(TokenType.EQUAL)
        expression = self.parse_numeric_expression()
        return LetStatement(line_id=line_id, line_num=let_token.line_num,
                            col_start=let_token.col_start, col_end=expression.col_end,
                            name=cast(str, variable.associated_value), expr=expression)

    # GOTO NUMERIC_EXPRESSION
    def parse_goto(self, line_id: int) -> GoToStatement:
        goto_token = self.consume(TokenType.GOTO)
        expression = self.parse_numeric_expression()
        return GoToStatement(line_id=line_id, line_num=goto_token.line_num,
                             col_start=goto_token.col_start, col_end=expression.col_end,
                             line_expr=expression)

    # GOSUB NUMERIC_EXPRESSION
    def parse_gosub(self, line_id: int) -> GoSubStatement:
        gosub_token = self.consume(TokenType.GOSUB)
        expression = self.parse_numeric_expression()
        return GoSubStatement(line_id=line_id, line_num=gosub_token.line_num,
                              col_start=gosub_token.col_start, col_end=expression.col_end,
                              line_expr=expression)

    # RETURN
    def parse_return(self, line_id: int) -> ReturnStatement:
        return_token = self.consume(TokenType.RETURN_T)
        return ReturnStatement(line_id=line_id, line_num=return_token.line_num,
                               col_start=return_token.col_start, col_end=return_token.col_end)

    # NUMERIC_EXPRESSION BOOLEAN_OPERATOR NUMERIC_EXPRESSION
    def parse_boolean_expression(self) -> BooleanExpression:
        left = self.parse_numeric_expression()
        if self.current.kind in [TokenType.GREATER, TokenType.GREATER_EQUAL, TokenType.EQUAL,
                                 TokenType.LESS, TokenType.LESS_EQUAL, TokenType.NOT_EQUAL]:
            operator = self.consume(self.current.kind)
            right = self.parse_numeric_expression()
            return BooleanExpression(line_num=left.line_num,
                                     col_start=left.col_start, col_end=right.col_end,
                                     operator=operator.kind, left_expr=left, right_expr=right)
        raise Parser.ParserError(f"Expected boolean operator inside boolean expression but found {self.current.kind}.",
                                 self.current)

    def parse_numeric_expression(self) -> NumericExpression:
        left = self.parse_term()
        # Keep parsing +s and -s until there are no more
        while True:
            if self.out_of_tokens:  # What if expression is end of file?
                return left
            if self.current.kind is TokenType.PLUS:
                self.consume(TokenType.PLUS)
                right = self.parse_term()
                left = BinaryOperation(line_num=left.line_num,
                                       col_start=left.col_start, col_end=right.col_end,
                                       operator=TokenType.PLUS, left_expr=left, right_expr=right)
            elif self.current.kind is TokenType.MINUS:
                self.consume(TokenType.MINUS)
                right = self.parse_term()
                left = BinaryOperation(line_num=left.line_num,
                                       col_start=left.col_start, col_end=right.col_end,
                                       operator=TokenType.MINUS, left_expr=left, right_expr=right)
            else:
                break  # No more, must be end of expression
        return left

    def parse_term(self) -> NumericExpression:
        left = self.parse_factor()
        # Keep parsing *s and /s until there are no more
        while True:
            if self.out_of_tokens:  # What if expression is end of file?
                return left
            if self.current.kind is TokenType.MULTIPLY:
                self.consume(TokenType.MULTIPLY)
                right = self.parse_factor()
                left = BinaryOperation(line_num=left.line_num,
                                       col_start=left.col_start, col_end=right.col_end,
                                       operator=TokenType.MULTIPLY, left_expr=left, right_expr=right)
            elif self.current.kind is TokenType.DIVIDE:
                self.consume(TokenType.DIVIDE)
                right = self.parse_factor()
                left = BinaryOperation(line_num=left.line_num,
                                       col_start=left.col_start, col_end=right.col_end,
                                       operator=TokenType.DIVIDE, left_expr=left, right_expr=right)
            else:
                break  # No more, must be end of expression
        return left

    def parse_factor(self) -> NumericExpression:
        if self.current.kind is TokenType.VARIABLE:
            variable = self.consume(TokenType.VARIABLE)
            return VarRetrieve(line_num=variable.line_num,
                               col_start=variable.col_start, col_end=variable.col_end,
                               name=cast(str, variable.associated_value))
        elif self.current.kind is TokenType.NUMBER:
            number = self.consume(TokenType.NUMBER)
            return NumberLiteral(line_num=number.line_num,
                                 col_start=number.col_start, col_end=number.col_end,
                                 number=int(cast(str, number.associated_value)))
        elif self.current.kind is TokenType.OPEN_PAREN:
            self.consume(TokenType.OPEN_PAREN)
            expression = self.parse_numeric_expression()
            if self.current.kind is not TokenType.CLOSE_PAREN:
                raise Parser.ParserError("Expected matching closing parenthesis.", self.current)
            self.consume(TokenType.CLOSE_PAREN)
            return expression
        elif self.current.kind is TokenType.MINUS:
            minus = self.consume(TokenType.MINUS)
            expression = self.parse_factor()
            return UnaryOperation(line_num=minus.line_num,
                                  col_start=minus.col_start, col_end=expression.col_end,
                                  operator=TokenType.MINUS, expr=expression)
        raise Parser.ParserError("Couldn't parse numeric expression, unexpected token.", self.current)
