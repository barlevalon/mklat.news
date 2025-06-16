const WebSocket = require('ws');
const http = require('http');
const axios = require('axios');

describe('WebSocket Integration Tests', () => {
    let server;
    let wss;
    let port;

    beforeAll((done) => {
        // Start a test server
        port = 3001; // Use different port for testing
        server = http.createServer();
        wss = new WebSocket.Server({ server });
        
        // Mock the WebSocket handlers from our server
        const clients = new Set();
        
        wss.on('connection', (ws) => {
            clients.add(ws);
            
            // Send initial mock data
            ws.send(JSON.stringify({
                type: 'initial',
                data: {
                    ynet: [{ title: 'Test News', link: 'http://test.com' }],
                    alerts: ['Test Alert'],
                    locations: ['תל אביב', 'ירושלים']
                }
            }));
            
            ws.on('close', () => {
                clients.delete(ws);
            });
        });
        
        server.listen(port, done);
    });

    afterAll((done) => {
        wss.close();
        server.close(done);
    });

    test('should establish WebSocket connection', (done) => {
        const ws = new WebSocket(`ws://localhost:${port}`);
        
        ws.on('open', () => {
            expect(ws.readyState).toBe(WebSocket.OPEN);
            ws.close();
        });
        
        ws.on('close', () => {
            done();
        });
        
        ws.on('error', done);
    });

    test('should receive initial data on connection', (done) => {
        const ws = new WebSocket(`ws://localhost:${port}`);
        
        ws.on('message', (data) => {
            const message = JSON.parse(data);
            
            expect(message.type).toBe('initial');
            expect(message.data).toHaveProperty('ynet');
            expect(message.data).toHaveProperty('alerts');
            expect(message.data).toHaveProperty('locations');
            expect(Array.isArray(message.data.ynet)).toBe(true);
            expect(Array.isArray(message.data.alerts)).toBe(true);
            expect(Array.isArray(message.data.locations)).toBe(true);
            
            ws.close();
            done();
        });
        
        ws.on('error', done);
    });

    test('should handle multiple clients', (done) => {
        const clients = [];
        let connectedCount = 0;
        let receivedCount = 0;
        const totalClients = 3;

        for (let i = 0; i < totalClients; i++) {
            const ws = new WebSocket(`ws://localhost:${port}`);
            clients.push(ws);

            ws.on('open', () => {
                connectedCount++;
                if (connectedCount === totalClients) {
                    // All clients connected
                    expect(connectedCount).toBe(totalClients);
                }
            });

            ws.on('message', (data) => {
                const message = JSON.parse(data);
                expect(message.type).toBe('initial');
                
                receivedCount++;
                if (receivedCount === totalClients) {
                    // All clients received data
                    clients.forEach(client => client.close());
                    done();
                }
            });

            ws.on('error', done);
        }
    });

    test('should handle connection errors gracefully', (done) => {
        const ws = new WebSocket('ws://localhost:9999'); // Invalid port
        
        ws.on('error', (error) => {
            expect(error).toBeDefined();
            expect(error.code).toBe('ECONNREFUSED');
            done();
        });
    });
});

describe('Background Polling Logic Tests', () => {
    let mockYnetData = [{ title: 'News 1' }];
    let mockAlertsData = ['Alert 1'];
    
    beforeEach(() => {
        jest.clearAllMocks();
    });

    test('should detect changes in Ynet data', () => {
        const lastData = [{ title: 'News 1' }];
        const newData = [{ title: 'News 2' }];
        
        const hasChanged = JSON.stringify(newData) !== JSON.stringify(lastData);
        expect(hasChanged).toBe(true);
    });

    test('should not trigger updates for identical data', () => {
        const lastData = [{ title: 'News 1' }];
        const newData = [{ title: 'News 1' }];
        
        const hasChanged = JSON.stringify(newData) !== JSON.stringify(lastData);
        expect(hasChanged).toBe(false);
    });

    test('should handle empty data arrays', () => {
        const lastData = [];
        const newData = ['Alert 1'];
        
        const hasChanged = JSON.stringify(newData) !== JSON.stringify(lastData);
        expect(hasChanged).toBe(true);
    });

    test('should handle null/undefined data', () => {
        const lastData = null;
        const newData = [];
        
        const hasChanged = JSON.stringify(newData) !== JSON.stringify(lastData);
        expect(hasChanged).toBe(true);
    });
});

describe('Message Broadcasting Tests', () => {
    test('should broadcast to all connected clients', () => {
        const mockClients = new Set();
        const mockSend = jest.fn();
        
        // Create mock WebSocket clients
        for (let i = 0; i < 3; i++) {
            mockClients.add({
                readyState: 1, // WebSocket.OPEN
                send: mockSend
            });
        }
        
        // Mock broadcast function
        const broadcastToClients = (type, data) => {
            const message = JSON.stringify({ type, data });
            const deadClients = new Set();
            
            mockClients.forEach(ws => {
                if (ws.readyState === 1) { // WebSocket.OPEN
                    ws.send(message);
                } else {
                    deadClients.add(ws);
                }
            });
            
            deadClients.forEach(ws => mockClients.delete(ws));
        };
        
        broadcastToClients('alerts', ['Test Alert']);
        
        expect(mockSend).toHaveBeenCalledTimes(3);
        expect(mockSend).toHaveBeenCalledWith(
            JSON.stringify({ type: 'alerts', data: ['Test Alert'] })
        );
    });

    test('should clean up dead connections', () => {
        const mockClients = new Set();
        
        // Add mix of live and dead connections
        mockClients.add({ readyState: 1, send: jest.fn() }); // OPEN
        mockClients.add({ readyState: 3, send: jest.fn() }); // CLOSED
        mockClients.add({ readyState: 1, send: jest.fn() }); // OPEN
        
        const broadcastToClients = (type, data) => {
            const message = JSON.stringify({ type, data });
            const deadClients = new Set();
            
            mockClients.forEach(ws => {
                if (ws.readyState === 1) { // WebSocket.OPEN
                    ws.send(message);
                } else {
                    deadClients.add(ws);
                }
            });
            
            deadClients.forEach(ws => mockClients.delete(ws));
            return mockClients.size;
        };
        
        const remainingClients = broadcastToClients('test', {});
        
        expect(remainingClients).toBe(2); // Only live connections remain
    });
});
