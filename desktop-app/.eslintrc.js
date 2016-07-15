module.exports = {
  'env': {
    'es6': true,
    'node': true
  },
  'parserOptions': {
    'sourceType': 'module'
  },
  'plugins': [
    'import'
  ],
  'rules': {
    /* errors */
    'constructor-super': ['error'],
    'no-array-constructor': ['error'],
    'no-class-assign': ['error'],
    'no-dupe-args': ['error'],
    'no-dupe-class-members': ['error'],
    'no-delete-var': ['error'],
    'no-invalid-regexp': ['error'],
    'no-irregular-whitespace': ['error'],
    'no-const-assign': ['error'],
    'no-eval': ['error'],
    'no-obj-calls': ['error'],
    'no-new-object': ['error'],
    'no-new-symbol': ['error'],
    'no-redeclare': ['error'],
    'no-this-before-super': ['error'],
    'no-undef': ['error'],
    'no-use-before-define': ['error', { 'functions': true, 'classes': true }],
    'no-var': ['error'],
    'no-with': ['error'],
    'valid-typeof': ['error'],
    'import/no-amd': ['error'],
    'import/no-commonjs': ['error'],
    'import/no-duplicates': ['error'],
    'import/no-named-as-default': ['error'],
    /* good-practices */
    'eqeqeq': ['warn', 'allow-null'],
    'no-cond-assign': ['warn', 'except-parens'],
    'no-duplicate-case': ['warn'],
    'no-extra-parens': ['warn'],
    'no-extra-semi': ['warn'],
    'no-func-assign': ['warn'],
    'no-negated-in-lhs': ['warn'],
    'no-self-assign': ['warn'],
    'no-unused-vars': ['warn'],
    'no-useless-call': ['warn'],
    'object-shorthand': ['warn'],
    'prefer-rest-params': ['warn'],
    'prefer-spread': ['warn'],
    'use-isnan': ['warn'],
    'import/no-named-as-default-member': ['warn'],
    /* coding style */
    'brace-style': ['warn', 'stroustrup'],
    'camelcase': ['warn', {'properties': 'always'}],
    'func-style': ['warn', 'expression', {'allowArrowFunctions': true}],
    'indent': ['warn', 2],
    'no-mixed-spaces-and-tabs': ['error', 'smart-tabs'],
    'no-spaced-func': ['warn'],
    'object-curly-spacing': ['error', 'never'],
    'quotes': ['warn', 'single'],
    'semi': ['warn', 'never'],
    'template-curly-spacing': ['warn','never']
  }
};
