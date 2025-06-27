import { jest } from '@jest/globals';
import { WebSocket } from 'ws';
import { createWebSocketHandler } from '../../src/websocket/websocket.handler.js';

jest.mock('ws');

describe('WebSocket Handler - Client-Aware Polling', () => {
  let mockAlertProvider;
  let mockNewsProvider;
  let handler;
  let mockWs;

  beforeEach(() => {
    jest.clearAllMocks();
    jest.useFakeTimers();
    
    mockAlertProvider = {
      fetchActiveAlerts: jest.fn().mockResolvedValue([]),
      fetchHistoricalAlerts: jest.fn().mockResolvedValue([]),
      fetchAlertAreas: jest.fn().mockResolvedValue([])
    };
    
    mockNewsProvider = {
      fetchNews: jest.fn().mockResolvedValue([])
    };
    
    handler = createWebSocketHandler({
      alertProvider: mockAlertProvider,
      newsProvider: mockNewsProvider
    });
    
    mockWs = {
      readyState: WebSocket.OPEN,
      send: jest.fn(),
      on: jest.fn()
    };
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  test('should not poll when no clients are connected', () => {
    jest.advanceTimersByTime(10000);
    
    expect(mockAlertProvider.fetchActiveAlerts).not.toHaveBeenCalled();
    expect(mockNewsProvider.fetchNews).not.toHaveBeenCalled();
  });

  test('should start polling when first client connects', async () => {
    handler.handleConnection(mockWs);
    
    // Wait for initial data to be sent
    await Promise.resolve();
    
    // Reset mocks after initial data fetch
    mockAlertProvider.fetchActiveAlerts.mockClear();
    mockNewsProvider.fetchNews.mockClear();
    
    jest.advanceTimersByTime(2000);
    
    expect(mockAlertProvider.fetchActiveAlerts).toHaveBeenCalledTimes(1);
    expect(mockNewsProvider.fetchNews).toHaveBeenCalledTimes(1);
  });

  test('should continue polling with multiple clients', async () => {
    const mockWs2 = {
      readyState: WebSocket.OPEN,
      send: jest.fn(),
      on: jest.fn()
    };
    
    handler.handleConnection(mockWs);
    handler.handleConnection(mockWs2);
    
    // Wait for initial data to be sent
    await Promise.resolve();
    
    // Reset mocks after initial data fetch
    mockAlertProvider.fetchActiveAlerts.mockClear();
    mockNewsProvider.fetchNews.mockClear();
    
    jest.advanceTimersByTime(4000);
    
    expect(mockAlertProvider.fetchActiveAlerts).toHaveBeenCalledTimes(2);
    expect(mockNewsProvider.fetchNews).toHaveBeenCalledTimes(2);
  });

  test('should stop polling when last client disconnects', async () => {
    handler.handleConnection(mockWs);
    
    // Wait for initial data to be sent
    await Promise.resolve();
    
    // Reset mocks after initial data fetch
    mockAlertProvider.fetchActiveAlerts.mockClear();
    mockNewsProvider.fetchNews.mockClear();
    
    jest.advanceTimersByTime(2000);
    expect(mockAlertProvider.fetchActiveAlerts).toHaveBeenCalledTimes(1);
    
    const closeHandler = mockWs.on.mock.calls.find(call => call[0] === 'close')[1];
    closeHandler();
    
    jest.advanceTimersByTime(4000);
    expect(mockAlertProvider.fetchActiveAlerts).toHaveBeenCalledTimes(1);
  });

  test('should restart polling when client reconnects', async () => {
    handler.handleConnection(mockWs);
    
    // Wait for initial data to be sent
    await Promise.resolve();
    
    // Reset mocks after initial data fetch
    mockAlertProvider.fetchActiveAlerts.mockClear();
    
    jest.advanceTimersByTime(2000);
    
    const closeHandler = mockWs.on.mock.calls.find(call => call[0] === 'close')[1];
    closeHandler();
    
    const mockWs2 = {
      readyState: WebSocket.OPEN,
      send: jest.fn(),
      on: jest.fn()
    };
    
    handler.handleConnection(mockWs2);
    
    // Wait for initial data to be sent
    await Promise.resolve();
    
    // Reset mocks after initial data fetch
    mockAlertProvider.fetchActiveAlerts.mockClear();
    
    jest.advanceTimersByTime(2000);
    
    expect(mockAlertProvider.fetchActiveAlerts).toHaveBeenCalledTimes(1);
  });

  test('should handle client disconnect via error', async () => {
    // Mock console.error only for this specific test
    const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
    
    handler.handleConnection(mockWs);
    
    // Wait for initial data to be sent
    await Promise.resolve();
    
    // Reset mocks after initial data fetch
    mockAlertProvider.fetchActiveAlerts.mockClear();
    mockNewsProvider.fetchNews.mockClear();
    
    jest.advanceTimersByTime(2000);
    expect(mockAlertProvider.fetchActiveAlerts).toHaveBeenCalledTimes(1);
    
    const errorHandler = mockWs.on.mock.calls.find(call => call[0] === 'error')[1];
    errorHandler(new Error('Connection lost'));
    
    // Verify error was logged (but suppressed in output)
    expect(consoleErrorSpy).toHaveBeenCalledWith('WebSocket error:', expect.any(Error));
    
    jest.advanceTimersByTime(4000);
    expect(mockAlertProvider.fetchActiveAlerts).toHaveBeenCalledTimes(1);
    
    // Restore console.error
    consoleErrorSpy.mockRestore();
  });
});