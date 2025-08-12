-- Check existing users table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;

-- Also check if there are any existing users
SELECT COUNT(*) as user_count FROM users;

-- Show first few rows if any exist
SELECT * FROM users LIMIT 3;