import { DEFAULT_USER_AGENT, DEFAULT_TIMEOUT } from '../config/constants.js';

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

export {
  createAxiosConfig
};
