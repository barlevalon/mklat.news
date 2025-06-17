const { DEFAULT_USER_AGENT, DEFAULT_TIMEOUT } = require('../config/constants');

// Common axios config generator
function createAxiosConfig(timeout = DEFAULT_TIMEOUT, headers = {}) {
  return {
    timeout,
    headers: {
      'User-Agent': DEFAULT_USER_AGENT,
      ...headers
    }
  };
}

module.exports = {
  createAxiosConfig
};
