# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the "Home Skillet" - a comprehensive home improvement and maintenance tracking application. The project is currently in the specification phase with detailed requirements documented in `home_maintenance_spec.md`.

## Project Architecture

This application is designed as a multi-platform property management system with the following key architectural components:

### Technology Stack (Planned)
- **Frontend**: Flutter for cross-platform mobile and web deployment
- **Backend**: TBD (considering Node.js, Python/Django, or .NET)
- **Database**: Relational database with document storage capability
- **Authentication**: OAuth 2.0 / OpenID Connect
- **File Storage**: Cloud storage (AWS S3 or Google Cloud Storage)

### Core Domain Model
The application centers around these primary entities:
- **Property**: Central entity representing real estate properties
- **User**: Multi-role system (Owner, Family, Contractor, Tenant, Realtor)
- **Project**: Home improvement projects with task lists and assignments
- **MaintenanceSchedule**: Recurring maintenance tasks and schedules
- **Document**: Warranties, receipts, photos, and other property documentation
- **Vendor**: Service providers and contractors

### Permission System
Complex role-based access control with granular permissions:
- Property-level and project-level permission assignments
- Time-limited access grants
- Different user types with varying access levels
- Multi-property support with property-specific permissions

### Key Features to Implement
1. **Project Management**: Task-based project tracking with assignments
2. **Maintenance Scheduling**: Automated reminders and recurring tasks
3. **Document Management**: OCR-enabled document storage and search
4. **Vendor Management**: Service provider profiles and work history
5. **Financial Tracking**: Budget management and cost analysis
6. **Multi-Property Support**: Manage multiple properties from single account

## Development Phases

The project is planned in three phases:
1. **Phase 1 (MVP)**: Basic auth, single property, simple projects and maintenance
2. **Phase 2**: Multi-property, advanced permissions, vendor and financial management
3. **Phase 3**: Advanced project management, integrations, and analytics

## Setup Instructions

### 1. Supabase Setup (Required)
1. Create project at [supabase.com](https://supabase.com)
2. Get your project details from Settings → Database
3. Copy connection string and API keys

### 2. Backend Setup
```bash
cd backend
npm install                    # Install dependencies

# Configure environment
cp .env.example .env
# Add your Supabase connection details to .env:
# SUPABASE_DB_URL=postgresql://postgres:YOUR_PASSWORD@db.YOUR_PROJECT_REF.supabase.co:5432/postgres

# Setup database
npm run db:setup              # Run migrations + seeds
npm test                      # Run all tests (45 tests)
npm run dev                   # Start development server
```

### 3. Mobile Setup  
```bash
cd mobile
flutter pub get               # Install dependencies

# Configure Supabase (create lib/config/.env)
echo "SUPABASE_URL=https://your-project.supabase.co" >> lib/config/.env
echo "SUPABASE_ANON_KEY=your-anon-key" >> lib/config/.env

flutter test                  # Run all tests
flutter run                   # Start development app
```

## Development Commands

### Backend (Node.js + Supabase)
```bash
cd backend
npm run migrate              # Run pending migrations
npm run migrate:rollback     # Rollback migrations  
npm run seed                 # Run seed data
npm run test:watch          # Run tests in watch mode
npm run test:coverage       # Run with coverage report
npm run dev                 # Start development server
```

### Database (Supabase PostgreSQL)
```bash
cd backend
npm run db:setup            # Setup complete database
npm run migrate:status      # Check migration status
npm run seed                # Add sample data
```

### Mobile (Flutter)
```bash
cd mobile
flutter pub get             # Install dependencies
flutter test               # Run all tests
flutter test --coverage    # Run with coverage
flutter run               # Start development app
flutter build apk         # Build Android APK
```

## API Endpoints

**Authentication:**
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `GET /api/auth/me` - Get current user (protected)

**Properties:**
- `GET /api/properties` - List user's properties
- `POST /api/properties` - Create new property
- `GET /api/properties/:id` - Get property details
- `PUT /api/properties/:id` - Update property
- `DELETE /api/properties/:id` - Delete property

**Projects:**
- `GET /api/projects` - List projects
- `POST /api/projects` - Create project with tasks
- `GET /api/projects/:id` - Get project details
- `PUT /api/projects/:id` - Update project
- `DELETE /api/projects/:id` - Delete project
- `POST /api/projects/:id/assign` - Assign user to project
- `DELETE /api/projects/:id/assign` - Remove user assignment

**Maintenance:**
- `GET /api/maintenance/schedules` - List maintenance schedules
- `POST /api/maintenance/schedules` - Create maintenance schedule
- `POST /api/maintenance/complete` - Mark maintenance complete

## Testing
- **Backend**: 45 tests passing (Jest + Supertest)
- **Database**: Schema and migration tests
- **Frontend**: Widget, unit, and integration tests

## Architecture Features

### 🚀 Real-time Capabilities (via Supabase)
- **Live Project Updates**: Instant sync across devices
- **Maintenance Notifications**: Real-time reminders
- **Collaborative Editing**: Multiple users on same project
- **Row Level Security**: Database-enforced multi-tenancy

### 🔧 Hybrid Architecture Options
- **Node.js Backend Mode** (Default): Traditional JWT + API
- **Supabase Mode**: Direct Supabase integration
- **Hybrid Mode**: Node.js auth + Supabase real-time

### 🔒 Security & Multi-tenancy
- Property-based data isolation
- Granular permission system (5 user roles)
- JWT authentication with bcrypt hashing
- Supabase Row Level Security policies

## Current Status

**✅ Phase 1 MVP Complete** - Full TDD + Supabase integration:
- ✅ JWT authentication system with 45 tests passing
- ✅ Multi-tenant property management with RLS
- ✅ Project management with real-time task updates
- ✅ Maintenance scheduling with live notifications  
- ✅ Flutter mobile app with Supabase real-time features
- ✅ Supabase PostgreSQL with 10 optimized migrations
- ✅ Row Level Security for enterprise-grade data isolation
- ✅ Comprehensive API documentation

**🎯 Ready for Production**: Full Supabase integration with real-time features, enterprise security, and scalable architecture!