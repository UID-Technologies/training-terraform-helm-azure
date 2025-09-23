const http = require('http');
const os = require('os');

const PORT = process.env.PORT || 8080;
const hostname = os.hostname();

const server = http.createServer((req, res) => {
    const msg = `hello from ${hostname}`;
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end(msg);
});

server.listen(PORT, () => {
    console.log(`Server running at http://${hostname}:${PORT}/`);
});