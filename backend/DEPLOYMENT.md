# Railway Deployment Guide

## Environment Variables Required

Set these environment variables in your Railway project:

### Database Configuration
```
SUPABASE_DB_URL=postgresql://postgres:your_password@db.your_project_ref.supabase.co:5432/postgres
```

### Supabase Storage Configuration  
```
SUPABASE_URL=https://your_project_ref.supabase.co
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

### JWT Configuration
```
JWT_SECRET=your_very_secure_random_string_here
```

### Optional Configuration
```
NODE_ENV=production
API_VERSION=v1
PORT=3000
```

## Deployment Steps

1. **Create Railway Project**
   ```bash
   railway login
   railway init
   railway add
   ```

2. **Set Environment Variables**
   ```bash
   railway variables set SUPABASE_DB_URL="postgresql://postgres:password@db.ref.supabase.co:5432/postgres"
   railway variables set SUPABASE_URL="https://your_project_ref.supabase.co"
   railway variables set SUPABASE_ANON_KEY="your_anon_key"
   railway variables set SUPABASE_SERVICE_ROLE_KEY="your_service_role_key"
   railway variables set JWT_SECRET="your_jwt_secret"
   ```

3. **Deploy**
   ```bash
   railway up
   ```

## Troubleshooting

### Healthcheck Failures
If you see "Network healthcheck failure", check:

1. **Environment Variables**: Visit `/health/db-simple` to test database connection
2. **Database Migrations**: Check deployment logs for migration errors
3. **Startup Logs**: Look for configuration issues in the build logs

### Debug Endpoints
- `/health` - Basic app health (no database)
- `/health/db` - Database connection via Knex
- `/health/db-simple` - Direct database connection test
- `/` - Root endpoint with basic info

### Common Issues
1. **Missing SUPABASE_DB_URL**: App will exit with error message
2. **Database Connection Timeout**: Reduce connection pool settings
3. **Migration Failures**: Ensure Supabase database is accessible

## Health Check Configuration

The app includes multiple health check endpoints:
- Railway uses `/health` endpoint
- 300 second timeout with 30 second intervals
- Automatic database migrations on production startup