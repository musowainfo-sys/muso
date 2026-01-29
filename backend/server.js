const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

// NOTE: require path should point to backend/config/database.js
const db = require('./config/database');
const authRoutes = require('./src/routes/auth');
const leadRoutes = require('./src/routes/leads');
const bookingRoutes = require('./src/routes/bookings');
const paymentRoutes = require('./src/routes/payments');
const dashboardRoutes = require('./src/routes/dashboard');
const { errorHandler } = require('./src/middleware/errorHandler');

const app = express();

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:5173',
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100
});
app.use(limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// File upload middleware (route-level file handlers recommended)
const multer = require('multer');
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + ' - ' + file.originalname);
  }
});
// .none() will reject files; keep it only if you expect no files globally
app.use(multer({ storage }).none());

// Test DB connections (async). db should export { core, finance, analytics } pools.
async function testConnections() {
  try {
    const connCore = await db.core.getConnection();
    connCore.release();
    const connFinance = await db.finance.getConnection();
    connFinance.release();
    const connAnalytics = await db.analytics.getConnection();
    connAnalytics.release();
    console.log('All DB pools connected');
  } catch (err) {
    console.error('Database connection failed:', err);
    process.exit(1);
  }
}

// Run connection tests then start server
(async () => {
  await testConnections();

  // Routes
  app.use('/api/auth', authRoutes);
  app.use('/api/leads', leadRoutes);
  app.use('/api/bookings', bookingRoutes);
  app.use('/api/payments', paymentRoutes);
  app.use('/api/dashboard', dashboardRoutes);

  // Health check
  app.get('/health', (req, res) => {
    res.json({ status: 'OK', timestamp: new Date().toISOString() });
  });

  // Error handling
  app.use(errorHandler);

  const PORT = process.env.PORT || 3000;
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
})();

module.exports = app;