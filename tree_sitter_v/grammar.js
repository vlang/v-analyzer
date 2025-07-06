/**
 * @file V grammar for tree-sitter
 */

/* eslint-disable arrow-parens */
/* eslint-disable camelcase */
/* eslint-disable-next-line spaced-comment */
/// <reference types="tree-sitter-cli/dsl" />

const PREC = {
	attributes: 10,
	match_arm_type: 9,
	type_initializer: 8,
	primary: 7,
	unary: 6,
	multiplicative: 5,
	additive: 4,
	comparative: 3,
	and: 2,
	or: 1,
	resolve: 1,
	composite_literal: -1,
	strictly_expression_list: -2,
};

const multiplicative_operators = ['*', '/', '%', '<<', '>>', '>>>', '&', '&^'];
const additive_operators = ['+', '-', '|', '^'];
const comparative_operators = ['==', '!=', '<', '<=', '>', '>='];
const assignment_operators = multiplicative_operators
	.concat(additive_operators)
	.map((operator) => operator + '=')
	.concat('=');
const unary_operators = ['+', '-', '!', '~', '^', '*', '&'];
const overridable_operators = ['+', '-', '*', '/', '%', '<', '>', '==', '!=', '<=', '>='].map(
	(operator) => token(operator),
);

const terminator = choice('\n', '\r', '\r\n');

const unicode_digit = /[0-9]/;
const unicode_letter = /[a-zA-Zα-ωΑ-Ωµ]/;

const letter = choice(unicode_letter, '_');

const hex_digit = /[0-9a-fA-F]/;
const octal_digit = /[0-7]/;
const decimal_digit = /[0-9]/;
const binary_digit = /[01]/;

const hex_digits = seq(hex_digit, repeat(seq(optional('_'), hex_digit)));
const octal_digits = seq(octal_digit, repeat(seq(optional('_'), octal_digit)));
const decimal_digits = seq(decimal_digit, repeat(seq(optional('_'), decimal_digit)));
const binary_digits = seq(binary_digit, repeat(seq(optional('_'), binary_digit)));

const hex_literal = seq('0', choice('x', 'X'), optional('_'), hex_digits);
const octal_literal = seq('0', optional(choice('o', 'O')), optional('_'), octal_digits);
const decimal_literal = choice('0', seq(/[1-9]/, optional(seq(optional('_'), decimal_digits))));
const binary_literal = seq('0', choice('b', 'B'), optional('_'), binary_digits);

const int_literal = choice(binary_literal, decimal_literal, octal_literal, hex_literal);

const decimal_exponent = seq(choice('e', 'E'), optional(choice('+', '-')), decimal_digits);
const decimal_float_literal = choice(
	seq(decimal_digits, '.', decimal_digits, optional(decimal_exponent)),
	seq(decimal_digits, decimal_exponent),
	seq('.', decimal_digits, optional(decimal_exponent)),
);

const hex_exponent = seq(choice('p', 'P'), optional(choice('+', '-')), decimal_digits);
const hex_mantissa = choice(
	seq(optional('_'), hex_digits, '.', optional(hex_digits)),
	seq(optional('_'), hex_digits),
	seq('.', hex_digits),
);
const hex_float_literal = seq('0', choice('x', 'X'), hex_mantissa, hex_exponent);
const float_literal = choice(decimal_float_literal, hex_float_literal);

const format_flag = token(/[bgGeEfFcdoxXpsS]/);

const semi = choice(terminator, ';');
const list_separator = choice(semi, ',');

