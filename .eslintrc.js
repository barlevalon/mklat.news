module.exports = {
  env: {
    browser: true,
    commonjs: true,
    es2021: true,
    node: true,
    jest: true
  },
  extends: [
    'eslint:recommended'
  ],
  parserOptions: {
    ecmaVersion: 'latest'
  },
  rules: {
    // Temporarily more permissive rules for CI setup
    'no-console': 'off',
    'no-unused-vars': ['warn', { argsIgnorePattern: '^_' }],
    'semi': 'off',
    'quotes': 'off',
    'indent': 'off',
    'no-trailing-spaces': 'off',
    'space-before-function-paren': 'off',
    'quote-props': 'off',
    'comma-dangle': 'off'
  },
  globals: {
    // For Playwright tests
    'page': 'readonly',
    'browser': 'readonly',
    'context': 'readonly',
    // For browser globals in client-side code
    'WebSocket': 'readonly',
    'localStorage': 'readonly'
  },
  overrides: [
    {
      files: ['tests/**/*.js', '**/*.spec.js', '**/*.test.js'],
      env: {
        jest: true
      },
      globals: {
        'test': 'readonly',
        'expect': 'readonly',
        'describe': 'readonly',
        'beforeEach': 'readonly',
        'afterEach': 'readonly',
        'beforeAll': 'readonly',
        'afterAll': 'readonly',
        'jest': 'readonly'
      }
    },
    {
      files: ['public/**/*.js'],
      env: {
        browser: true,
        node: false
      },
      globals: {
        'document': 'readonly',
        'window': 'readonly',
        'fetch': 'readonly',
        'WebSocket': 'readonly',
        'localStorage': 'readonly'
      }
    },
    {
      files: ['tests/unit/**/*.js'],
      globals: {
        // Client-side functions being tested
        'updateSelectedLocationsDisplay': 'readonly',
        'saveUserPreferences': 'readonly',
        'loadUserPreferences': 'readonly',
        'filterAlertsByLocation': 'readonly',
        'toggleLocation': 'readonly'
      }
    }
  ]
};
