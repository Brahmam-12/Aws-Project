# CODE EXAMPLES: 3-TIER AWS APPLICATION 💻

## Complete Code Samples for Node.js, Python, and Java

---

## TABLE OF CONTENTS

1. [Node.js + Express + PostgreSQL](#nodejs--express--postgresql)
2. [Python + Flask + PostgreSQL](#python--flask--postgresql)
3. [Java + Spring Boot + PostgreSQL](#java--spring-boot--postgresql)
4. [Database Connection Strings](#database-connection-strings)
5. [Configuration Management (No Hardcoded IPs!)](#configuration-management)
6. [S3 Integration Examples](#s3-integration)
7. [Error Handling & Timeouts](#error-handling--timeouts)
8. [Common Issues & Solutions](#common-issues--solutions)

---

## Node.js + Express + PostgreSQL

### Architecture Review
```
Browser (React/Angular)
    ↓
HTTPS GET/POST to api.myapp.com:443
    ↓
Route53 resolves to ALB IP
    ↓
ALB (port 443 → 3000)
    ↓
Node.js Express Server (port 3000)
    ↓
PostgreSQL Pool (port 5432)
    ↓
RDS Instance (mydb.c123xyz.us-east-1.rds.amazonaws.com)
```

### File 1: `package.json`

```json
{
  "name": "3-tier-api",
  "version": "1.0.0",
  "description": "Node.js API for 3-tier AWS application",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "jest --detectOpenHandles",
    "migrate": "node scripts/migrate.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "pg": "^8.10.0",
    "dotenv": "^16.3.1",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "morgan": "^1.10.0",
    "aws-sdk": "^2.1500.0",
    "joi": "^17.11.0",
    "express-async-errors": "^3.1.1",
    "bcrypt": "^5.1.1",
    "jsonwebtoken": "^9.1.2"
  },
  "devDependencies": {
    "nodemon": "^3.0.1",
    "jest": "^29.7.0",
    "supertest": "^6.3.3"
  },
  "engines": {
    "node": ">=20.0.0",
    "npm": ">=10.0.0"
  }
}
```

### File 2: `.env` Configuration

```bash
# Application
NODE_ENV=production
PORT=3000
LOG_LEVEL=info

# Database (NO HARDCODED IPs - Use RDS Endpoint!)
DB_HOST=mydb.c123xyz.us-east-1.rds.amazonaws.com
DB_PORT=5432
DB_NAME=appdb
DB_USER=postgres
# Password from AWS Secrets Manager (DO NOT PUT IN .env for production!)
DB_PASSWORD_SECRET=rds-creds-prod

# Connection Pool
DB_POOL_MIN=5
DB_POOL_MAX=20
DB_IDLE_TIMEOUT=30000
DB_STATEMENT_TIMEOUT=5000

# Database SSL
DB_SSL=true
DB_SSL_REJECT_UNAUTHORIZED=false

# API
API_TIMEOUT=30000
REQUEST_ID_HEADER=x-request-id

# AWS
AWS_REGION=us-east-1
AWS_ACCOUNT_ID=123456789012

# S3
S3_BUCKET=my-app-uploads
S3_REGION=us-east-1
S3_UPLOAD_TIMEOUT=30000

# Security
JWT_SECRET=your-secret-key-here
JWT_EXPIRE=24h
CORS_ORIGIN=https://myapp.com

# Logging
CLOUDWATCH_LOG_GROUP=/aws/ec2/3-tier-api
CLOUDWATCH_LOG_STREAM=prod
```

### File 3: `db/pool.js` - Database Connection Pool

```javascript
const { Pool } = require('pg');
const AWS = require('aws-sdk');
const fs = require('fs');
const path = require('path');

// Get RDS CA certificate from AWS
const getRDSCertificate = () => {
  try {
    return fs.readFileSync(path.join(__dirname, '../certs/rds-ca-2019-root.pem'));
  } catch (err) {
    console.warn('RDS CA certificate not found, using system certs');
    return undefined;
  }
};

// Fetch database password from AWS Secrets Manager
const getDBPassword = async () => {
  const secretsManager = new AWS.SecretsManager({ region: process.env.AWS_REGION });
  
  try {
    const secret = await secretsManager.getSecretValue({
      SecretId: process.env.DB_PASSWORD_SECRET
    }).promise();
    
    const credentials = JSON.parse(secret.SecretString);
    return credentials.password;
  } catch (err) {
    console.error('Failed to fetch DB password from Secrets Manager:', err);
    throw err;
  }
};

// Create connection pool
const createPool = async () => {
  const dbPassword = await getDBPassword();
  
  const pool = new Pool({
    // Connection Details
    host: process.env.DB_HOST,           // RDS endpoint (not hardcoded IP)
    port: parseInt(process.env.DB_PORT),
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: dbPassword,                 // From Secrets Manager
    
    // Pool Configuration
    min: parseInt(process.env.DB_POOL_MIN) || 5,
    max: parseInt(process.env.DB_POOL_MAX) || 20,
    idleTimeoutMillis: parseInt(process.env.DB_IDLE_TIMEOUT) || 30000,
    connectionTimeoutMillis: 10000,
    
    // SSL Configuration (for RDS)
    ssl: process.env.DB_SSL === 'true' ? {
      rejectUnauthorized: process.env.DB_SSL_REJECT_UNAUTHORIZED !== 'true',
      ca: getRDSCertificate()
    } : false,
    
    // Statement Timeout
    statement_timeout: parseInt(process.env.DB_STATEMENT_TIMEOUT) || 5000,
    
    // Query Timeout
    query_timeout: parseInt(process.env.DB_STATEMENT_TIMEOUT) || 5000,
    
    // Connection Lifecycle Logging
    application_name: 'node-api-prod'
  });

  // Event: Connection Error
  pool.on('error', (err, client) => {
    console.error('Unexpected error on idle client', err);
    process.exit(-1);
  });

  // Event: Query Start
  pool.on('query', (query) => {
    if (query.text && query.text.length > 200) {
      console.debug(`Query: ${query.text.substring(0, 200)}...`);
    } else {
      console.debug(`Query: ${query.text}`);
    }
  });

  // Health check on startup
  try {
    const result = await pool.query('SELECT NOW()');
    console.log('✓ Database connection successful:', result.rows[0]);
  } catch (err) {
    console.error('✗ Database connection failed:', err.message);
    throw err;
  }

  return pool;
};

// Export
module.exports = {
  createPool,
  getDBPassword
};
```

### File 4: `db/connection.js` - Initialize Pool

```javascript
const { createPool } = require('./pool');

let pool = null;

// Initialize pool once on startup
const initializePool = async () => {
  if (!pool) {
    pool = await createPool();
  }
  return pool;
};

// Get pool (lazy initialization)
const getPool = async () => {
  if (!pool) {
    return await initializePool();
  }
  return pool;
};

// Query helper
const query = async (text, params) => {
  const pool = await getPool();
  
  const start = Date.now();
  try {
    const result = await pool.query(text, params);
    const duration = Date.now() - start;
    console.log(`✓ Query executed: ${duration}ms`);
    return result;
  } catch (error) {
    const duration = Date.now() - start;
    console.error(`✗ Query failed: ${duration}ms`, error);
    throw error;
  }
};

// Close pool (for graceful shutdown)
const closePool = async () => {
  if (pool) {
    await pool.end();
    pool = null;
    console.log('Database pool closed');
  }
};

module.exports = {
  initializePool,
  getPool,
  query,
  closePool
};
```

### File 5: `models/User.js` - Database Model

```javascript
const db = require('../db/connection');

class User {
  // Create new user
  static async create(name, email, password) {
    const text = `
      INSERT INTO users (name, email, password_hash, created_at, updated_at)
      VALUES ($1, $2, $3, NOW(), NOW())
      RETURNING id, name, email, created_at
    `;
    
    try {
      const result = await db.query(text, [name, email, password]);
      return result.rows[0];
    } catch (err) {
      if (err.code === '23505') {  // Unique constraint violation
        const error = new Error('Email already exists');
        error.statusCode = 400;
        throw error;
      }
      throw err;
    }
  }

  // Find by ID
  static async findById(userId) {
    const text = `
      SELECT id, name, email, created_at, updated_at
      FROM users
      WHERE id = $1
    `;
    
    const result = await db.query(text, [userId]);
    return result.rows[0] || null;
  }

  // Find by email
  static async findByEmail(email) {
    const text = `
      SELECT id, name, email, password_hash, created_at, updated_at
      FROM users
      WHERE email = $1
    `;
    
    const result = await db.query(text, [email]);
    return result.rows[0] || null;
  }

  // Get all users (with pagination)
  static async findAll(page = 1, limit = 10) {
    const offset = (page - 1) * limit;
    
    const text = `
      SELECT id, name, email, created_at
      FROM users
      ORDER BY created_at DESC
      LIMIT $1 OFFSET $2
    `;
    
    const result = await db.query(text, [limit, offset]);
    return result.rows;
  }

  // Update user
  static async update(userId, name, email) {
    const text = `
      UPDATE users
      SET name = $2, email = $3, updated_at = NOW()
      WHERE id = $1
      RETURNING id, name, email, updated_at
    `;
    
    try {
      const result = await db.query(text, [userId, name, email]);
      return result.rows[0] || null;
    } catch (err) {
      if (err.code === '23505') {  // Unique constraint
        const error = new Error('Email already in use');
        error.statusCode = 400;
        throw error;
      }
      throw err;
    }
  }

  // Delete user
  static async delete(userId) {
    const text = 'DELETE FROM users WHERE id = $1';
    await db.query(text, [userId]);
    return true;
  }
}

module.exports = User;
```

### File 6: `routes/users.js` - API Endpoints

```javascript
const express = require('express');
const router = express.Router();
const User = require('../models/User');
const { validateUser } = require('../middleware/validation');
const { authenticate } = require('../middleware/auth');

/**
 * POST /api/users
 * Create new user
 * 
 * Request:
 *   {
 *     "name": "John Doe",
 *     "email": "john@example.com",
 *     "password": "securepass123"
 *   }
 * 
 * Response: 201 Created
 *   {
 *     "success": true,
 *     "data": {
 *       "id": 42,
 *       "name": "John Doe",
 *       "email": "john@example.com",
 *       "created_at": "2025-11-27T10:30:00Z"
 *     }
 *   }
 * 
 * Error: 400 Bad Request
 *   {
 *     "error": "Email already exists"
 *   }
 */
router.post('/', validateUser, async (req, res, next) => {
  try {
    const { name, email, password } = req.body;
    
    // Hash password (simplified - use bcrypt in production)
    const hashedPassword = await require('bcrypt').hash(password, 10);
    
    // Create user
    const user = await User.create(name, email, hashedPassword);
    
    // Response
    res.status(201).json({
      success: true,
      data: user
    });
    
  } catch (err) {
    next(err);  // Pass to error handler
  }
});

/**
 * GET /api/users/:id
 * Get user by ID
 * 
 * Response: 200 OK
 *   {
 *     "success": true,
 *     "data": { ... user object ... }
 *   }
 */
router.get('/:id', authenticate, async (req, res, next) => {
  try {
    const { id } = req.params;
    
    const user = await User.findById(id);
    
    if (!user) {
      return res.status(404).json({
        error: 'User not found'
      });
    }
    
    res.json({
      success: true,
      data: user
    });
    
  } catch (err) {
    next(err);
  }
});

/**
 * GET /api/users
 * Get all users (with pagination)
 * 
 * Query params:
 *   ?page=1&limit=10
 * 
 * Response: 200 OK
 *   {
 *     "success": true,
 *     "data": [ ... array of users ... ],
 *     "pagination": {
 *       "page": 1,
 *       "limit": 10,
 *       "total": 42
 *     }
 *   }
 */
router.get('/', authenticate, async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    
    const users = await User.findAll(page, limit);
    
    res.json({
      success: true,
      data: users,
      pagination: {
        page,
        limit,
        count: users.length
      }
    });
    
  } catch (err) {
    next(err);
  }
});

/**
 * PUT /api/users/:id
 * Update user
 * 
 * Request:
 *   {
 *     "name": "Jane Doe",
 *     "email": "jane@example.com"
 *   }
 * 
 * Response: 200 OK
 *   {
 *     "success": true,
 *     "data": { ... updated user ... }
 *   }
 */
router.put('/:id', authenticate, validateUser, async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, email } = req.body;
    
    // Authorization check: users can only update their own profile
    if (parseInt(id) !== req.user.id) {
      return res.status(403).json({ error: 'Unauthorized' });
    }
    
    const user = await User.update(id, name, email);
    
    res.json({
      success: true,
      data: user
    });
    
  } catch (err) {
    next(err);
  }
});

/**
 * DELETE /api/users/:id
 * Delete user
 * 
 * Response: 204 No Content
 */
router.delete('/:id', authenticate, async (req, res, next) => {
  try {
    const { id } = req.params;
    
    // Authorization check
    if (parseInt(id) !== req.user.id) {
      return res.status(403).json({ error: 'Unauthorized' });
    }
    
    await User.delete(id);
    
    res.status(204).send();
    
  } catch (err) {
    next(err);
  }
});

module.exports = router;
```

### File 7: `server.js` - Express Application

```javascript
require('dotenv').config();
require('express-async-errors');

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { v4: uuidv4 } = require('uuid');

const { initializePool, closePool } = require('./db/connection');
const usersRouter = require('./routes/users');

// Initialize Express app
const app = express();

// ============================================
// MIDDLEWARE - Security
// ============================================

// Helmet: Set security headers
app.use(helmet());

// CORS: Cross-origin requests
app.use(cors({
  origin: process.env.CORS_ORIGIN || 'https://myapp.com',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// ============================================
// MIDDLEWARE - Logging & Parsing
// ============================================

// Morgan: HTTP request logging
app.use(morgan('combined'));

// Body parser
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

// ============================================
// MIDDLEWARE - Request Context
// ============================================

// Add request ID for tracing
app.use((req, res, next) => {
  req.id = req.get(process.env.REQUEST_ID_HEADER) || uuidv4();
  res.setHeader('X-Request-ID', req.id);
  
  // Log request
  console.log(`[${req.id}] ${req.method} ${req.path}`);
  
  next();
});

// ============================================
// MIDDLEWARE - Timeout
// ============================================

// Set timeout for all requests
app.use((req, res, next) => {
  req.setTimeout(parseInt(process.env.API_TIMEOUT) || 30000);
  next();
});

// ============================================
// ROUTES
// ============================================

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// User routes
app.use('/api/users', usersRouter);

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    path: req.path
  });
});

// ============================================
// ERROR HANDLING MIDDLEWARE
// ============================================

app.use((err, req, res, next) => {
  const requestId = req.id;
  
  console.error(`[${requestId}] Error:`, {
    message: err.message,
    statusCode: err.statusCode,
    stack: err.stack
  });

  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal Server Error';
  
  // Database errors
  if (err.code === 'ECONNREFUSED') {
    return res.status(503).json({
      error: 'Database unavailable',
      requestId
    });
  }
  
  if (err.code === '23505') {  // Unique constraint
    return res.status(400).json({
      error: 'Duplicate entry',
      detail: err.detail,
      requestId
    });
  }
  
  // Timeout errors
  if (err.code === 'STATEMENT_TIMEOUT') {
    return res.status(504).json({
      error: 'Query timeout',
      requestId
    });
  }

  // Generic error response
  res.status(statusCode).json({
    error: message,
    requestId,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// ============================================
// SERVER STARTUP
// ============================================

const PORT = process.env.PORT || 3000;

const startServer = async () => {
  try {
    // Initialize database pool
    console.log('Initializing database pool...');
    await initializePool();
    
    // Start Express server
    const server = app.listen(PORT, () => {
      console.log(`✓ Server listening on port ${PORT}`);
      console.log(`✓ Environment: ${process.env.NODE_ENV}`);
      console.log(`✓ Database: ${process.env.DB_HOST}:${process.env.DB_PORT}`);
    });
    
    // Graceful shutdown
    process.on('SIGTERM', async () => {
      console.log('SIGTERM received, shutting down gracefully...');
      server.close(async () => {
        await closePool();
        process.exit(0);
      });
    });
    
    process.on('SIGINT', async () => {
      console.log('SIGINT received, shutting down gracefully...');
      server.close(async () => {
        await closePool();
        process.exit(0);
      });
    });
    
  } catch (err) {
    console.error('Failed to start server:', err);
    process.exit(1);
  }
};

// Start the server
startServer();

module.exports = app;
```

### File 8: `middleware/validation.js` - Input Validation

```javascript
const Joi = require('joi');

const userSchema = Joi.object({
  name: Joi.string()
    .min(3)
    .max(100)
    .required()
    .messages({
      'string.min': 'Name must be at least 3 characters',
      'string.max': 'Name cannot exceed 100 characters'
    }),
  email: Joi.string()
    .email()
    .required()
    .messages({
      'string.email': 'Must be a valid email address'
    }),
  password: Joi.string()
    .min(8)
    .required()
    .messages({
      'string.min': 'Password must be at least 8 characters'
    })
});

const validateUser = (req, res, next) => {
  const { error, value } = userSchema.validate(req.body);
  
  if (error) {
    return res.status(400).json({
      error: 'Validation failed',
      details: error.details.map(d => ({
        field: d.path[0],
        message: d.message
      }))
    });
  }
  
  req.body = value;  // Sanitized input
  next();
};

module.exports = {
  validateUser
};
```

### File 9: `middleware/auth.js` - Authentication

```javascript
const jwt = require('jsonwebtoken');

const authenticate = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Missing authorization token' });
    }
    
    const token = authHeader.slice(7);
    
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    req.user = decoded;  // {id, email, ...}
    next();
    
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token expired' });
    }
    res.status(401).json({ error: 'Invalid token' });
  }
};

module.exports = {
  authenticate
};
```

---

## Python + Flask + PostgreSQL

### Architecture Mapping (Same as Node.js)

```
Browser (React/Angular)
    ↓
HTTPS to api.myapp.com
    ↓
Route53 → ALB (IP: 12.34.56.78)
    ↓
ALB forwards to Python Flask (port 5000)
    ↓
Connection Pool → PostgreSQL (RDS endpoint)
```

### File 1: `requirements.txt`

```
Flask==2.3.3
Flask-CORS==4.0.0
psycopg2-binary==2.9.7
python-dotenv==1.0.0
boto3==1.28.0
gunicorn==21.2.0
Werkzeug==2.3.7
```

### File 2: `app.py` - Flask Application

```python
import os
import logging
import json
from flask import Flask, jsonify, request
from flask_cors import CORS
import psycopg2
from psycopg2 import pool
import boto3
from dotenv import load_dotenv
from functools import wraps
from datetime import datetime
import uuid

# Load environment variables
load_dotenv()

# Initialize Flask
app = Flask(__name__)

# Configuration
app.config['JSON_SORT_KEYS'] = False
app.config['JSONIFY_PRETTYPRINT_REGULAR'] = True

# CORS
CORS(app, origins=[os.getenv('CORS_ORIGIN', 'https://myapp.com')])

# Logging
logging.basicConfig(level=os.getenv('LOG_LEVEL', 'INFO'))
logger = logging.getLogger(__name__)

# ============================================
# DATABASE CONNECTION POOL
# ============================================

def get_db_password():
    """Fetch database password from AWS Secrets Manager"""
    secrets_client = boto3.client(
        'secretsmanager',
        region_name=os.getenv('AWS_REGION')
    )
    
    try:
        response = secrets_client.get_secret_value(
            SecretId=os.getenv('DB_PASSWORD_SECRET')
        )
        secret = json.loads(response['SecretString'])
        return secret['password']
    except Exception as e:
        logger.error(f'Failed to fetch DB password: {str(e)}')
        raise

# Create connection pool (lazy initialization)
connection_pool = None

def init_connection_pool():
    """Initialize database connection pool on startup"""
    global connection_pool
    
    try:
        db_password = get_db_password()
        
        connection_pool = psycopg2.pool.SimpleConnectionPool(
            minconn=int(os.getenv('DB_POOL_MIN', 5)),
            maxconn=int(os.getenv('DB_POOL_MAX', 20)),
            
            # Connection details (NO hardcoded IPs!)
            host=os.getenv('DB_HOST'),  # RDS endpoint
            port=int(os.getenv('DB_PORT')),
            database=os.getenv('DB_NAME'),
            user=os.getenv('DB_USER'),
            password=db_password,
            
            # SSL
            sslmode='require',
            
            # Timeout
            connect_timeout=10
        )
        
        logger.info('✓ Database connection pool initialized')
        
    except Exception as e:
        logger.error(f'Failed to initialize connection pool: {str(e)}')
        raise

def get_db_connection():
    """Get connection from pool"""
    if connection_pool is None:
        init_connection_pool()
    return connection_pool.getconn()

def return_db_connection(conn):
    """Return connection to pool"""
    if connection_pool:
        connection_pool.putconn(conn)

# ============================================
# MIDDLEWARE
# ============================================

@app.before_request
def before_request():
    """Add request context"""
    request.request_id = request.headers.get('X-Request-ID', str(uuid.uuid4()))
    logger.info(f"[{request.request_id}] {request.method} {request.path}")

@app.after_request
def after_request(response):
    """Add response headers"""
    response.headers['X-Request-ID'] = request.request_id
    return response

# ============================================
# ERROR HANDLING
# ============================================

@app.errorhandler(400)
def bad_request(error):
    return jsonify({'error': 'Bad request'}), 400

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    logger.error(f"[{request.request_id}] Internal error: {str(error)}")
    return jsonify({
        'error': 'Internal server error',
        'request_id': request.request_id
    }), 500

# ============================================
# ROUTES
# ============================================

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'service': 'api'
    })

@app.route('/api/users', methods=['POST'])
def create_user():
    """
    POST /api/users
    Create new user
    
    Request:
      {
        "name": "John Doe",
        "email": "john@example.com"
      }
    
    Response: 201 Created
      {
        "success": true,
        "data": {
          "id": 42,
          "name": "John Doe",
          "email": "john@example.com",
          "created_at": "2025-11-27T10:30:00Z"
        }
      }
    """
    try:
        data = request.get_json()
        
        # Validation
        if not data.get('name') or not data.get('email'):
            return jsonify({'error': 'Name and email required'}), 400
        
        name = data['name']
        email = data['email']
        
        # Get connection from pool
        conn = get_db_connection()
        cur = conn.cursor()
        
        try:
            # Insert user
            cur.execute(
                '''INSERT INTO users (name, email, created_at, updated_at)
                   VALUES (%s, %s, NOW(), NOW())
                   RETURNING id, name, email, created_at''',
                (name, email)
            )
            
            conn.commit()
            user = cur.fetchone()
            
            return jsonify({
                'success': True,
                'data': {
                    'id': user[0],
                    'name': user[1],
                    'email': user[2],
                    'created_at': user[3].isoformat()
                }
            }), 201
            
        except psycopg2.IntegrityError as e:
            conn.rollback()
            if 'unique constraint' in str(e):
                return jsonify({'error': 'Email already exists'}), 400
            raise
        
        finally:
            cur.close()
            return_db_connection(conn)
            
    except Exception as e:
        logger.error(f"[{request.request_id}] Error creating user: {str(e)}")
        return jsonify({
            'error': 'Failed to create user',
            'request_id': request.request_id
        }), 500

@app.route('/api/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    """GET /api/users/:id"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        try:
            cur.execute(
                'SELECT id, name, email, created_at FROM users WHERE id = %s',
                (user_id,)
            )
            
            user = cur.fetchone()
            
            if not user:
                return jsonify({'error': 'User not found'}), 404
            
            return jsonify({
                'success': True,
                'data': {
                    'id': user[0],
                    'name': user[1],
                    'email': user[2],
                    'created_at': user[3].isoformat()
                }
            })
        
        finally:
            cur.close()
            return_db_connection(conn)
    
    except Exception as e:
        logger.error(f"[{request.request_id}] Error fetching user: {str(e)}")
        return jsonify({'error': 'Server error', 'request_id': request.request_id}), 500

# ============================================
# STARTUP
# ============================================

if __name__ == '__main__':
    try:
        # Initialize database pool
        init_connection_pool()
        
        # Start server
        port = int(os.getenv('PORT', 5000))
        app.run(
            host='0.0.0.0',
            port=port,
            debug=(os.getenv('NODE_ENV') == 'development')
        )
    
    except Exception as e:
        logger.error(f'Failed to start server: {str(e)}')
        exit(1)
```

---

## Java + Spring Boot + PostgreSQL

### File 1: `pom.xml` - Maven Dependencies

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.1.5</version>
    </parent>

    <groupId>com.myapp</groupId>
    <artifactId>3-tier-api</artifactId>
    <version>1.0.0</version>
    <name>3-Tier AWS API</name>

    <properties>
        <java.version>17</java.version>
    </properties>

    <dependencies>
        <!-- Spring Boot Web -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <!-- Spring Data JPA -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>

        <!-- PostgreSQL Driver -->
        <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>postgresql</artifactId>
            <version>42.6.0</version>
        </dependency>

        <!-- HikariCP Connection Pool -->
        <dependency>
            <groupId>com.zaxxer</groupId>
            <artifactId>HikariCP</artifactId>
            <version>5.0.1</version>
        </dependency>

        <!-- AWS SDK -->
        <dependency>
            <groupId>software.amazon.awssdk</groupId>
            <artifactId>secretsmanager</artifactId>
            <version>2.20.100</version>
        </dependency>

        <!-- Lombok (reduce boilerplate) -->
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>

        <!-- Validation -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>

        <!-- Testing -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

### File 2: `application.yml` - Configuration

```yaml
spring:
  application:
    name: 3-tier-api
  
  jpa:
    hibernate:
      ddl-auto: validate
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect
        jdbc:
          batch_size: 10
  
  datasource:
    # NO hardcoded IPs - use RDS endpoint!
    url: jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=require
    username: ${DB_USER}
    password: ${DB_PASSWORD}
    hikari:
      minimum-idle: 5
      maximum-pool-size: 20
      idle-timeout: 30000
      max-lifetime: 1800000
      connection-timeout: 10000
      auto-commit: true
  
  servlet:
    multipart:
      max-file-size: 10MB
      max-request-size: 10MB

server:
  port: ${PORT:8080}
  servlet:
    context-path: /
  compression:
    enabled: true
  timeout:
    connect: PT10S

logging:
  level:
    root: ${LOG_LEVEL:INFO}
    com.myapp: DEBUG
  pattern:
    console: "[%d{HH:mm:ss.SSS}] [%thread] %-5level %logger{36} - %msg%n"
    file: "%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n"
  file:
    name: /var/log/app/application.log
```

### File 3: `com/myapp/entity/User.java` - Database Entity

```java
package com.myapp.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "users", indexes = {
    @Index(name = "idx_email", columnList = "email", unique = true)
})
@Data
@NoArgsConstructor
@AllArgsConstructor
public class User {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @NotBlank(message = "Name is required")
    @Size(min = 3, max = 100, message = "Name must be 3-100 characters")
    @Column(nullable = false)
    private String name;
    
    @NotBlank(message = "Email is required")
    @Email(message = "Email must be valid")
    @Column(nullable = false, unique = true)
    private String email;
    
    @NotBlank(message = "Password is required")
    @Size(min = 8, message = "Password must be at least 8 characters")
    @Column(nullable = false, name = "password_hash")
    private String passwordHash;
    
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();
    
    @Column(nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();
    
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
```

### File 4: `com/myapp/repository/UserRepository.java` - Database Access

```java
package com.myapp.repository;

import com.myapp.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    
    Optional<User> findByEmail(String email);
    
    Page<User> findAll(Pageable pageable);
    
    boolean existsByEmail(String email);
}
```

### File 5: `com/myapp/service/UserService.java` - Business Logic

```java
package com.myapp.service;

import com.myapp.entity.User;
import com.myapp.repository.UserRepository;
import com.myapp.dto.UserDTO;
import com.myapp.exception.ResourceNotFoundException;
import com.myapp.exception.DuplicateEmailException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;

@Service
@Transactional
@RequiredArgsConstructor
@Slf4j
public class UserService {
    
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    
    /**
     * Create new user
     */
    public UserDTO createUser(String name, String email, String password) {
        log.info("Creating user: {}", email);
        
        // Check if email already exists
        if (userRepository.existsByEmail(email)) {
            log.warn("Email already exists: {}", email);
            throw new DuplicateEmailException("Email already in use");
        }
        
        // Create new user entity
        User user = new User();
        user.setName(name);
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(password));
        
        // Save to database
        user = userRepository.save(user);
        
        log.info("User created successfully: {}", user.getId());
        return convertToDTO(user);
    }
    
    /**
     * Get user by ID
     */
    @Transactional(readOnly = true)
    public UserDTO getUserById(Long userId) {
        log.debug("Fetching user: {}", userId);
        
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        
        return convertToDTO(user);
    }
    
    /**
     * Get all users with pagination
     */
    @Transactional(readOnly = true)
    public Page<UserDTO> getAllUsers(Pageable pageable) {
        log.debug("Fetching all users: page={}, size={}", 
            pageable.getPageNumber(), pageable.getPageSize());
        
        return userRepository.findAll(pageable)
            .map(this::convertToDTO);
    }
    
    /**
     * Update user
     */
    public UserDTO updateUser(Long userId, String name, String email) {
        log.info("Updating user: {}", userId);
        
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        
        // Check if new email is already in use by another user
        if (!user.getEmail().equals(email) && 
            userRepository.existsByEmail(email)) {
            throw new DuplicateEmailException("Email already in use");
        }
        
        user.setName(name);
        user.setEmail(email);
        user = userRepository.save(user);
        
        return convertToDTO(user);
    }
    
    /**
     * Delete user
     */
    public void deleteUser(Long userId) {
        log.info("Deleting user: {}", userId);
        
        if (!userRepository.existsById(userId)) {
            throw new ResourceNotFoundException("User not found");
        }
        
        userRepository.deleteById(userId);
    }
    
    /**
     * Convert entity to DTO
     */
    private UserDTO convertToDTO(User user) {
        return UserDTO.builder()
            .id(user.getId())
            .name(user.getName())
            .email(user.getEmail())
            .createdAt(user.getCreatedAt())
            .build();
    }
}
```

### File 6: `com/myapp/controller/UserController.java` - API Endpoints

```java
package com.myapp.controller;

import com.myapp.service.UserService;
import com.myapp.dto.UserDTO;
import com.myapp.dto.CreateUserRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
@Slf4j
public class UserController {
    
    private final UserService userService;
    
    /**
     * POST /api/users
     * Create new user
     */
    @PostMapping
    public ResponseEntity<Map<String, Object>> createUser(
        @Valid @RequestBody CreateUserRequest request) {
        
        log.info("Creating user: {}", request.getEmail());
        
        UserDTO userDTO = userService.createUser(
            request.getName(),
            request.getEmail(),
            request.getPassword()
        );
        
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("data", userDTO);
        
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
    
    /**
     * GET /api/users/{id}
     * Get user by ID
     */
    @GetMapping("/{id}")
    public ResponseEntity<Map<String, Object>> getUser(@PathVariable Long id) {
        log.debug("Fetching user: {}", id);
        
        UserDTO userDTO = userService.getUserById(id);
        
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("data", userDTO);
        
        return ResponseEntity.ok(response);
    }
    
    /**
     * GET /api/users
     * Get all users (paginated)
     */
    @GetMapping
    public ResponseEntity<Map<String, Object>> getAllUsers(Pageable pageable) {
        log.debug("Fetching all users");
        
        Page<UserDTO> page = userService.getAllUsers(pageable);
        
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("data", page.getContent());
        response.put("pagination", Map.of(
            "page", page.getNumber(),
            "size", page.getSize(),
            "totalElements", page.getTotalElements(),
            "totalPages", page.getTotalPages()
        ));
        
        return ResponseEntity.ok(response);
    }
    
    /**
     * PUT /api/users/{id}
     * Update user
     */
    @PutMapping("/{id}")
    public ResponseEntity<Map<String, Object>> updateUser(
        @PathVariable Long id,
        @Valid @RequestBody CreateUserRequest request) {
        
        log.info("Updating user: {}", id);
        
        UserDTO userDTO = userService.updateUser(
            id,
            request.getName(),
            request.getEmail()
        );
        
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("data", userDTO);
        
        return ResponseEntity.ok(response);
    }
    
    /**
     * DELETE /api/users/{id}
     * Delete user
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
        log.info("Deleting user: {}", id);
        
        userService.deleteUser(id);
        
        return ResponseEntity.noContent().build();
    }
}
```

---

## Database Connection Strings

### PostgreSQL RDS Endpoint Format

```
RDS Endpoint: mydb.c123xyz.us-east-1.rds.amazonaws.com
Port: 5432
Database: appdb
Username: postgres
Password: (from Secrets Manager, NOT hardcoded!)
```

### Node.js Connection String

```javascript
// ✗ BAD - Hardcoded IP
const pool = new Pool({
  host: '10.0.5.42',  // Server restarts → new IP!
  port: 5432,
  database: 'appdb',
  user: 'postgres',
  password: 'secret123'  // Exposed in code!
});

// ✓ GOOD - Using environment variables
const pool = new Pool({
  host: process.env.DB_HOST,  // mydb.c123xyz.us-east-1.rds.amazonaws.com
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,  // From AWS Secrets Manager
  ssl: { rejectUnauthorized: false }
});
```

### Python Connection String

```python
# ✗ BAD
import psycopg2
conn = psycopg2.connect("host=10.0.5.42 port=5432 database=appdb user=postgres password=secret123")

# ✓ GOOD
import os
import psycopg2
conn = psycopg2.connect(
    host=os.getenv('DB_HOST'),  # RDS endpoint
    port=os.getenv('DB_PORT'),
    database=os.getenv('DB_NAME'),
    user=os.getenv('DB_USER'),
    password=os.getenv('DB_PASSWORD'),  # From Secrets Manager
    sslmode='require'
)
```

### Java Connection String

```
# application.properties
spring.datasource.url=jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=require
spring.datasource.username=${DB_USER}
spring.datasource.password=${DB_PASSWORD}

# At runtime:
# jdbc:postgresql://mydb.c123xyz.us-east-1.rds.amazonaws.com:5432/appdb?sslmode=require
```

---

## Configuration Management

### ✓ Best Practices

```
1. NEVER hardcode IPs, passwords, or secrets
2. Use AWS Secrets Manager for credentials
3. Use environment variables for configuration
4. Use RDS Endpoint DNS name (not IP address)
5. Use connection pools (not new connection per request)
6. Use SSL/TLS for database connections
7. Use IAM roles (not access keys) for AWS service access
```

### File: `.env` (Never commit to Git!)

```bash
# Add to .gitignore
.env
.env.local
*.pem
secrets/

# Contents of .env (development only)
NODE_ENV=production
PORT=3000
DB_HOST=mydb.c123xyz.us-east-1.rds.amazonaws.com
DB_PORT=5432
DB_NAME=appdb
DB_USER=postgres
DB_PASSWORD_SECRET=rds-prod-creds
AWS_REGION=us-east-1
```

### AWS Secrets Manager Setup

```bash
# Store database credentials in AWS Secrets Manager
aws secretsmanager create-secret \
  --name rds-prod-creds \
  --secret-string '{"username":"postgres","password":"your-secure-password"}' \
  --region us-east-1

# Retrieve credentials (from application)
aws secretsmanager get-secret-value \
  --secret-id rds-prod-creds \
  --region us-east-1
```

---

## S3 Integration

### Node.js + S3 Example

```javascript
// routes/files.js
const express = require('express');
const router = express.Router();
const AWS = require('aws-sdk');
const fs = require('fs');
const path = require('path');

// Configure S3
const s3 = new AWS.S3({
  region: process.env.AWS_REGION,
  // No access keys needed! Use EC2 IAM role
});

/**
 * Upload file to S3
 * POST /api/files/upload
 */
router.post('/upload', async (req, res) => {
  try {
    const file = req.files.upload;  // From multipart form
    const userId = req.user.id;
    
    const key = `uploads/users/${userId}/${Date.now()}-${file.name}`;
    
    const params = {
      Bucket: process.env.S3_BUCKET,
      Key: key,
      Body: file.data,
      ContentType: file.mimetype,
      ServerSideEncryption: 'AES256'  // Encrypt at rest
    };
    
    // Upload to S3
    const result = await s3.upload(params).promise();
    
    res.json({
      success: true,
      data: {
        url: result.Location,
        key: result.Key,
        etag: result.ETag
      }
    });
    
  } catch (err) {
    console.error('S3 upload failed:', err);
    res.status(500).json({ error: 'Upload failed' });
  }
});

/**
 * Download file from S3
 * GET /api/files/download/:fileKey
 */
router.get('/download/:fileKey', async (req, res) => {
  try {
    const fileKey = Buffer.from(req.params.fileKey, 'base64').toString();
    
    const params = {
      Bucket: process.env.S3_BUCKET,
      Key: fileKey
    };
    
    // Generate signed URL (valid for 1 hour)
    const url = s3.getSignedUrl('getObject', {
      ...params,
      Expires: 3600
    });
    
    res.json({
      success: true,
      url: url
    });
    
  } catch (err) {
    console.error('S3 download failed:', err);
    res.status(500).json({ error: 'Download failed' });
  }
});

module.exports = router;
```

---

## Error Handling & Timeouts

### Node.js Error Handling

```javascript
/**
 * Database connection timeout
 */
pool.on('error', (err) => {
  console.error('Pool error:', err);
  // Alert monitoring system
  // Attempt to reconnect
});

/**
 * Query timeout handling
 */
const queryWithTimeout = async (sql, params, timeoutMs = 5000) => {
  return Promise.race([
    db.query(sql, params),
    new Promise((_, reject) =>
      setTimeout(() => reject(new Error('Query timeout')), timeoutMs)
    )
  ]);
};

/**
 * Database specific errors
 */
const handleDatabaseError = (err) => {
  if (err.code === '23505') {  // Unique constraint
    return { status: 400, message: 'Duplicate entry' };
  }
  if (err.code === 'ECONNREFUSED') {  // Connection refused
    return { status: 503, message: 'Database unavailable' };
  }
  if (err.code === 'STATEMENT_TIMEOUT') {  // Timeout
    return { status: 504, message: 'Query timeout' };
  }
  return { status: 500, message: 'Database error' };
};
```

---

## Common Issues & Solutions

### Issue 1: "Connection refused" Error

```
Error: connect ECONNREFUSED 10.0.5.42:5432

Possible causes:
1. ✗ Web server security group doesn't allow outbound to RDS
2. ✗ Database security group doesn't allow inbound from web server SG
3. ✗ RDS endpoint in wrong subnet
4. ✗ RDS is stopped or failed
5. ✗ Hardcoded IP changed (RDS restarted)

Solution:
1. ✓ Verify web-sg has outbound rule: database-sg on port 5432
2. ✓ Verify database-sg has inbound rule: web-sg on port 5432
3. ✓ Use RDS endpoint DNS, not hardcoded IP
4. ✓ Check RDS status in AWS console
5. ✓ Test from EC2: telnet mydb.c123xyz.us-east-1.rds.amazonaws.com 5432
```

### Issue 2: "Connection timeout" Error

```
Error: connect ETIMEDOUT
at TCPConnectWrap.afterConnect [as oncomplete] (net.js:1144:5)

Possible causes:
1. ✗ NACL rule missing for database subnet
2. ✗ Network ACL not allowing ephemeral ports
3. ✗ Route table misconfigured
4. ✗ RDS not accepting connections

Solution:
1. ✓ Check NACL-Private-App outbound: Allow TCP 5432 to DB subnet
2. ✓ Check NACL-Private-App outbound: Allow 1024-65535 ephemeral
3. ✓ Check route tables: Private subnets route to RDS subnet
4. ✓ Test from EC2: nmap -p 5432 <rds-endpoint>
```

### Issue 3: "Permission denied" Error

```
Error: password authentication failed for user "postgres"

Possible causes:
1. ✗ Wrong password from Secrets Manager
2. ✗ User doesn't exist in database
3. ✗ Database user changed

Solution:
1. ✓ Verify Secrets Manager secret value
2. ✓ Check database user: psql -l -U postgres
3. ✓ Update credentials in Secrets Manager
4. ✓ Restart application to fetch new credentials
```

### Issue 4: "Connection pool exhausted" Error

```
Error: timeout acquiring a client from the connection pool

Possible causes:
1. ✗ Pool size too small for traffic
2. ✗ Connections not being released (no close())
3. ✗ Long-running queries holding connections
4. ✗ RDS max connections limit reached

Solution:
1. ✓ Increase DB_POOL_MAX (careful with RDS limits)
2. ✓ Ensure pool.end() called in finally block
3. ✓ Add query timeout: 30 seconds
4. ✓ Check RDS: SELECT count(*) FROM pg_stat_activity
```

---

**Last Updated:** November 27, 2025  
**Compatible With:** Node.js 20+, Python 3.10+, Java 17+  
**Database:** PostgreSQL 13+  
**AWS Services:** RDS, EC2, ALB, S3, Secrets Manager, Route53
