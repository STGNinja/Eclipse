const http = require('http');
const url = require('url');

const PORT = 3000;

const server = http.createServer((req, res) => {
    const parsedUrl = url.parse(req.url, true);

    // Handle Canva OAuth callback
    if (parsedUrl.pathname === '/oauth/canva') {
        const code = parsedUrl.query.code;
        const state = parsedUrl.query.state;
        const error = parsedUrl.query.error;

        if (error) {
            console.log('❌ OAuth Error:', error);
            res.writeHead(200, { 'Content-Type': 'text/html' });
            res.end(`
        <html>
          <body style="font-family: Arial; text-align: center; padding: 50px;">
            <h1>❌ Authorization Failed</h1>
            <p>Error: ${error}</p>
            <p>You can close this window.</p>
          </body>
        </html>
      `);
            return;
        }

        if (code) {
            console.log('✅ Authorization Code Received:', code);
            console.log('📝 State:', state);

            // Send success response
            res.writeHead(200, { 'Content-Type': 'text/html' });
            res.end(`
        <html>
          <body style="font-family: Arial; text-align: center; padding: 50px;">
            <h1>✅ Authorization Successful!</h1>
            <p>You can close this window and return to the app.</p>
            <script>
              // Try to close the window after 2 seconds
              setTimeout(() => window.close(), 2000);
            </script>
          </body>
        </html>
      `);

            // The app will handle the token exchange automatically
            return;
        }
    }

    // Default response for other paths
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('Not Found');
});

server.listen(PORT, () => {
    console.log(`🚀 OAuth callback server running at http://localhost:${PORT}`);
    console.log(`📡 Waiting for Canva OAuth redirect...`);
});
