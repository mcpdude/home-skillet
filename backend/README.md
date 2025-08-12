# Home Skillet Backend API

A Node.js backend API for the Home Skillet recipe management application, built with Express.js and following Test-Driven Development (TDD) principles.

## Features

- **Authentication**: JWT-based user registration and login
- **Security**: Helmet, CORS, rate limiting
- **Database**: PostgreSQL with Knex.js query builder
- **Testing**: Jest with unit and integration tests
- **Validation**: Input validation middleware
- **Environment**: Configuration management with dotenv

## Prerequisites

- Node.js (v16 or higher)
- PostgreSQL database
- npm or yarn

## Quick Start

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Set up environment variables:**
   ```bash
   cp .env.example .env
   # Edit .env with your database credentials and JWT secret
   ```

3. **Set up test environment:**
   ```bash
   cp .env.example .env.test
   # Edit .env.test with your test database credentials
   ```

4. **Run tests (TDD approach):**
   ```bash
   npm test
   ```

5. **Start development server:**
   ```bash
   npm run dev
   ```

## Project Structure

```
backend/
├── src/
│   ├── config/          # Configuration files
│   │   ├── database.js  # Database configuration
│   │   └── index.js     # General app configuration
│   ├── middleware/      # Express middleware
│   │   ├── auth.js      # JWT authentication middleware
│   │   └── validation.js # Request validation middleware
│   ├── models/          # Data models
│   │   └── User.js      # User model
│   ├── routes/          # Express routes
│   │   └── auth.js      # Authentication routes
│   ├── utils/           # Utility functions
│   ├── app.js           # Express app setup
│   └── server.js        # Server entry point
├── tests/
│   ├── unit/            # Unit tests
│   │   ├── auth.test.js # Authentication unit tests
│   │   └── middleware.test.js # Middleware unit tests
│   ├── integration/     # Integration tests
│   │   └── auth.integration.test.js # Auth integration tests
│   ├── fixtures/        # Test data fixtures
│   └── setup.js         # Test setup configuration
├── .env.example         # Environment variables template
├── .env.test           # Test environment variables
├── jest.config.js      # Jest configuration
└── package.json        # Project dependencies and scripts
```

## API Endpoints

### Authentication

- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user info (protected)

### Health Check

- `GET /health` - API health status

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `NODE_ENV` | Environment mode | `development` |
| `PORT` | Server port | `5000` |
| `DB_HOST` | Database host | `localhost` |
| `DB_PORT` | Database port | `5432` |
| `DB_NAME` | Database name | - |
| `DB_USER` | Database user | - |
| `DB_PASSWORD` | Database password | - |
| `JWT_SECRET` | JWT signing secret | - |
| `JWT_EXPIRES_IN` | JWT expiration time | `24h` |
| `CORS_ORIGIN` | Allowed CORS origin | `http://localhost:3000` |

## Testing

The project follows TDD principles with comprehensive test coverage:

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage
```

## Development

```bash
# Start development server with auto-reload
npm run dev

# Start production server
npm start
```

## Database Setup

1. Create PostgreSQL databases for development and testing
2. Update environment variables with database credentials
3. Run migrations (to be implemented)

## Security Features

- **Helmet**: Security headers
- **CORS**: Cross-origin resource sharing
- **Rate Limiting**: Prevent abuse
- **JWT Authentication**: Secure token-based auth
- **Password Hashing**: bcrypt with salt rounds
- **Input Validation**: Comprehensive request validation

## Next Steps

1. **Database Setup**: Create database migrations and seed files
2. **Recipe Management**: Implement recipe CRUD operations
3. **User Management**: Add user profile management
4. **File Upload**: Add recipe image upload functionality
5. **Search & Filtering**: Implement recipe search capabilities
6. **API Documentation**: Add Swagger/OpenAPI documentation
7. **Deployment**: Set up production deployment configuration

## Contributing

1. Follow TDD principles - write tests first
2. Use ES6+ syntax and modern JavaScript practices
3. Follow the existing code structure and naming conventions
4. Ensure all tests pass before committing changes

## License

MIT