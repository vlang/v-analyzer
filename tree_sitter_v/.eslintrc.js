module.exports = {
	env: {
		commonjs: true,
		es2024: true,
	},
	extends: [
		'google',
		'prettier', // Use prettier for formatting, disable potentially conflicting rules.
	],
	overrides: [],
	parserOptions: {
		ecmaVersion: 'latest',
		sourceType: 'module',
	},
};
