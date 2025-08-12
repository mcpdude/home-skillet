# Supabase Database Setup Guide

This guide explains how to set up your Home Skillet backend to work with Supabase PostgreSQL.

## Prerequisites

1. A Supabase account (sign up at https://supabase.com)
2. Node.js and npm installed
3. The required dependencies installed (`npm install`)

## Step 1: Create a Supabase Project

1. Go to https://supabase.com/dashboard
2. Click "New Project"
3. Choose your organization
4. Fill in your project details:
   - Project name: `home-skillet`
   - Database password: Choose a strong password
   - Region: Select the closest region to your users

## Step 2: Get Your Database Connection Details

After your project is created:

1. Go to **Settings** → **Database**
2. Scroll down to **Connection Info**
3. Copy the connection details:
   - Host: `db.<your-project-ref>.supabase.co`
   - Database name: `postgres`
   - Port: `5432`
   - User: `postgres`
   - Password: The password you set during project creation

## Step 3: Configure Environment Variables

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Update the `.env` file with your Supabase details:
   ```env
   NODE_ENV=development
   
   # Replace with your actual Supabase connection details
   SUPABASE_DB_URL=postgresql://postgres:YOUR_PASSWORD@db.YOUR_PROJECT_REF.supabase.co:5432/postgres
   
   # Alternative format (if you prefer individual parameters)
   DB_HOST=db.YOUR_PROJECT_REF.supabase.co
   DB_PORT=5432
   DB_NAME=postgres
   DB_USER=postgres
   DB_PASSWORD=YOUR_PASSWORD
   
   # Add other required environment variables
   JWT_SECRET=your_super_secret_jwt_key_here
   PORT=3000
   ```

## Step 4: Run Database Migrations

Once your environment is configured, run the migrations to set up your database schema:

```bash
# Run all migrations
npm run migrate

# Check migration status
npm run migrate:status

# Seed the database with sample data
npm run seed

# Or run both migrations and seeds
npm run db:setup
```

## Step 5: Verify Setup

1. Go to your Supabase dashboard
2. Navigate to **Table Editor**
3. You should see all the created tables:
   - users
   - properties
   - property_permissions
   - projects
   - project_tasks
   - project_assignments
   - maintenance_schedules
   - maintenance_records

## Supabase-Specific Features Implemented

### 1. SSL Configuration
- Automatic SSL connection for production environments
- Proper connection pooling optimized for Supabase

### 2. Row Level Security (RLS)
- Enabled RLS on all tables for multi-tenant security
- Policies ensure users can only access their own data
- Property-based access control for collaborative features

### 3. Performance Optimizations
- Composite indexes for complex queries
- Partial indexes for active records only
- Full-text search capabilities with GIN indexes

### 4. Data Integrity
- Check constraints for valid enum values
- Foreign key relationships with proper cascade rules
- Budget and date validation constraints

### 5. Supabase Utilities
- Custom PostgreSQL functions for calculated fields
- Automatic search vector updates with triggers
- Project progress calculation function

## Available NPM Scripts

- `npm run migrate` - Run pending migrations
- `npm run migrate:rollback` - Rollback the last migration
- `npm run migrate:status` - Check migration status
- `npm run seed` - Run database seeds
- `npm run db:setup` - Run migrations and seeds together

## Connection Troubleshooting

### Issue: Connection Refused
- Verify your Supabase project is active
- Check your connection string format
- Ensure your IP is allowed (Supabase allows all IPs by default)

### Issue: Authentication Failed
- Double-check your database password
- Ensure you're using the `postgres` user
- Verify the project reference in your connection string

### Issue: SSL Errors
- Make sure SSL is properly configured in your connection settings
- For development, you can disable SSL by setting `ssl: false` in database config

## Security Notes

1. **Row Level Security**: All tables have RLS enabled. Users can only access:
   - Their own user profile
   - Properties they own or have been granted access to
   - Projects and tasks for accessible properties
   - Maintenance data for accessible properties

2. **Environment Variables**: Never commit your `.env` file to version control. The database password should be kept secure.

3. **Connection Pooling**: The configuration includes proper connection pooling settings optimized for Supabase's connection limits.

## Next Steps

After setting up the database:

1. Test your API endpoints
2. Configure your frontend to connect to the backend
3. Consider setting up Supabase Auth for user authentication
4. Review and customize the RLS policies based on your specific business rules

For more advanced Supabase features, refer to the [Supabase Documentation](https://supabase.com/docs).