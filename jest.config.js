module.exports = {
  // Test environment
  testEnvironment: 'node',
  
  // Test file patterns
  testMatch: [
    '**/tests/unit/**/*.test.js',
    '**/tests/integration/**/*.test.js',
    '**/__tests__/**/*.js',
    '**/?(*.)+(spec|test).js'
  ],
  
  // Ignore E2E tests (they use Playwright)
  testPathIgnorePatterns: [
    '/node_modules/',
    '/tests/e2e/',
    '/.github/'
  ],
  
  // Coverage disabled
  collectCoverage: false,
  
  // Setup files
  setupFilesAfterEnv: [],
  
  // Module directories
  moduleDirectories: ['node_modules'],
  
  // Verbose output
  verbose: true,
  
  // Clear mocks between tests
  clearMocks: true,
  
  // Timeout for tests
  testTimeout: 10000
};