module.exports = grammar({
	name: 'v',

	extras: ($) => [/\s/, $.line_comment, $.block_comment],

	word: ($) => $.identifier,

	externals: (_) => [],

	inline: ($) => [$._string_literal, $._top_level_declaration, $._array],

	supertypes: ($) => [
		$._expression,
		$._statement,
		$._top_level_declaration,
		$._expression_with_blocks,
	],

	conflicts: ($) => [
		[$.fixed_array_type, $._expression_without_blocks],
		[$.qualified_type, $._expression_without_blocks],
		[$.fixed_array_type, $.literal],
		[$.reference_expression, $.type_reference_expression],
		[$.is_expression],
		[$._expression_without_blocks, $.element_list],
	],

	rules: {
		source_file: ($) =>
			seq(
				optional($.shebang),
				optional($.module_clause),
				optional($.import_list),
				repeat(
					choice(
						seq($._top_level_declaration, optional(terminator)),
						seq($._statement, optional(terminator)),
					),
				),
			),

		shebang: (_) => seq('#!', /.*/),

		line_comment: (_) => seq('//', /.*/),

		block_comment: (_) =>
			seq(
				'/*',
				repeat(
					choice(
						/\*/,
						regexOr(
							'[^*]', // any symbol except reserved
							'[/][^*]', // start of nested comment
							'[^*][/]', // end of nested comment
						),
					),
				),
				'*/',
			),

		comment: ($) => choice($.line_comment, $.block_comment),

		module_clause: ($) => seq(optional($.attributes), 'module', $.identifier),

		import_list: ($) => repeat1($.import_declaration),

		import_declaration: ($) => seq('import', $.import_spec, semi),

		import_spec: ($) =>
			seq($.import_path, optional($.import_alias), optional($.selective_import_list)),

		// foo.bar.baz
		import_path: ($) => seq($.import_name, repeat(seq('.', $.import_name))),

		// foo
		import_name: ($) => $.identifier,

		// foo as bar
		//     ^^^^^^
		import_alias: ($) => seq('as', $.import_name),

		// { foo, bar }
		selective_import_list: ($) =>
			seq(
				'{',
				$.reference_expression,
				repeat(seq(choice(',', terminator), optional($.reference_expression))),
				'}',
			),

		// ==================== TOP LEVEL DECLARATIONS ====================

		_top_level_declaration: ($) =>
			choice(
				$.const_declaration,
				$.global_var_declaration,
				$.type_declaration,
				$.function_declaration,
				$.static_method_declaration,
				$.struct_declaration,
				$.enum_declaration,
				$.interface_declaration,
			),

		const_declaration: ($) =>
			seq(
				optional(field('attributes', $.attributes)),
				optional($.visibility_modifiers),
				'const',
				choice($.const_definition, seq('(', repeat(seq($.const_definition, semi)), ')')),
			),

		const_definition: ($) => seq(field('name', $.identifier), '=', field('value', $._expression)),

		global_var_declaration: ($) =>
			seq(
				optional(field('attributes', $.attributes)),
				'__global',
				choice($.global_var_definition, seq('(', repeat(seq($.global_var_definition, semi)), ')')),
			),

		global_var_definition: ($) =>
			seq(field('name', $.identifier), choice($.plain_type, $._global_var_value)),

		_global_var_value: ($) => seq('=', field('value', $._expression)),

		type_declaration: ($) =>
			prec.right(
				PREC.resolve,
				seq(
					optional($.visibility_modifiers),
					'type',
					field('name', $.identifier),
					optional(field('generic_parameters', $.generic_parameters)),
					'=',
					field('type', choice($.sum_type, $.plain_type)),
				),
			),

		function_declaration: ($) =>
			prec.right(
				PREC.resolve,
				seq(
					optional(field('attributes', $.attributes)),
					optional($.visibility_modifiers),
					'fn',
					optional(field('receiver', $.receiver)),
					field('name', $._function_name),
					optional(field('generic_parameters', $.generic_parameters)),
					field('signature', $.signature),
					optional(field('body', $.block)),
				),
			),

		static_method_declaration: ($) =>
			prec.right(
				PREC.resolve,
				seq(
					optional(field('attributes', $.attributes)),
					optional($.visibility_modifiers),
					'fn',
					field('static_receiver', $.static_receiver),
					'.',
					field('name', $._function_name),
					optional(field('generic_parameters', $.generic_parameters)),
					field('signature', $.signature),
					optional(field('body', $.block)),
				),
			),

		static_receiver: ($) => $.reference_expression,

		_function_name: ($) => choice($.identifier, $.overridable_operator),

		overridable_operator: () => choice(...overridable_operators),

		receiver: ($) =>
			prec(
				PREC.primary,
				seq(
					'(',
					seq(
						optional(field('mutability', $.mutability_modifiers)),
						field('name', $.identifier),
						field('type', alias($._plain_type_without_special, $.plain_type)),
					),
					')',
				),
			),

		signature: ($) =>
			prec.right(
				seq(
					field('parameters', choice($.parameter_list, $.type_parameter_list)),
					optional(field('result', $.plain_type)),
				),
			),

		parameter_list: ($) =>
			prec(PREC.resolve, seq('(', optional(sep($.parameter_declaration)), ')')),

		parameter_declaration: ($) =>
			seq(
				optional(field('mutability', $.mutability_modifiers)),
				field('name', $.identifier),
				optional(field('variadic', '...')),
				field('type', $.plain_type),
			),

		type_parameter_list: ($) => seq('(', sep($.type_parameter_declaration), ')'),

		type_parameter_declaration: ($) =>
			prec(
				PREC.primary,
				seq(
					optional($.mutability_modifiers),
					optional(field('variadic', '...')),
					field('type', $.plain_type),
				),
			),

		// fn foo[T, T2]() {}
		//       ^^^^^^^
		generic_parameters: ($) =>
			prec(
				PREC.resolve,
				seq(
					choice(token.immediate('['), token.immediate('<')),
					sep($.generic_parameter),
					optional(','),
					choice(']', '>'),
				),
			),

		generic_parameter: ($) => $.identifier,

		struct_declaration: ($) =>
			seq(
				optional(field('attributes', $.attributes)),
				optional($.visibility_modifiers),
				choice('struct', 'union'),
				field('name', $.identifier),
				optional(field('generic_parameters', $.generic_parameters)),
				optional(seq('implements', field('implements', $.implements))),
				$._struct_body,
			),

		implements: ($) =>
			seq(
				choice($.type_reference_expression, $.qualified_type),
				repeat(seq(',', choice($.type_reference_expression, $.qualified_type)))
			),

		_struct_body: ($) =>
			seq(
				'{',
				repeat(
					choice(
						seq($.struct_field_scope, optional(terminator)),
						seq($.struct_field_declaration, optional(terminator)),
					),
				),
				'}',
			),

		// pub:
		// mut:
		// pub mut:
		// __global:
		struct_field_scope: () => seq(choice('pub', 'mut', seq('pub', 'mut'), '__global'), ':'),

		struct_field_declaration: ($) => choice($._struct_field_definition, $.embedded_definition),

		_struct_field_definition: ($) =>
			prec.right(
				PREC.type_initializer,
				seq(
					field('name', $.identifier),
					field('type', $.plain_type),
					optional(seq('=', field('default_value', $._expression))),
					optional(field('attributes', $.attribute)),
				),
			),

		embedded_definition: ($) =>
			choice($.type_reference_expression, $.qualified_type, $.generic_type),

		enum_declaration: ($) =>
			seq(
				optional(field('attributes', $.attributes)),
				optional($.visibility_modifiers),
				'enum',
				field('name', $.identifier),
				optional($.enum_backed_type),
				$._enum_body,
			),

		enum_backed_type: ($) => seq('as', $.plain_type),

		_enum_body: ($) => seq('{', repeat(seq($.enum_field_definition, optional(terminator))), '}'),

		enum_field_definition: ($) =>
			seq(
				field('name', $.identifier),
				optional(seq('=', field('value', $._expression))),
				optional(field('attributes', $.attribute)),
			),

		interface_declaration: ($) =>
			seq(
				optional(field('attributes', $.attributes)),
				optional($.visibility_modifiers),
				'interface',
				field('name', $.identifier),
				optional(field('generic_parameters', $.generic_parameters)),
				$._interface_body,
			),

		_interface_body: ($) =>
			seq(
				'{',
				repeat(
					choice(
						seq($.struct_field_scope, optional(terminator)),
						seq($.struct_field_declaration, optional(terminator)),
						seq($.interface_method_definition, optional(terminator)),
					),
				),
				'}',
			),

		interface_method_definition: ($) =>
			prec.right(
				seq(
					field('name', $.identifier),
					optional(field('generic_parameters', $.generic_parameters)),
					field('signature', $.signature),
					optional(field('attributes', $.attribute)),
				),
			),

		// ==================== EXPRESSIONS ====================

		_expression: ($) => choice($._expression_without_blocks, $._expression_with_blocks),

		_expression_without_blocks: ($) =>
			choice(
				$.parenthesized_expression,
				$.go_expression,
				$.spawn_expression,
				$.call_expression,
				$.function_literal,
				$.reference_expression,
				$._max_group,
				$.array_creation,
				$.fixed_array_creation,
				$.unary_expression,
				$.receive_expression,
				$.binary_expression,
				$.is_expression,
				$.in_expression,
				$.index_expression,
				$.slice_expression,
				$.as_type_cast_expression,
				$.selector_expression,
				$.enum_fetch,
				$.inc_expression,
				$.dec_expression,
				$.or_block_expression,
				$.option_propagation_expression,
				$.result_propagation_expression,
			),

		_expression_with_blocks: ($) =>
			choice(
				$.type_initializer,
				$.anon_struct_value_expression,
				$.if_expression,
				$.match_expression,
				$.select_expression,
				$.sql_expression,
				$.lock_expression,
				$.unsafe_expression,
				$.compile_time_if_expression,
				$.map_init_expression,
			),

		strictly_expression_list: ($) =>
			prec(
				PREC.strictly_expression_list,
				seq(
					choice($._expression, $.mutable_expression),
					',',
					sep(choice($._expression, $.mutable_expression)),
				),
			),

		inc_expression: ($) => seq($._expression, '++'),

		dec_expression: ($) => seq($._expression, '--'),

		or_block_expression: ($) => seq($._expression, $.or_block),

		option_propagation_expression: ($) => prec(PREC.match_arm_type, seq($._expression, '?')),

		result_propagation_expression: ($) => prec(PREC.match_arm_type, seq($._expression, '!')),

		anon_struct_value_expression: ($) =>
			seq(
				'struct',
				'{',
				choice(
					field('element_list', $.element_list),
					// For short struct init syntax
					field('short_element_list', $.short_element_list),
				),
				'}',
			),

		go_expression: ($) => prec.left(PREC.composite_literal, seq('go', $._expression)),

		spawn_expression: ($) => prec.left(PREC.composite_literal, seq('spawn', $._expression)),

		parenthesized_expression: ($) => seq('(', field('expression', $._expression), ')'),

		call_expression: ($) =>
			prec.right(
				PREC.primary,
				choice(
					seq(field('function', token('json.decode')), field('arguments', $.special_argument_list)),
					seq(
						field('name', $._expression),
						optional(field('type_parameters', $.type_parameters)),
						field('arguments', $.argument_list),
					),
				),
			),

		type_parameters: ($) => prec.dynamic(2, seq(token.immediate('['), sep($.plain_type), ']')),

		argument_list: ($) =>
			seq('(', choice(repeat(seq($.argument, optional(list_separator))), $.short_lambda), ')'),

		short_lambda: ($) =>
			seq('|', optional(sep($.reference_expression)), '|', $._expression_without_blocks),

		argument: ($) =>
			choice($._expression, $.mutable_expression, $.keyed_element, $.spread_expression),

		special_argument_list: ($) =>
			seq(
				'(',
				alias($._plain_type_without_special, $.plain_type),
				optional(seq(',', $._expression)),
				')',
			),

		type_initializer: ($) =>
			prec.right(
				PREC.type_initializer,
				seq(field('type', $.plain_type), field('body', $.type_initializer_body)),
			),

		type_initializer_body: ($) =>
			seq(
				'{',
				optional(
					choice(
						field('element_list', $.element_list),
						// For short struct init syntax
						field('short_element_list', $.short_element_list),
					),
				),
				'}',
			),

		element_list: ($) =>
			repeat1(
				seq(
					choice($.spread_expression, $.keyed_element, $.reference_expression),
					optional(list_separator),
				),
			),

		short_element_list: ($) =>
			repeat1(seq(alias($._expression, $.element), optional(list_separator))),

		field_name: ($) =>
			$.reference_expression,

		keyed_element: ($) =>
			seq(
				field('key', $.field_name),
				':',
				field('value', $._expression),
			),

		function_literal: ($) =>
			prec.right(
				seq(
					'fn',
					optional(field('capture_list', $.capture_list)),
					optional(field('generic_parameters', $.generic_parameters)),
					field('signature', $.signature),
					field('body', $.block),
				),
			),

		capture_list: ($) => seq('[', sep($.capture), optional(','), ']'),

		capture: ($) => seq(optional($.mutability_modifiers), $.reference_expression),

		reference_expression: ($) => prec.left($.identifier),
		type_reference_expression: ($) => prec.left($.identifier),

		unary_expression: ($) =>
			prec(
				PREC.unary,
				seq(field('operator', choice(...unary_operators)), field('operand', $._expression)),
			),

		receive_expression: ($) =>
			prec.right(PREC.unary, seq(field('operator', '<-'), field('operand', $._expression))),

		binary_expression: ($) => {
			const table = [
				[PREC.multiplicative, choice(...multiplicative_operators)],
				[PREC.additive, choice(...additive_operators)],
				[PREC.comparative, choice(...comparative_operators)],
				[PREC.and, '&&'],
				[PREC.or, '||'],
			];

			return choice(
				...table.map(([precedence, operator]) =>
					prec.left(
						Number(precedence),
						seq(
							field('left', $._expression),
							// @ts-ignore
							field('operator', operator),
							field('right', $._expression),
						),
					),
				),
			);
		},

		as_type_cast_expression: ($) => seq($._expression, 'as', $.plain_type),

		or_block: ($) => seq('or', field('block', $.block)),

		_max_group: ($) => prec.left(PREC.resolve, choice($.pseudo_compile_time_identifier, $.literal)),

		escape_sequence: () =>
			token(
				prec(
					1,
					seq(
						'\\',
						choice(
							/u[a-fA-F\d]{4}/,
							/U[a-fA-F\d]{8}/,
							/x[a-fA-F\d]{2}/,
							/\d{3}/,
							/\r?\n/,
							/['"abfrntv$\\]/,
							/\S/,
						),
					),
				),
			),

		literal: ($) =>
			choice(
				$.int_literal,
				$.float_literal,
				$._string_literal,
				$.rune_literal,
				$.none,
				$.true,
				$.false,
				$.nil,
			),

		none: () => 'none',
		true: () => 'true',
		false: () => 'false',
		nil: () => 'nil',

		spread_expression: ($) => prec.right(PREC.unary, seq('...', $._expression)),

		map_init_expression: ($) =>
			prec(
				PREC.composite_literal,
				seq('{', repeat(seq($.map_keyed_element, optional(list_separator))), '}'),
			),

		map_keyed_element: ($) => seq(field('key', $._expression), ':', field('value', $._expression)),

		array_creation: ($) => prec.right(PREC.multiplicative, $._array),

		fixed_array_creation: ($) => prec.right(PREC.multiplicative, seq($._array, '!')),

		_array: ($) => seq('[', repeat(seq($._expression, optional(','))), ']'),

		selector_expression: ($) =>
			prec.dynamic(
				-1,
				prec(
					PREC.primary,
					seq(
						field('operand', $._expression),
						choice('.', '?.'),
						field('field', choice($.reference_expression, $.compile_time_selector_expression)),
					),
				),
			),

		compile_time_selector_expression: ($) =>
			seq(
				token.immediate('$('),
				field('field', choice($.reference_expression, $.selector_expression)),
				')',
			),

		index_expression: ($) =>
			prec.dynamic(
				-1,
				prec.right(
					PREC.primary,
					seq(
						field('operand', $._expression),
						choice('[', token.immediate('['), token('#[')),
						field('index', $._expression),
						']',
					),
				),
			),

		slice_expression: ($) =>
			prec(
				PREC.primary,
				seq(
					field('operand', $._expression),
					choice('[', token.immediate('['), token('#[')),
					$.range,
					']',
				),
			),

		if_expression: ($) =>
			seq(
				'if',
				choice(field('condition', $._expression), field('guard', $.var_declaration)),
				field('block', $.block),
				optional($.else_branch),
			),

		else_branch: ($) =>
			seq('else', field('else_branch', choice(field('block', $.block), $.if_expression))),

		compile_time_if_expression: ($) =>
			seq(
				'$if',
				field('condition', seq($._expression, optional('?'))),
				field('block', $.block),
				optional(seq('$else', field('else_branch', choice($.block, $.compile_time_if_expression)))),
			),

		is_expression: ($) =>
			prec.dynamic(
				2,
				seq(
					field('left', seq(optional($.mutability_modifiers), $._expression)),
					choice('is', '!is'),
					field('right', $.plain_type),
				),
			),

		in_expression: ($) =>
			prec.left(
				PREC.comparative,
				seq(field('left', $._expression), choice('in', '!in'), field('right', $._expression)),
			),

		enum_fetch: ($) => prec.dynamic(-1, seq('.', $.reference_expression)),

		match_expression: ($) =>
			seq(
				'match',
				field('condition', choice($._expression, $.mutable_expression)),
				'{',
				optional($.match_arms),
				'}',
			),

		match_arms: ($) => repeat1(choice($.match_arm, $.match_else_arm_clause)),

		match_arm: ($) => seq(field('value', $.match_expression_list), field('block', $.block)),

		match_expression_list: ($) =>
			sep(
				choice($._expression_without_blocks, $.match_arm_type, alias($._definite_range, $.range)),
			),

		match_arm_type: ($) => prec(PREC.match_arm_type, $.plain_type),

		match_else_arm_clause: ($) => seq('else', field('block', $.block)),

		select_expression: ($) =>
			seq(
				'select',
				optional(field('selected_variables', $.expression_list)),
				'{',
				repeat($.select_arm),
				optional($.select_else_arn_clause),
				'}',
			),

		select_arm: ($) => seq($.select_arm_statement, $.block),

		select_arm_statement: ($) =>
			prec.left(
				choice(
					alias($.select_var_declaration, $.var_declaration),
					$.send_statement,
					seq(
						alias($.expression_without_blocks_list, $.expression_list),
						optional($._select_arm_assignment_statement),
					),
				),
			),

		_select_arm_assignment_statement: ($) =>
			seq(
				choice(...assignment_operators),
				alias($.expression_without_blocks_list, $.expression_list),
			),

		select_var_declaration: ($) =>
			prec.left(
				seq(
					field('var_list', $.identifier_list),
					':=',
					field('expression_list', alias($.expression_without_blocks_list, $.expression_list)),
				),
			),

		select_else_arn_clause: ($) => seq('else', $.block),

		lock_expression: ($) =>
			seq(
				choice('lock', 'rlock'),
				optional(field('locked_variables', $.expression_list)),
				field('body', $.block),
			),

		unsafe_expression: ($) => seq('unsafe', $.block),

		// TODO: this should be put into a separate grammar to avoid any "noise"
		sql_expression: ($) => prec(PREC.resolve, seq('sql', optional($.identifier), $._content_block)),

		// ==================== LITERALS ====================

		int_literal: () => token(int_literal),

		float_literal: () => token(float_literal),

		rune_literal: () =>
			token(
				seq(
					'`',
					choice(
						/[^'\\]/,
						"'",
						'"',
						seq(
							'\\',
							choice(
								'0',
								'`',
								seq('x', hex_digit, hex_digit),
								seq(octal_digit, octal_digit, octal_digit),
								seq('u', hex_digit, hex_digit, hex_digit, hex_digit),
								seq(
									'U',
									hex_digit,
									hex_digit,
									hex_digit,
									hex_digit,
									hex_digit,
									hex_digit,
									hex_digit,
									hex_digit,
								),
								seq(choice('a', 'b', 'e', 'f', 'n', 'r', 't', 'v', '\\', "'", '"')),
							),
						),
					),
					'`',
				),
			),

		_string_literal: ($) =>
			choice($.interpreted_string_literal, $.c_string_literal, $.raw_string_literal),

		interpreted_string_literal: ($) =>
			choice(
				seq("'", repeat(stringBody(/[^'\\$]+/, $)), "'"),
				seq('"', repeat(stringBody(/[^"\\$]+/, $)), '"'),
			),

		c_string_literal: ($) =>
			choice(
				seq("c'", repeat(stringBody(/[^'\\$]+/, $)), "'"),
				seq('c"', repeat(stringBody(/[^"\\$]+/, $)), '"'),
			),

		raw_string_literal: (_) =>
			choice(
				seq("r'", repeat(token.immediate(prec.right(1, /[^']+/))), "'"),
				seq('r"', repeat(token.immediate(prec.right(1, /[^"]+/))), '"'),
			),

		string_interpolation: ($) =>
			seq(
				alias('${', $.interpolation_opening),
				choice(
					repeat(alias($._expression, $.interpolation_expression)),
					seq(alias($._expression, $.interpolation_expression), $.format_specifier),
				),
				alias('}', $.interpolation_closing),
			),

		format_specifier: ($) =>
			seq(
				token(':'),
				choice(
					format_flag,
					seq(
						optional(choice(token(/[+\-]/), token('0'))),
						optional($.int_literal),
						optional(seq('.', $.int_literal)),
						optional(format_flag),
					),
				),
			),

		pseudo_compile_time_identifier: ($) =>
			token(seq('@', alias(token.immediate(/[A-Z][A-Z0-9_]+/), $.identifier))),

		identifier: () =>
			token(
				seq(
					optional('@'),
					optional('$'),
					optional('C.'),
					optional('JS.'),
					choice(unicode_letter, '_'),
					repeat(choice(letter, unicode_digit)),
				),
			),

		visibility_modifiers: () => prec.left(choice('pub', '__global')),

		mutability_modifiers: () =>
			prec.left(
				PREC.resolve,
				choice(seq('mut', optional('static'), optional('volatile')), 'shared'),
			),

		mutable_identifier: ($) => prec(PREC.resolve, seq($.mutability_modifiers, $.identifier)),

		mutable_expression: ($) => prec(PREC.resolve, seq($.mutability_modifiers, $._expression)),

		identifier_list: ($) => prec(PREC.and, sep(choice($.mutable_identifier, $.identifier))),

		expression_list: ($) => prec(PREC.resolve, sep(choice($._expression, $.mutable_expression))),

		expression_without_blocks_list: ($) => prec(PREC.resolve, sep($._expression_without_blocks)),

		// ==================== TYPES ====================

		// int | string | Foo
		sum_type: ($) =>
			prec.right(
				seq($.plain_type, repeat1(seq(optional(/\s+/), token.immediate('|'), $.plain_type))),
			),

		plain_type: ($) =>
			prec.right(
				PREC.primary,
				choice($._plain_type_without_special, $.option_type, $.result_type, $.multi_return_type),
			),

		_plain_type_without_special: ($) =>
			prec.right(
				PREC.primary,
				choice(
					$.type_reference_expression,
					$.qualified_type,
					$.pointer_type,
					$.wrong_pointer_type,
					$.array_type,
					$.fixed_array_type,
					$.function_type,
					$.generic_type,
					$.map_type,
					$.channel_type,
					$.shared_type,
					$.thread_type,
					$.atomic_type,
					$.anon_struct_type,
				),
			),

		anon_struct_type: ($) => seq('struct', $._struct_body),

		multi_return_type: ($) => seq('(', sep($.plain_type), optional(','), ')'),

		result_type: ($) => prec.right(seq('!', optional($.plain_type))),

		option_type: ($) => prec.right(seq('?', optional($.plain_type))),

		qualified_type: ($) =>
			seq(field('module', $.reference_expression), '.', field('name', $.type_reference_expression)),

		fixed_array_type: ($) =>
			seq(
				'[',
				field('size', choice($.int_literal, $.reference_expression, $.selector_expression)),
				']',
				field('element', $.plain_type),
			),

		array_type: ($) => prec.right(PREC.primary, seq('[', ']', field('element', $.plain_type))),

		pointer_type: ($) => prec(PREC.match_arm_type, seq('&', $.plain_type)),

		// In languages like Go, pointers use an asterisk, not an ampersand,
		// so this rule is needed to properly parse and then give an error to the user.
		wrong_pointer_type: ($) => prec(PREC.match_arm_type, seq('*', $.plain_type)),

		map_type: ($) => seq('map[', field('key', $.plain_type), ']', field('value', $.plain_type)),

		channel_type: ($) => prec.right(PREC.primary, seq('chan', $.plain_type)),

		shared_type: ($) => seq('shared', $.plain_type),

		thread_type: ($) => seq('thread', $.plain_type),

		atomic_type: ($) => seq('atomic', $.plain_type),

		generic_type: ($) =>
			seq(choice($.qualified_type, $.type_reference_expression), $.type_parameters),

		function_type: ($) => prec.right(seq('fn', field('signature', $.signature))),

		// ==================== TYPES END ====================

		// ==================== STATEMENTS ====================

		_statement: ($) =>
			choice(
				$.simple_statement,
				$.assert_statement,
				$.continue_statement,
				$.break_statement,
				$.return_statement,
				$.asm_statement,
				$.goto_statement,
				$.labeled_statement,
				$.defer_statement,
				$.for_statement,
				$.compile_time_for_statement,
				$.send_statement,
				$.block,
				$.hash_statement,
				$.append_statement,
			),

		simple_statement: ($) =>
			choice(
				$.var_declaration,
				$._expression,
				$.assignment_statement,
				alias($.strictly_expression_list, $.expression_list),
			),

		assert_statement: ($) =>
			prec.left(seq('assert', $._expression, optional(seq(',', $._expression)))),

		append_statement: ($) =>
			prec(PREC.unary, seq(field('left', $._expression), '<<', field('right', $._expression))),

		send_statement: ($) =>
			prec.right(
				PREC.primary,
				seq(field('channel', $._expression), '<-', field('value', $._expression)),
			),

		var_declaration: ($) =>
			prec.right(
				seq(
					field('var_list', $.expression_list),
					':=',
					field('expression_list', $.expression_list),
				),
			),

		var_definition_list: ($) => sep($.var_definition),

		var_definition: ($) =>
			prec(
				PREC.type_initializer,
				seq(optional(field('modifiers', 'mut')), field('name', $.identifier)),
			),

		assignment_statement: ($) =>
			seq(
				field('left', $.expression_list),
				field('operator', choice(...assignment_operators)),
				field('right', $.expression_list),
			),

		block: ($) => seq('{', repeat(seq($._statement, optional(semi))), '}'),

		defer_statement: ($) => seq('defer', $.block),

		label_reference: ($) => $.identifier,

		goto_statement: ($) => seq('goto', $.label_reference),

		break_statement: ($) => prec.right(seq('break', optional($.label_reference))),

		continue_statement: ($) => prec.right(seq('continue', optional($.label_reference))),

		return_statement: ($) =>
			prec.right(seq('return', optional(field('expression_list', $.expression_list)))),

		label_definition: ($) => seq($.identifier, ':'),

		labeled_statement: ($) => prec.right(seq($.label_definition, optional($._statement))),

		compile_time_for_statement: ($) => seq('$for', $.range_clause, field('body', $.block)),

		for_statement: ($) =>
			seq(
				'for',
				optional(choice($.range_clause, $.for_clause, $.is_clause, $._expression)),
				field('body', $.block),
			),

		is_clause: ($) =>
			prec(PREC.primary, seq(optional(alias('mut', $.mutability_modifiers)), $.is_expression)),

		range_clause: ($) =>
			prec.left(
				PREC.primary,
				seq(
					field('left', $.var_definition_list),
					'in',
					field('right', choice(alias($._definite_range, $.range), $._expression)),
				),
			),

		for_clause: ($) =>
			prec.left(
				seq(
					optional(field('initializer', $.simple_statement)),
					';',
					optional(field('condition', $._expression)),
					';',
					optional(field('update', $.simple_statement)),
				),
			),

		_definite_range: ($) =>
			prec(
				PREC.multiplicative,
				seq(
					field('start', $._expression),
					field('operator', choice('..', '...')),
					field('end', $._expression),
				),
			),

		range: ($) =>
			prec(
				PREC.multiplicative,
				seq(
					optional(field('start', $._expression)),
					field('operator', '..'),
					optional(field('end', $._expression)),
				),
			),

		hash_statement: () => seq('#', token.immediate(repeat1(/[^\\\r\n]/))),

		asm_statement: ($) => seq('asm', $.identifier, $._content_block),

		// Loose checking for asm and sql statements
		_content_block: () => seq('{', token.immediate(prec(1, /[^{}]+/)), '}'),

		// ==================== ATTRIBUTES ====================

		attributes: ($) => repeat1(seq($.attribute, optional(terminator))),

		attribute: ($) =>
			seq(
				choice('[', '@['),
				seq($.attribute_expression, repeat(seq(';', $.attribute_expression))),
				']',
			),

		attribute_expression: ($) => prec(PREC.attributes, choice($.if_attribute, $._plain_attribute)),

		// [if some ?]
		// @[if some ?]
		if_attribute: ($) => prec(PREC.attributes, seq('if', $.reference_expression, optional('?'))),

		_plain_attribute: ($) => choice($.literal_attribute, $.value_attribute, $.key_value_attribute),

		// ['/query']
		// @['/query']
		literal_attribute: ($) => prec(PREC.attributes, $.literal),

		value_attribute: ($) =>
			prec(
				PREC.attributes,
				field('name', choice(alias('unsafe', $.reference_expression), $.reference_expression)),
			),

		// [key]
		// [key: value]
		// @[key]
		// @[key: value]
		key_value_attribute: ($) =>
			prec(
				PREC.attributes,
				seq($.value_attribute, ':', field('value', choice($.literal, $.identifier))),
			),
	},
});

/**
 * Creates a comma separated rule sequence to match one or more of the passed rule.
 *
 * @param {RuleOrLiteral} rule
 *
 * @return {SeqRule}
 *
 */
function sep(rule) {
	return seq(rule, repeat(seq(',', rule)));
}

/**
 *
 * @param {RegExp} re
 * @param {$} $
 *
 * @return {SeqRule}
 *
 */
function stringBody(re, $) {
	return choice(token.immediate(prec.right(1, re)), '$', $.escape_sequence, $.string_interpolation);
}

/**
 * @param {...string} args - One or more regular expression patterns.
 *
 * @return {PatternRule}
 */
function regexOr(...args) {
	const regex = args.length > 1 ? args.join('|') : args[0];
	return {
		type: 'PATTERN',
		value: regex,
	};
}
