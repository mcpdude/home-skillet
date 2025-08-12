# Home Skillet API Documentation

## Overview

The Home Skillet API is a comprehensive REST API for property management and home improvement tracking. Built following TDD principles with full test coverage, it provides authentication, multi-tenant data isolation, and comprehensive CRUD operations for all core entities.

## Base URL
- Development: `http://localhost:3001/api/v1`
- Test Environment: `http://localhost:3001/api/v1`

## Authentication

All endpoints (except registration and login) require JWT authentication via the `Authorization` header:

```
Authorization: Bearer <your_jwt_token>
```

### User Types
- `property_owner`: Full administrative control
- `family_member`: Configurable permissions per property
- `contractor`: Limited access to assigned projects
- `tenant`: Access to maintenance requests and property info
- `realtor`: Read-only access to property history

## API Endpoints

### Authentication
- `POST /auth/register` - Register a new user
- `POST /auth/login` - Authenticate and get JWT token
- `GET /auth/me` - Get current user profile
- `PUT /auth/me` - Update current user profile
- `POST /auth/logout` - Logout (client-side token removal)

### Properties
- `POST /properties` - Create a new property
- `GET /properties` - Get all user-accessible properties
- `GET /properties/:id` - Get specific property details
- `PUT /properties/:id` - Update property (owner only)
- `DELETE /properties/:id` - Delete property (owner only)

### Projects
- `POST /projects` - Create a new project
- `GET /projects` - Get all user-accessible projects
- `GET /projects/:id` - Get specific project details
- `PUT /projects/:id` - Update project
- `DELETE /projects/:id` - Delete project
- `POST /projects/:id/assign` - Assign user to project
- `DELETE /projects/:id/assign/:userId` - Unassign user from project
- `GET /projects/:id/assignments` - Get project assignments

### Users & Permissions
- `GET /users` - Get all users
- `GET /users/:id` - Get specific user details
- `PUT /users/:id` - Update user profile
- `POST /users/properties/:propertyId/permissions` - Grant property permissions
- `GET /users/properties/:propertyId/permissions` - Get property permissions
- `PUT /users/properties/:propertyId/permissions/:userId` - Update permissions
- `DELETE /users/properties/:propertyId/permissions/:userId` - Revoke permissions

### Maintenance Schedules
- `POST /maintenance-schedules` - Create maintenance schedule
- `GET /maintenance-schedules` - Get all user-accessible schedules
- `GET /maintenance-schedules/:id` - Get specific schedule details
- `PUT /maintenance-schedules/:id` - Update schedule
- `DELETE /maintenance-schedules/:id` - Delete schedule
- `POST /maintenance-schedules/:id/complete` - Mark maintenance completed
- `GET /maintenance-schedules/:id/history` - Get completion history
- `GET /maintenance-schedules/due` - Get overdue/due schedules

### Health Check
- `GET /health` - API health status

## Request/Response Format

### Standard Response Structure
```json
{
  "success": true,
  "data": {
    // Response data here
  }
}
```

### Error Response Structure
```json
{
  "success": false,
  "error": {
    "message": "Error description",
    "details": [] // Additional validation details if applicable
  }
}
```

### HTTP Status Codes
- `200` - Success
- `201` - Created
- `400` - Bad Request (validation errors)
- `401` - Unauthorized (missing/invalid token)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `409` - Conflict (duplicate resource)
- `429` - Too Many Requests (rate limited)
- `500` - Internal Server Error

## Example API Usage

### Register a New User
```bash
curl -X POST http://localhost:3001/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "SecurePass123!",
    "firstName": "John",
    "lastName": "Doe",
    "userType": "property_owner"
  }'
```

### Login
```bash
curl -X POST http://localhost:3001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "SecurePass123!"
  }'
```

### Create a Property
```bash
curl -X POST http://localhost:3001/api/v1/properties \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "name": "My Family Home",
    "address": {
      "street": "123 Main St",
      "city": "Anytown",
      "state": "CA",
      "zipCode": "12345",
      "country": "USA"
    },
    "propertyType": "single_family",
    "yearBuilt": 1995,
    "squareFootage": 2500
  }'
```

### Create a Project
```bash
curl -X POST http://localhost:3001/api/v1/projects \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "title": "Kitchen Renovation",
    "description": "Complete kitchen remodel",
    "category": "interior",
    "priority": "high",
    "propertyId": "property-uuid",
    "tasks": [
      {
        "title": "Remove old cabinets",
        "description": "Demo existing kitchen cabinets",
        "completed": false
      },
      {
        "title": "Install new countertops",
        "description": "Install granite countertops",
        "completed": false
      }
    ]
  }'
```

