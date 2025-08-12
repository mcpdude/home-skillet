const express = require('express');
const db = require('../config/database');
const { authenticate } = require('../middleware/auth');
const { v4: uuidv4 } = require('uuid');
const { 
  createResponse, 
  createErrorResponse
} = require('../utils/helpers');

const router = express.Router();

/**
 * Middleware to validate task access
 */
const validateTaskAccess = async (req, res, next) => {
  try {
    const taskId = req.params.id || req.params.taskId;
    
    // Get task with project and property info
    const task = await db('project_tasks')
      .join('projects', 'project_tasks.project_id', 'projects.id')
      .join('properties', 'projects.property_id', 'properties.id')
      .where('project_tasks.id', taskId)
      .select(
        'project_tasks.*',
        'projects.property_id',
        'properties.owner_id'
      )
      .first();

    if (!task) {
      const { error: errorObj, statusCode } = createErrorResponse('Task not found', 404);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Check if user has access (property owner, assigned to task, or has project permissions)
    const hasAccess = task.owner_id === req.user.id || 
      task.assigned_to === req.user.id ||
      await db('property_permissions')
        .where({ user_id: req.user.id, property_id: task.property_id })
        .first() !== undefined ||
      await db('project_assignments')
        .where({ user_id: req.user.id, project_id: task.project_id })
        .first() !== undefined;

    if (!hasAccess) {
      const { error: errorObj, statusCode } = createErrorResponse('Access denied to this task', 403);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    req.task = task;
    next();
  } catch (error) {
    console.error('Task access validation error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
};

/**
 * PUT /api/v1/tasks/:id/status
 * Update task status with progress tracking
 */
router.put('/:id/status', authenticate, validateTaskAccess, async (req, res) => {
  try {
    const { status, progress_percentage, notes } = req.body;
    const taskId = req.params.id;

    if (!status) {
      const { error: errorObj, statusCode } = createErrorResponse('Status is required', 400);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Check dependencies if trying to start a task
    if (status === 'in_progress') {
      const dependencies = await db('task_dependencies')
        .join('project_tasks', 'task_dependencies.depends_on_task_id', 'project_tasks.id')
        .where('task_dependencies.task_id', taskId)
        .where('project_tasks.status', '!=', 'completed')
        .select('project_tasks.title');

      if (dependencies.length > 0) {
        const { error: errorObj, statusCode } = createErrorResponse(
          `Cannot start task due to incomplete dependency: ${dependencies[0].title}`, 
          400
        );
        return res.status(statusCode).json(createResponse(false, null, errorObj));
      }
    }

    const updateData = {
      status,
      status_updated_at: new Date(),
      updated_at: new Date()
    };

    // Set progress percentage
    if (progress_percentage !== undefined) {
      updateData.progress_percentage = Math.max(0, Math.min(100, progress_percentage));
    }

    // Auto-set progress to 100% when completed
    if (status === 'completed') {
      updateData.progress_percentage = 100;
      updateData.completed_at = new Date();
    }

    // Add notes if provided
    if (notes) {
      updateData.notes = notes;
    }

    const [updatedTask] = await db('project_tasks')
      .where('id', taskId)
      .update(updateData)
      .returning('*');

    // Create a status update comment
    await db('task_comments').insert({
      id: uuidv4(),
      task_id: taskId,
      user_id: req.user.id,
      content: notes || `Status changed to ${status}`,
      type: 'status_update',
      metadata: JSON.stringify({ 
        old_status: req.task.status, 
        new_status: status,
        progress_percentage: updateData.progress_percentage 
      })
    });

    res.json(createResponse(true, updatedTask));

  } catch (error) {
    console.error('Task status update error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * POST /api/v1/tasks/:id/time-tracking/start
 * Start time tracking for a task
 */
router.post('/:id/time-tracking/start', authenticate, validateTaskAccess, async (req, res) => {
  try {
    const { description } = req.body;
    const taskId = req.params.id;

    // Check if user already has an active time tracking session for any task
    const activeSession = await db('task_time_tracking')
      .where({ user_id: req.user.id, is_active: true })
      .first();

    if (activeSession) {
      const { error: errorObj, statusCode } = createErrorResponse(
        'You already have an active time tracking session. Please stop it first.', 
        400
      );
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    const timeEntry = {
      id: uuidv4(),
      task_id: taskId,
      user_id: req.user.id,
      started_at: new Date(),
      description,
      is_active: true
    };

    const [insertedEntry] = await db('task_time_tracking')
      .insert(timeEntry)
      .returning('*');

    res.json(createResponse(true, insertedEntry || timeEntry));

  } catch (error) {
    console.error('Time tracking start error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * POST /api/v1/tasks/:id/time-tracking/stop
 * Stop time tracking for a task
 */
router.post('/:id/time-tracking/stop', authenticate, validateTaskAccess, async (req, res) => {
  try {
    const { description } = req.body;
    const taskId = req.params.id;

    // Find the active session
    const activeSession = await db('task_time_tracking')
      .where({ 
        task_id: taskId, 
        user_id: req.user.id, 
        is_active: true 
      })
      .first();

    if (!activeSession) {
      const { error: errorObj, statusCode } = createErrorResponse('No active time tracking session found', 404);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    const endTime = new Date();
    const durationMinutes = Math.floor((endTime - new Date(activeSession.started_at)) / (1000 * 60));

    const [updatedEntry] = await db('task_time_tracking')
      .where('id', activeSession.id)
      .update({
        ended_at: endTime,
        duration_minutes: durationMinutes,
        description: description || activeSession.description,
        is_active: false,
        updated_at: new Date()
      })
      .returning('*');

    res.json(createResponse(true, updatedEntry));

  } catch (error) {
    console.error('Time tracking stop error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * GET /api/v1/tasks/:id/time-tracking
 * Get time tracking summary for a task
 */
router.get('/:id/time-tracking', authenticate, validateTaskAccess, async (req, res) => {
  try {
    const taskId = req.params.id;

    const sessions = await db('task_time_tracking')
      .where('task_id', taskId)
      .orderBy('started_at', 'desc')
      .select('*');

    const totalMinutes = sessions
      .filter(session => !session.is_active)
      .reduce((sum, session) => sum + (session.duration_minutes || 0), 0);

    const totalHours = Math.round((totalMinutes / 60) * 100) / 100;

    const summary = {
      total_hours: totalHours,
      estimated_hours: req.task.estimated_hours || 0,
      sessions: sessions
    };

    res.json(createResponse(true, summary));

  } catch (error) {
    console.error('Time tracking summary error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * POST /api/v1/tasks/:id/comments
 * Add a comment to a task
 */
router.post('/:id/comments', authenticate, validateTaskAccess, async (req, res) => {
  try {
    const { content, type } = req.body;
    const taskId = req.params.id;

    if (!content) {
      const { error: errorObj, statusCode } = createErrorResponse('Comment content is required', 400);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    const comment = {
      id: uuidv4(),
      task_id: taskId,
      user_id: req.user.id,
      content,
      type: type || 'comment'
    };

    const [insertedComment] = await db('task_comments')
      .insert(comment)
      .returning('*');

    res.status(201).json(createResponse(true, insertedComment || comment));

  } catch (error) {
    console.error('Task comment creation error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * GET /api/v1/tasks/:id/comments
 * Get all comments for a task
 */
router.get('/:id/comments', authenticate, validateTaskAccess, async (req, res) => {
  try {
    const taskId = req.params.id;

    const comments = await db('task_comments')
      .join('users', 'task_comments.user_id', 'users.id')
      .where('task_comments.task_id', taskId)
      .orderBy('task_comments.created_at', 'desc')
      .select(
        'task_comments.*',
        'users.first_name',
        'users.last_name',
        'users.email'
      );

    const enrichedComments = comments.map(comment => ({
      ...comment,
      user: {
        id: comment.user_id,
        first_name: comment.first_name,
        last_name: comment.last_name,
        email: comment.email
      }
    }));

    res.json(createResponse(true, enrichedComments));

  } catch (error) {
    console.error('Task comments retrieval error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * POST /api/v1/tasks/:id/dependencies
 * Create task dependency
 */
router.post('/:id/dependencies', authenticate, validateTaskAccess, async (req, res) => {
  try {
    const { depends_on_task_id, dependency_type } = req.body;
    const taskId = req.params.id;

    if (!depends_on_task_id) {
      const { error: errorObj, statusCode } = createErrorResponse('depends_on_task_id is required', 400);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Check if the dependency task exists and user has access
    const dependsOnTask = await db('project_tasks')
      .join('projects', 'project_tasks.project_id', 'projects.id')
      .join('properties', 'projects.property_id', 'properties.id')
      .where('project_tasks.id', depends_on_task_id)
      .select('project_tasks.*', 'properties.owner_id')
      .first();

    if (!dependsOnTask) {
      const { error: errorObj, statusCode } = createErrorResponse('Dependency task not found', 404);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Check for circular dependencies
    const existingDependency = await db('task_dependencies')
      .where({
        task_id: depends_on_task_id,
        depends_on_task_id: taskId
      })
      .first();

    if (existingDependency) {
      const { error: errorObj, statusCode } = createErrorResponse('Circular dependency detected', 400);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    const dependency = {
      id: uuidv4(),
      task_id: taskId,
      depends_on_task_id,
      dependency_type: dependency_type || 'finish_to_start'
    };

    const [insertedDependency] = await db('task_dependencies')
      .insert(dependency)
      .returning('*');

    res.status(201).json(createResponse(true, insertedDependency || dependency));

  } catch (error) {
    console.error('Task dependency creation error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * PUT /api/v1/tasks/bulk-update
 * Update multiple tasks at once
 */
router.put('/bulk-update', authenticate, async (req, res) => {
  try {
    const { task_ids, updates } = req.body;

    if (!task_ids || !Array.isArray(task_ids) || task_ids.length === 0) {
      const { error: errorObj, statusCode } = createErrorResponse('task_ids array is required', 400);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    if (!updates || Object.keys(updates).length === 0) {
      const { error: errorObj, statusCode } = createErrorResponse('updates object is required', 400);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Verify user has access to all tasks
    const tasks = await db('project_tasks')
      .join('projects', 'project_tasks.project_id', 'projects.id')
      .join('properties', 'projects.property_id', 'properties.id')
      .whereIn('project_tasks.id', task_ids)
      .select(
        'project_tasks.id',
        'project_tasks.project_id',
        'properties.owner_id',
        'project_tasks.assigned_to'
      );

    if (tasks.length !== task_ids.length) {
      const { error: errorObj, statusCode } = createErrorResponse('Some tasks not found', 404);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Check access for each task
    for (const task of tasks) {
      const hasAccess = task.owner_id === req.user.id ||
        task.assigned_to === req.user.id ||
        await db('property_permissions')
          .where({ user_id: req.user.id, property_id: task.property_id })
          .first() !== undefined ||
        await db('project_assignments')
          .where({ user_id: req.user.id, project_id: task.project_id })
          .first() !== undefined;

      if (!hasAccess) {
        const { error: errorObj, statusCode } = createErrorResponse('Access denied to some tasks', 403);
        return res.status(statusCode).json(createResponse(false, null, errorObj));
      }
    }

    // Perform bulk update
    const updateData = { ...updates, updated_at: new Date() };
    const updatedCount = await db('project_tasks')
      .whereIn('id', task_ids)
      .update(updateData);

    res.json(createResponse(true, { updated_count: updatedCount }));

  } catch (error) {
    console.error('Bulk task update error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * DELETE /api/v1/tasks/bulk-delete
 * Delete multiple tasks at once
 */
router.delete('/bulk-delete', authenticate, async (req, res) => {
  try {
    const { task_ids } = req.body;

    if (!task_ids || !Array.isArray(task_ids) || task_ids.length === 0) {
      const { error: errorObj, statusCode } = createErrorResponse('task_ids array is required', 400);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Verify user has access to all tasks (similar to bulk update)
    const tasks = await db('project_tasks')
      .join('projects', 'project_tasks.project_id', 'projects.id')
      .join('properties', 'projects.property_id', 'properties.id')
      .whereIn('project_tasks.id', task_ids)
      .select(
        'project_tasks.id',
        'project_tasks.project_id',
        'properties.owner_id',
        'project_tasks.assigned_to'
      );

    if (tasks.length !== task_ids.length) {
      const { error: errorObj, statusCode } = createErrorResponse('Some tasks not found', 404);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Check access for each task
    for (const task of tasks) {
      const hasAccess = task.owner_id === req.user.id ||
        task.assigned_to === req.user.id ||
        await db('property_permissions')
          .where({ user_id: req.user.id, property_id: task.property_id })
          .first() !== undefined ||
        await db('project_assignments')
          .where({ user_id: req.user.id, project_id: task.project_id })
          .first() !== undefined;

      if (!hasAccess) {
        const { error: errorObj, statusCode } = createErrorResponse('Access denied to some tasks', 403);
        return res.status(statusCode).json(createResponse(false, null, errorObj));
      }
    }

    // Perform bulk delete
    const deletedCount = await db('project_tasks')
      .whereIn('id', task_ids)
      .del();

    res.json(createResponse(true, { deleted_count: deletedCount }));

  } catch (error) {
    console.error('Bulk task delete error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * POST /api/v1/projects/:id/tasks
 * Create a new task in a project (existing route - should be moved here from projects.js)
 */
router.post('/projects/:id/tasks', authenticate, async (req, res) => {
  try {
    const { title, description, status, priority, estimated_hours } = req.body;
    const projectId = req.params.id;

    // Verify project exists and user has access
    const project = await db('projects')
      .join('properties', 'projects.property_id', 'properties.id')
      .where('projects.id', projectId)
      .select('projects.*', 'properties.owner_id')
      .first();

    if (!project) {
      const { error: errorObj, statusCode } = createErrorResponse('Project not found', 404);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    const hasAccess = project.owner_id === req.user.id ||
      await db('property_permissions')
        .where({ user_id: req.user.id, property_id: project.property_id })
        .first() !== undefined ||
      await db('project_assignments')
        .where({ user_id: req.user.id, project_id: projectId })
        .first() !== undefined;

    if (!hasAccess) {
      const { error: errorObj, statusCode } = createErrorResponse('Access denied to this project', 403);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    const task = {
      id: uuidv4(),
      project_id: projectId,
      title,
      description,
      status: status || 'pending',
      priority: priority || 'medium',
      estimated_hours,
      progress_percentage: 0
    };

    const [insertedTask] = await db('project_tasks')
      .insert(task)
      .returning('*');

    res.status(201).json(createResponse(true, insertedTask || task));

  } catch (error) {
    console.error('Task creation error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

module.exports = router;