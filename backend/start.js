const { spawn } = require('child_process');

console.log('🚀 Starting Home Skillet API...');
console.log(`📱 Environment: ${process.env.NODE_ENV}`);
console.log(`🗄️  Database URL: ${process.env.SUPABASE_DB_URL ? 'Configured' : 'Missing'}`);
console.log(`🗄️  Fallback Database URL: ${process.env.DATABASE_URL ? 'Configured' : 'Missing'}`);
console.log(`🪣 Supabase URL: ${process.env.SUPABASE_URL ? 'Configured' : 'Missing'}`);
console.log(`🔑 Supabase Service Key: ${process.env.SUPABASE_SERVICE_ROLE_KEY ? 'Configured' : 'Missing'}`);

// Check if we have database configuration
const hasDbConfig = process.env.SUPABASE_DB_URL || process.env.DATABASE_URL || 
  (process.env.DB_HOST && process.env.DB_NAME && process.env.DB_USER);

if (!hasDbConfig) {
  console.error('❌ No database configuration found!');
  console.error('   Please set SUPABASE_DB_URL or DATABASE_URL environment variable');
  console.error('   Example: postgresql://postgres:password@host:5432/database');
  process.exit(1);
}

// Skip migrations for now and start server directly
console.log('🚀 Starting server without migrations...');
console.log('⚠️  Note: Run migrations manually if needed');
startServer();

function startServer() {
  console.log('🚀 Starting server...');
  const server = spawn('node', ['src/server.js'], {
    stdio: 'inherit',
    env: process.env
  });

  server.on('error', (error) => {
    console.error('❌ Server process error:', error);
    process.exit(1);
  });

  server.on('close', (code) => {
    console.log(`Server process exited with code ${code}`);
    process.exit(code);
  });
}