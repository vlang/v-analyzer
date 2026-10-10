## Description

`parser` module provides way to parse V code to AST.

Input may be provided in a variety of forms (see the various `parser_*` functions)
Output is an abstract syntax tree (AST) representing the V source.

The parser accepts a larger language than is syntactically permitted by the V spec,
for simplicity, and for improved robustness in the presence of syntax errors.
