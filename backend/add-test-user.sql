-- Add a test user with known password
-- Password will be 'password123' 
INSERT INTO users (email, password, first_name, last_name, user_type, created_at, updated_at) 
VALUES (
  'test@homeskillet.com', 
  '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 
  'Test', 
  'User', 
  'admin',
  NOW(),
  NOW()
) ON CONFLICT (email) DO UPDATE SET
  password = EXCLUDED.password,
  user_type = EXCLUDED.user_type,
  updated_at = NOW();

-- Verify the user was created/updated
SELECT id, email, first_name, last_name, user_type, created_at 
FROM users 
WHERE email = 'test@homeskillet.com';

SELECT 'Test user created! Email: test@homeskillet.com, Password: password123' as result;