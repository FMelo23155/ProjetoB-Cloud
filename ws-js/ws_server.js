const WebSocket = require('ws');
const Redis = require('ioredis');

// Configuração do Redis
const redis = new Redis({
    host: '10.10.20.11',
    port: 6379,
});

const wss = new WebSocket.Server({ port: 8888 });

wss.on('connection', function connection(ws) {
    console.log('New connection!');

    ws.on('message', function incoming(message) {
        const data = JSON.parse(message);

        // Adicionar timestamp e sender ID
        data.timestamp = new Date().toISOString();
        data.sender_id = ws._socket.remotePort;
        data.message = sanitize(data.message);

        const messageToSend = JSON.stringify(data);
        redis.publish('websocket', messageToSend);
    });

    ws.on('close', function () {
        console.log('Connection has disconnected');
    });

    ws.on('error', function (error) {
        console.error('An error has occurred:', error.message);
    });
});

// Função de sanitização para evitar XSS
function sanitize(message) {
    return message.replace(/[&<>"'\/]/g, function (s) {
        return {
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            '"': '&quot;',
            "'": '&#39;',
            '/': '&#x2F;',
        }[s];
    });
}

// Inscreve-se no canal Redis
const subscriber = new Redis({
    host: '10.10.20.11',
    port: 6379,
});

subscriber.subscribe('websocket', function (err, count) {
    if (err) {
        console.error('Failed to subscribe: %s', err.message);
    } else {
        console.log(`Subscribed successfully! This client is currently subscribed to ${count} channels.`);
    }
});

subscriber.on('message', function (channel, message) {
    wss.clients.forEach(function each(client) {
        if (client.readyState === WebSocket.OPEN) {
            client.send(message);
        }
    });
});
