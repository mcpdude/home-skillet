-- Home Skillet Database Setup for Supabase
-- Run this in your Supabase SQL Editor

-- Create migrations tracking table
CREATE TABLE IF NOT EXISTS knex_migrations (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  batch INTEGER NOT NULL,
  migration_time TIMESTAMPTZ DEFAULT NOW()
);

-- Core users table (if not exists)
CREATE TABLE IF NOT EXISTS users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  role VARCHAR(20) DEFAULT 'user',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Properties table
CREATE TABLE IF NOT EXISTS properties (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  address TEXT,
  property_type VARCHAR(50),
  year_built INTEGER,
  square_footage INTEGER,
  bedrooms INTEGER,
  bathrooms DECIMAL(3,1),
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Projects table
CREATE TABLE IF NOT EXISTS projects (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  status VARCHAR(20) DEFAULT 'planning',
  priority VARCHAR(10) DEFAULT 'medium',
  budget DECIMAL(12, 2),
  start_date DATE,
  end_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tasks table
CREATE TABLE IF NOT EXISTS tasks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  status VARCHAR(20) DEFAULT 'pending',
  priority VARCHAR(10) DEFAULT 'medium',
  due_date DATE,
  estimated_hours DECIMAL(5, 2),
  actual_hours DECIMAL(5, 2),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Documents table
CREATE TABLE IF NOT EXISTS documents (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  filename VARCHAR(255) NOT NULL,
  original_filename VARCHAR(255) NOT NULL,
  file_url TEXT NOT NULL,
  file_size INTEGER,
  mime_type VARCHAR(100),
  file_hash VARCHAR(64),
  category VARCHAR(50) DEFAULT 'general',
  description TEXT,
  tags JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insurance Items table
CREATE TABLE IF NOT EXISTS insurance_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  category VARCHAR(50) NOT NULL,
  room_location VARCHAR(100),
  brand VARCHAR(100),
  model VARCHAR(100),
  serial_number VARCHAR(100),
  purchase_date DATE,
  purchase_price DECIMAL(12, 2),
  replacement_cost DECIMAL(12, 2),
  condition VARCHAR(20) DEFAULT 'good',
  is_insured BOOLEAN DEFAULT false,
  notes TEXT,
  tags JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insurance Item Photos table
CREATE TABLE IF NOT EXISTS insurance_item_photos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  item_id UUID NOT NULL REFERENCES insurance_items(id) ON DELETE CASCADE,
  filename VARCHAR(255) NOT NULL,
  file_url TEXT NOT NULL,
  photo_type VARCHAR(20) DEFAULT 'overview',
  file_size INTEGER,
  file_hash VARCHAR(64),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insurance Item Documents table
CREATE TABLE IF NOT EXISTS insurance_item_documents (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  item_id UUID NOT NULL REFERENCES insurance_items(id) ON DELETE CASCADE,
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  document_type VARCHAR(50) DEFAULT 'receipt',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insurance Valuations table
CREATE TABLE IF NOT EXISTS insurance_valuations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  item_id UUID NOT NULL REFERENCES insurance_items(id) ON DELETE CASCADE,
  valuation_type VARCHAR(50) NOT NULL,
  amount DECIMAL(12, 2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'USD',
  valuation_date DATE NOT NULL,
  appraiser_name VARCHAR(255),
  notes TEXT,
  document_id UUID REFERENCES documents(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insurance Reports table
CREATE TABLE IF NOT EXISTS insurance_inventory_reports (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
  report_name VARCHAR(255) NOT NULL,
  description TEXT,
  filters JSONB,
  total_items INTEGER,
  total_value DECIMAL(15, 2),
  generated_at TIMESTAMPTZ DEFAULT NOW(),
  report_data JSONB
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_properties_user_id ON properties(user_id);
CREATE INDEX IF NOT EXISTS idx_projects_property_id ON projects(property_id);
CREATE INDEX IF NOT EXISTS idx_projects_user_id ON projects(user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_project_id ON tasks(project_id);
CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_documents_user_id ON documents(user_id);
CREATE INDEX IF NOT EXISTS idx_documents_property_id ON documents(property_id);
CREATE INDEX IF NOT EXISTS idx_insurance_items_user_id ON insurance_items(user_id);
CREATE INDEX IF NOT EXISTS idx_insurance_items_property_id ON insurance_items(property_id);
CREATE INDEX IF NOT EXISTS idx_insurance_item_photos_item_id ON insurance_item_photos(item_id);
CREATE INDEX IF NOT EXISTS idx_insurance_item_documents_item_id ON insurance_item_documents(item_id);

-- Record this migration
INSERT INTO knex_migrations (name, batch) 
VALUES ('20250812000004_create_insurance_inventory_system.js', 1)
ON CONFLICT DO NOTHING;

-- Success message
SELECT 'Home Skillet database setup completed successfully!' as result;