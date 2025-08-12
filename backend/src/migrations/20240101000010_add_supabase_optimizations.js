/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = async function(knex) {
  // Add composite indexes for better query performance
  await knex.raw('CREATE INDEX idx_properties_owner_type ON properties(owner_id, type);');
  await knex.raw('CREATE INDEX idx_projects_property_status ON projects(property_id, status);');
  await knex.raw('CREATE INDEX idx_project_tasks_project_status ON project_tasks(project_id, status);');
  await knex.raw('CREATE INDEX idx_maintenance_schedules_property_active ON maintenance_schedules(property_id, is_active);');
  
  // Add partial indexes for active records only (Supabase optimization)
  await knex.raw('CREATE INDEX idx_active_maintenance_schedules ON maintenance_schedules(next_due_date) WHERE is_active = true;');
  await knex.raw('CREATE INDEX idx_active_projects ON projects(due_date) WHERE status != \'completed\' AND status != \'cancelled\';');
  await knex.raw('CREATE INDEX idx_pending_tasks ON project_tasks(due_date) WHERE status = \'pending\';');
  
  // Add text search capabilities (Supabase supports full-text search)
  await knex.raw('ALTER TABLE properties ADD COLUMN search_vector tsvector;');
  await knex.raw('ALTER TABLE projects ADD COLUMN search_vector tsvector;');
  
  // Create GIN indexes for text search
  await knex.raw('CREATE INDEX idx_properties_search ON properties USING gin(search_vector);');
  await knex.raw('CREATE INDEX idx_projects_search ON projects USING gin(search_vector);');
  
  // Create triggers to automatically update search vectors
  await knex.raw(`
    CREATE OR REPLACE FUNCTION update_properties_search_vector() RETURNS trigger AS $$
    BEGIN
      NEW.search_vector := to_tsvector('english', 
        COALESCE(NEW.name, '') || ' ' ||
        COALESCE(NEW.description, '') || ' ' ||
        COALESCE(NEW.address, '') || ' ' ||
        COALESCE(NEW.type, '')
      );
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
  `);
  
  await knex.raw(`
    CREATE OR REPLACE FUNCTION update_projects_search_vector() RETURNS trigger AS $$
    BEGIN
      NEW.search_vector := to_tsvector('english', 
        COALESCE(NEW.title, '') || ' ' ||
        COALESCE(NEW.description, '')
      );
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
  `);
  
  // Create triggers
  await knex.raw(`
    CREATE TRIGGER update_properties_search_vector_trigger
    BEFORE INSERT OR UPDATE ON properties
    FOR EACH ROW EXECUTE FUNCTION update_properties_search_vector();
  `);
  
  await knex.raw(`
    CREATE TRIGGER update_projects_search_vector_trigger
    BEFORE INSERT OR UPDATE ON projects
    FOR EACH ROW EXECUTE FUNCTION update_projects_search_vector();
  `);
  
  // Update existing records
  await knex.raw(`
    UPDATE properties SET search_vector = to_tsvector('english', 
      COALESCE(name, '') || ' ' ||
      COALESCE(description, '') || ' ' ||
      COALESCE(address, '') || ' ' ||
      COALESCE(type, '')
    );
  `);
  
  await knex.raw(`
    UPDATE projects SET search_vector = to_tsvector('english', 
      COALESCE(title, '') || ' ' ||
      COALESCE(description, '')
    );
  `);
  
  // Add check constraints for data integrity
  await knex.raw("ALTER TABLE properties ADD CONSTRAINT chk_properties_type CHECK (type IN ('residential', 'commercial', 'industrial', 'mixed-use'));");
  await knex.raw("ALTER TABLE projects ADD CONSTRAINT chk_projects_status CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled', 'on_hold'));");
  await knex.raw("ALTER TABLE projects ADD CONSTRAINT chk_projects_priority CHECK (priority IN ('low', 'medium', 'high', 'urgent'));");
  await knex.raw("ALTER TABLE project_tasks ADD CONSTRAINT chk_tasks_status CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled'));");
  await knex.raw("ALTER TABLE property_permissions ADD CONSTRAINT chk_permissions_role CHECK (role IN ('owner', 'manager', 'viewer', 'maintainer'));");
  await knex.raw("ALTER TABLE project_assignments ADD CONSTRAINT chk_assignments_role CHECK (role IN ('lead', 'contributor', 'viewer'));");
  await knex.raw("ALTER TABLE maintenance_schedules ADD CONSTRAINT chk_maintenance_frequency CHECK (frequency IN ('daily', 'weekly', 'monthly', 'quarterly', 'yearly', 'custom'));");
  
  // Add budget validation constraints
  await knex.raw("ALTER TABLE projects ADD CONSTRAINT chk_projects_budget CHECK (budget >= 0);");
  await knex.raw("ALTER TABLE projects ADD CONSTRAINT chk_projects_actual_cost CHECK (actual_cost >= 0);");
  await knex.raw("ALTER TABLE project_tasks ADD CONSTRAINT chk_tasks_cost CHECK (cost >= 0);");
  await knex.raw("ALTER TABLE project_tasks ADD CONSTRAINT chk_tasks_hours CHECK (estimated_hours >= 0 AND actual_hours >= 0);");
  
  // Add date validation constraints
  await knex.raw("ALTER TABLE projects ADD CONSTRAINT chk_projects_dates CHECK (start_date <= end_date);");
  
  // Create a function to calculate project progress (Supabase-specific utility)
  await knex.raw(`
    CREATE OR REPLACE FUNCTION calculate_project_progress(project_uuid uuid)
    RETURNS numeric AS $$
    DECLARE
      total_tasks integer;
      completed_tasks integer;
    BEGIN
      SELECT COUNT(*) INTO total_tasks 
      FROM project_tasks 
      WHERE project_id = project_uuid;
      
      IF total_tasks = 0 THEN
        RETURN 0;
      END IF;
      
      SELECT COUNT(*) INTO completed_tasks 
      FROM project_tasks 
      WHERE project_id = project_uuid AND status = 'completed';
      
      RETURN ROUND((completed_tasks::numeric / total_tasks::numeric) * 100, 2);
    END;
    $$ LANGUAGE plpgsql;
  `);
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = async function(knex) {
  // Drop function
  await knex.raw('DROP FUNCTION IF EXISTS calculate_project_progress(uuid);');
  
  // Drop triggers
  await knex.raw('DROP TRIGGER IF EXISTS update_projects_search_vector_trigger ON projects;');
  await knex.raw('DROP TRIGGER IF EXISTS update_properties_search_vector_trigger ON properties;');
  
  // Drop functions
  await knex.raw('DROP FUNCTION IF EXISTS update_projects_search_vector();');
  await knex.raw('DROP FUNCTION IF EXISTS update_properties_search_vector();');
  
  // Drop search indexes
  await knex.raw('DROP INDEX IF EXISTS idx_projects_search;');
  await knex.raw('DROP INDEX IF EXISTS idx_properties_search;');
  
  // Remove search vector columns
  await knex.raw('ALTER TABLE projects DROP COLUMN IF EXISTS search_vector;');
  await knex.raw('ALTER TABLE properties DROP COLUMN IF EXISTS search_vector;');
  
  // Drop partial indexes
  await knex.raw('DROP INDEX IF EXISTS idx_pending_tasks;');
  await knex.raw('DROP INDEX IF EXISTS idx_active_projects;');
  await knex.raw('DROP INDEX IF EXISTS idx_active_maintenance_schedules;');
  
  // Drop composite indexes
  await knex.raw('DROP INDEX IF EXISTS idx_maintenance_schedules_property_active;');
  await knex.raw('DROP INDEX IF EXISTS idx_project_tasks_project_status;');
  await knex.raw('DROP INDEX IF EXISTS idx_projects_property_status;');
  await knex.raw('DROP INDEX IF EXISTS idx_properties_owner_type;');
  
  // Drop check constraints
  const constraints = [
    'chk_projects_dates', 'chk_tasks_hours', 'chk_tasks_cost', 'chk_projects_actual_cost',
    'chk_projects_budget', 'chk_maintenance_frequency', 'chk_assignments_role', 
    'chk_permissions_role', 'chk_tasks_status', 'chk_projects_priority', 
    'chk_projects_status', 'chk_properties_type'
  ];
  
  for (const constraint of constraints) {
    await knex.raw(`ALTER TABLE properties DROP CONSTRAINT IF EXISTS ${constraint};`);
    await knex.raw(`ALTER TABLE projects DROP CONSTRAINT IF EXISTS ${constraint};`);
    await knex.raw(`ALTER TABLE project_tasks DROP CONSTRAINT IF EXISTS ${constraint};`);
    await knex.raw(`ALTER TABLE property_permissions DROP CONSTRAINT IF EXISTS ${constraint};`);
    await knex.raw(`ALTER TABLE project_assignments DROP CONSTRAINT IF EXISTS ${constraint};`);
    await knex.raw(`ALTER TABLE maintenance_schedules DROP CONSTRAINT IF EXISTS ${constraint};`);
  }
};