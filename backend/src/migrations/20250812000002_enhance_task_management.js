/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema
    // First, enhance the project_tasks table
    .alterTable('project_tasks', function(table) {
      // Add progress tracking
      table.integer('progress_percentage').defaultTo(0);
      table.text('notes');
      table.timestamp('status_updated_at');
      table.timestamp('completed_at');
      table.string('priority', 50).defaultTo('medium'); // low, medium, high, urgent
    })
    // Create task_time_tracking table for time tracking
    .createTable('task_time_tracking', function(table) {
      if (knex.client.config.client === 'sqlite3') {
        table.string('id').primary();
        table.string('task_id').notNullable();
        table.string('user_id').notNullable();
      } else {
        table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
        table.uuid('task_id').notNullable();
        table.uuid('user_id').notNullable();
      }
      table.timestamp('started_at').notNullable();
      table.timestamp('ended_at');
      table.integer('duration_minutes').defaultTo(0);
      table.text('description');
      table.boolean('is_active').defaultTo(true);
      table.timestamps(true, true);
      
      // Foreign key constraints
      table.foreign('task_id').references('id').inTable('project_tasks').onDelete('CASCADE');
      table.foreign('user_id').references('id').inTable('users').onDelete('CASCADE');
      
      // Indexes
      table.index(['task_id'], 'idx_time_tracking_task_id');
      table.index(['user_id'], 'idx_time_tracking_user_id');
      table.index(['is_active'], 'idx_time_tracking_is_active');
    })
    // Create task_comments table for comments and updates
    .createTable('task_comments', function(table) {
      if (knex.client.config.client === 'sqlite3') {
        table.string('id').primary();
        table.string('task_id').notNullable();
        table.string('user_id').notNullable();
      } else {
        table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
        table.uuid('task_id').notNullable();
        table.uuid('user_id').notNullable();
      }
      table.text('content').notNullable();
      table.string('type', 50).defaultTo('comment'); // comment, status_update, system
      table.json('metadata'); // For additional data like old/new status values
      table.timestamps(true, true);
      
      // Foreign key constraints
      table.foreign('task_id').references('id').inTable('project_tasks').onDelete('CASCADE');
      table.foreign('user_id').references('id').inTable('users').onDelete('CASCADE');
      
      // Indexes
      table.index(['task_id'], 'idx_task_comments_task_id');
      table.index(['user_id'], 'idx_task_comments_user_id');
      table.index(['type'], 'idx_task_comments_type');
      table.index(['created_at'], 'idx_task_comments_created_at');
    })
    // Create task_dependencies table for task dependencies
    .createTable('task_dependencies', function(table) {
      if (knex.client.config.client === 'sqlite3') {
        table.string('id').primary();
        table.string('task_id').notNullable(); // The dependent task
        table.string('depends_on_task_id').notNullable(); // The task it depends on
      } else {
        table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
        table.uuid('task_id').notNullable(); // The dependent task
        table.uuid('depends_on_task_id').notNullable(); // The task it depends on
      }
      table.string('dependency_type', 50).defaultTo('finish_to_start'); // finish_to_start, start_to_start, etc.
      table.timestamps(true, true);
      
      // Foreign key constraints
      table.foreign('task_id').references('id').inTable('project_tasks').onDelete('CASCADE');
      table.foreign('depends_on_task_id').references('id').inTable('project_tasks').onDelete('CASCADE');
      
      // Indexes
      table.index(['task_id'], 'idx_task_dependencies_task_id');
      table.index(['depends_on_task_id'], 'idx_task_dependencies_depends_on_task_id');
      table.unique(['task_id', 'depends_on_task_id'], 'unique_task_dependency');
    });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema
    .dropTableIfExists('task_dependencies')
    .dropTableIfExists('task_comments')
    .dropTableIfExists('task_time_tracking')
    .alterTable('project_tasks', function(table) {
      table.dropColumn('progress_percentage');
      table.dropColumn('notes');
      table.dropColumn('status_updated_at');
      table.dropColumn('completed_at');
      table.dropColumn('priority');
    });
};