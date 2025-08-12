# Home Skillet Database

This directory contains the database schema, migrations, and seed data for the Home Skillet application.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Copy environment variables:
```bash
cp .env.example .env
```

3. Update the `.env` file with your database credentials.

4. Run migrations and seeds:
```bash
npm run db:setup
```

## Available Commands

- `npm run migrate:latest` - Run all pending migrations
- `npm run migrate:rollback` - Rollback the last migration batch
- `npm run migrate:make <name>` - Create a new migration file
- `npm run seed:run` - Run all seed files
- `npm run seed:make <name>` - Create a new seed file
- `npm run test` - Run database tests

## Schema Overview

The database is designed with multi-tenant architecture using property-based isolation. Key entities include:

- **users** - User authentication and profile information
- **properties** - Property details and configuration
- **user_property_roles** - Permission assignments (multi-tenant)
- **projects** - Project information and management
- **tasks** - Individual project tasks
- **maintenance_schedules** - Recurring maintenance definitions
- **maintenance_records** - Completed maintenance logs
- **documents** - File storage metadata
- **vendors** - Service provider information
- **project_assignments** - Project-user assignments

## Permission System

The application uses a granular permission system with the following roles:
- Owner: Full administrative control
- Family: Configurable permissions per property
- Contractor: Limited access to assigned projects
- Tenant: Access to maintenance requests and property info
- Realtor: Read-only access to property history