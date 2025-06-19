// filepath: /c:/Users/USER/Desktop/MultiVendorPlatform/digizone-backend/.eslintrc.js
module.exports = {
  parser: '@typescript-eslint/parser',
  parserOptions: {
    project: 'tsconfig.json',
    tsconfigRootDir: __dirname,
    sourceType: 'module',
  },
  plugins: ['@typescript-eslint/eslint-plugin'],
  extends: [
    'plugin:@typescript-eslint/recommended',
    'plugin:prettier/recommended',
  ],
  root: true,
  env: {
    node: true,
    jest: true,
  },
  ignorePatterns: ['.eslintrc.js'],
  rules: {
    '@typescript-eslint/interface-name-prefix': 'off',
    '@typescript-eslint/explicit-function-return-type': 'off',
    '@typescript-eslint/explicit-module-boundary-types': 'off',
    '@typescript-eslint/no-explicit-any': 'off', // Disable the rule for `any` type
    '@typescript-eslint/no-unused-vars': [
      'warn', // Change to 'warn' to avoid build failure
      { argsIgnorePattern: '^_' }, // Ignore unused variables that start with `_`
    ],
    'prettier/prettier': [
      'error',
      {
        endOfLine: 'auto', // This will fix line ending issues
        singleQuote: true,
        trailingComma: 'all',
        semi: true,
        printWidth: 100,
        tabWidth: 2,
      },
    ],
    'linebreak-style': 'off', // Turn off linebreak style rule
    'eol-last': 'off', // Turn off requirement for last line
  },
};