## Data Models

### User
```javascript
{
  id: "uuid",
  email: "string",
  firstName: "string",
  lastName: "string",
  userType: "property_owner|family_member|contractor|tenant|realtor",
  createdAt: "ISO datetime",
  updatedAt: "ISO datetime"
}
```

### Property
```javascript
{
  id: "uuid",
  name: "string",
  address: {
    street: "string",
    city: "string", 
    state: "string",
    zipCode: "string",
    country: "string"
  },
  propertyType: "single_family|condo|townhouse|apartment|mobile_home|other",
  yearBuilt: "number",
  squareFootage: "number",
  bedrooms: "number",
  bathrooms: "number",
  description: "string",
  ownerId: "uuid",
  createdAt: "ISO datetime",
  updatedAt: "ISO datetime"
}
```

### Project
```javascript
{
  id: "uuid",
  title: "string",
  description: "string",
  category: "plumbing|electrical|hvac|interior|exterior|cosmetic|landscaping|other",
  priority: "low|medium|high|urgent",
  status: "not_started|in_progress|completed|on_hold|cancelled",
  propertyId: "uuid",
  createdBy: "uuid",
  estimatedCompletionDate: "ISO datetime",
  actualCompletionDate: "ISO datetime",
  tasks: [
    {
      id: "uuid",
      title: "string",
      description: "string",
      completed: "boolean",
      completedDate: "ISO datetime",
      createdAt: "ISO datetime",
      updatedAt: "ISO datetime"
    }
  ],
  createdAt: "ISO datetime",
  updatedAt: "ISO datetime"
}
```

### Maintenance Schedule
```javascript
{
  id: "uuid",
  title: "string",
  description: "string",
  category: "hvac|plumbing|electrical|exterior|interior|appliances|safety|landscaping|other",
  propertyId: "uuid",
  frequency: "daily|weekly|biweekly|monthly|quarterly|biannual|yearly|seasonal|as_needed",
  priority: "low|medium|high|urgent",
  estimatedDuration: "number (minutes)",
  instructions: "string",
  nextDueDate: "ISO datetime",
  lastCompletedDate: "ISO datetime",
  isActive: "boolean",
  createdBy: "uuid",
  createdAt: "ISO datetime",
  updatedAt: "ISO datetime"
}
```

## Security Features

- JWT token-based authentication
- Password hashing with bcrypt (12 rounds)
- Request rate limiting (100 requests per 15 minutes)
- CORS protection
- Helmet.js security headers
- Multi-tenant data isolation
- Role-based permission system
- Input validation with Joi schemas

## Error Handling

The API includes comprehensive error handling:
- Validation errors with detailed field-level messages
- Authentication/authorization errors
- Not found errors for invalid resources
- Conflict errors for duplicate data
- Rate limiting errors
- Internal server errors with proper logging

## Testing

The API includes comprehensive test coverage:
- **45 passing tests** across all endpoints
- **Integration tests** covering full request/response cycles
- **Unit tests** for middleware and utilities
- **Test coverage** for all major code paths
- **Error scenario testing** for proper error handling

### Running Tests
```bash
# Run all tests
npm test

# Run with coverage report
npm run test:coverage

# Run in watch mode during development
npm run test:watch
```

## Development

### Prerequisites
- Node.js 16+
- npm or yarn

### Setup
1. Clone the repository
2. Navigate to backend directory
3. Install dependencies: `npm install`
4. Copy `.env.example` to `.env` and configure
5. Start development server: `npm run dev`
6. Run tests: `npm test`

### Environment Variables
```bash
NODE_ENV=development
PORT=3001
JWT_SECRET=your_super_secret_jwt_key
JWT_EXPIRES_IN=7d
API_VERSION=v1
```

## Production Considerations

For production deployment, consider:

1. **Database Integration**: Replace in-memory storage with proper database (PostgreSQL, MySQL, etc.)
2. **Environment Security**: Use proper environment variable management
3. **Logging**: Implement structured logging (Winston, Pino)
4. **Monitoring**: Add health checks and metrics
5. **Caching**: Implement Redis for session/data caching  
6. **Load Balancing**: Use reverse proxy (Nginx) for multiple instances
7. **HTTPS**: Ensure all communication is encrypted
8. **Database Migrations**: Implement proper schema versioning
9. **Backup Strategy**: Automated database backups
10. **Container Deployment**: Dockerize for consistent deployments

## Support

For issues or questions regarding the API, please refer to the test suite for comprehensive usage examples, or contact the development team.