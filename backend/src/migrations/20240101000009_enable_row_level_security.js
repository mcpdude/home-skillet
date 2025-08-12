/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = async function(knex) {
  // Skip Row Level Security for JWT auth setup
  // This can be enabled later when migrating to Supabase Auth
  console.log('Skipping Row Level Security setup - using JWT authentication');
  return;

  // Create policies for users table - users can only see/modify their own data
  await knex.raw(`
    CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid()::text = id::text);
  `);
  
  await knex.raw(`
    CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid()::text = id::text);
  `);

  // Create policies for properties table - based on ownership and permissions
  await knex.raw(`
    CREATE POLICY "Users can view accessible properties" ON properties
    FOR SELECT USING (
      owner_id = auth.uid()::int OR
      id IN (
        SELECT property_id FROM property_permissions 
        WHERE user_id = auth.uid()::int
      )
    );
  `);
  
  await knex.raw(`
    CREATE POLICY "Property owners can insert properties" ON properties
    FOR INSERT WITH CHECK (owner_id = auth.uid()::int);
  `);
  
  await knex.raw(`
    CREATE POLICY "Property owners and managers can update properties" ON properties
    FOR UPDATE USING (
      owner_id = auth.uid()::int OR
      id IN (
        SELECT property_id FROM property_permissions 
        WHERE user_id = auth.uid()::int AND role IN ('owner', 'manager')
      )
    );
  `);
  
  await knex.raw(`
    CREATE POLICY "Property owners can delete properties" ON properties
    FOR DELETE USING (owner_id = auth.uid()::int);
  `);

  // Create policies for property permissions
  await knex.raw(`
    CREATE POLICY "Users can view permissions for accessible properties" ON property_permissions
    FOR SELECT USING (
      property_id IN (
        SELECT id FROM properties WHERE owner_id = auth.uid()::int
      ) OR
      property_id IN (
        SELECT property_id FROM property_permissions 
        WHERE user_id = auth.uid()::int AND role IN ('owner', 'manager')
      )
    );
  `);
  
  await knex.raw(`
    CREATE POLICY "Property owners and managers can manage permissions" ON property_permissions
    FOR ALL USING (
      property_id IN (
        SELECT id FROM properties WHERE owner_id = auth.uid()::int
      ) OR
      property_id IN (
        SELECT property_id FROM property_permissions 
        WHERE user_id = auth.uid()::int AND role IN ('owner', 'manager')
      )
    );
  `);

  // Create policies for projects table
  await knex.raw(`
    CREATE POLICY "Users can view accessible projects" ON projects
    FOR SELECT USING (
      property_id IN (
        SELECT id FROM properties WHERE owner_id = auth.uid()::int
      ) OR
      property_id IN (
        SELECT property_id FROM property_permissions 
        WHERE user_id = auth.uid()::int
      ) OR
      id IN (
        SELECT project_id FROM project_assignments 
        WHERE user_id = auth.uid()::int
      )
    );
  `);
  
  await knex.raw(`
    CREATE POLICY "Users can create projects for accessible properties" ON projects
    FOR INSERT WITH CHECK (
      property_id IN (
        SELECT id FROM properties WHERE owner_id = auth.uid()::int
      ) OR
      property_id IN (
        SELECT property_id FROM property_permissions 
        WHERE user_id = auth.uid()::int AND role IN ('owner', 'manager')
      )
    );
  `);
  
  await knex.raw(`
    CREATE POLICY "Users can update accessible projects" ON projects
    FOR UPDATE USING (
      property_id IN (
        SELECT id FROM properties WHERE owner_id = auth.uid()::int
      ) OR
      property_id IN (
        SELECT property_id FROM property_permissions 
        WHERE user_id = auth.uid()::int AND role IN ('owner', 'manager')
      ) OR
      id IN (
        SELECT project_id FROM project_assignments 
        WHERE user_id = auth.uid()::int AND role IN ('lead', 'contributor')
      )
    );
  `);

  // Create policies for project tasks
  await knex.raw(`
    CREATE POLICY "Users can view tasks for accessible projects" ON project_tasks
    FOR SELECT USING (
      project_id IN (
        SELECT id FROM projects WHERE
          property_id IN (
            SELECT id FROM properties WHERE owner_id = auth.uid()::int
          ) OR
          property_id IN (
            SELECT property_id FROM property_permissions 
            WHERE user_id = auth.uid()::int
          ) OR
          id IN (
            SELECT project_id FROM project_assignments 
            WHERE user_id = auth.uid()::int
          )
      )
    );
  `);
  
  await knex.raw(`
    CREATE POLICY "Users can manage tasks for accessible projects" ON project_tasks
    FOR ALL USING (
      project_id IN (
        SELECT id FROM projects WHERE
          property_id IN (
            SELECT id FROM properties WHERE owner_id = auth.uid()::int
          ) OR
          property_id IN (
            SELECT property_id FROM property_permissions 
            WHERE user_id = auth.uid()::int AND role IN ('owner', 'manager')
          ) OR
          id IN (
            SELECT project_id FROM project_assignments 
            WHERE user_id = auth.uid()::int AND role IN ('lead', 'contributor')
          )
      )
    );
  `);

  // Create policies for maintenance schedules
  await knex.raw(`
    CREATE POLICY "Users can view maintenance schedules for accessible properties" ON maintenance_schedules
    FOR SELECT USING (
      property_id IN (
        SELECT id FROM properties WHERE owner_id = auth.uid()::int
      ) OR
      property_id IN (
        SELECT property_id FROM property_permissions 
        WHERE user_id = auth.uid()::int
      )
    );
  `);
  
  await knex.raw(`
    CREATE POLICY "Users can manage maintenance schedules for accessible properties" ON maintenance_schedules
    FOR ALL USING (
      property_id IN (
        SELECT id FROM properties WHERE owner_id = auth.uid()::int
      ) OR
      property_id IN (
        SELECT property_id FROM property_permissions 
        WHERE user_id = auth.uid()::int AND role IN ('owner', 'manager', 'maintainer')
      )
    );
  `);

  // Create policies for maintenance records
  await knex.raw(`
    CREATE POLICY "Users can view maintenance records for accessible schedules" ON maintenance_records
    FOR SELECT USING (
      schedule_id IN (
        SELECT id FROM maintenance_schedules WHERE
          property_id IN (
            SELECT id FROM properties WHERE owner_id = auth.uid()::int
          ) OR
          property_id IN (
            SELECT property_id FROM property_permissions 
            WHERE user_id = auth.uid()::int
          )
      )
    );
  `);
  
  await knex.raw(`
    CREATE POLICY "Users can manage maintenance records for accessible schedules" ON maintenance_records
    FOR ALL USING (
      schedule_id IN (
        SELECT id FROM maintenance_schedules WHERE
          property_id IN (
            SELECT id FROM properties WHERE owner_id = auth.uid()::int
          ) OR
          property_id IN (
            SELECT property_id FROM property_permissions 
            WHERE user_id = auth.uid()::int AND role IN ('owner', 'manager', 'maintainer')
          )
      )
    );
  `);
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = async function(knex) {
  // Drop all RLS policies (they will be automatically removed when RLS is disabled)
  const tables = [
    'users', 'properties', 'property_permissions', 'projects', 
    'project_tasks', 'project_assignments', 'maintenance_schedules', 
    'maintenance_records'
  ];
  
  for (const table of tables) {
    await knex.raw(`ALTER TABLE ${table} DISABLE ROW LEVEL SECURITY;`);
  }
};