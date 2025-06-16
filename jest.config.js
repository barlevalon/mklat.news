module.exports = {
  testEnvironment: 'node',
  testMatch: [
    '**/tests/unit/**/*.test.js'
  ],
  collectCoverageFrom: [
    'server.js',
    'public/script.js'
  ],
  coverageDirectory: 'coverage',
  verbose: true
};
