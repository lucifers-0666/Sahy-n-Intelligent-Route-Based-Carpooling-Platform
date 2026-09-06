require('dotenv').config();
const app = require('./app');
const connectDB = require('./config/db');

const PORT = process.env.PORT || 5000;

// Initialize Database connection
connectDB();

const HOST = process.env.HOST || '0.0.0.0';

app.listen(PORT, HOST, () => {
  console.log(`[SERVER] Sahyān Backend Server running on http://${HOST}:${PORT}`);
  console.log(`[HEALTH] Health Check: http://localhost:${PORT}/api/health`);
});
