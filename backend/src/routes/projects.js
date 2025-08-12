const express = require('express');
const db = require('../config/database');
const { projectSchemas } = require('../utils/validation');
const { 
  formatValidationError, 
  createResponse, 
  createErrorResponse,
  filterByQuery,
  sortItems,
  paginateResults,
  hasProjectAccess
} = require('../utils/helpers');
const { authenticate, validateProjectAccess, validatePropertyAccess } = require('../middleware/auth');

const router = express.Router();

/**
 * POST /api/v1/projects
 * Create a new project
 */
router.post('/', authenticate, async (req, res) => {
  try {
    // Validate request body
    const { error, value } = projectSchemas.create.validate(req.body);
    if (error) {
      const validationError = formatValidationError(error);
      const { error: errorObj, statusCode } = createErrorResponse(validationError.message, 400, validationError.details);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    const { propertyId, tasks = [], ...projectData } = value;

    // Check if user has access to the property
    const dbProperty = await db('properties').where('id', propertyId).first();
    if (!dbProperty) {
      const { error: errorObj, statusCode } = createErrorResponse('Property not found', 404);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Check property access
    const hasAccess = dbProperty.owner_id === req.user.id || 
      await db('property_permissions')
        .where({ user_id: req.user.id, property_id: propertyId })
        .first() !== undefined;

    if (!hasAccess) {
      const { error: errorObj, statusCode } = createErrorResponse('Access denied to this property', 403);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Create new project
    const [dbProject] = await db('projects')
      .insert({
        property_id: propertyId,
        title: projectData.title,
        description: projectData.description,
        status: projectData.status || 'pending',
        priority: projectData.priority || 'medium',
        budget: projectData.budget,
        actual_cost: projectData.actualCost,
        start_date: projectData.startDate,
        end_date: projectData.endDate,
        due_date: projectData.dueDate,
        created_by: req.user.id
      })
      .returning(['id', 'property_id', 'title', 'description', 'status', 'priority', 'budget', 'actual_cost', 'start_date', 'end_date', 'due_date', 'created_by', 'created_at', 'updated_at']);
    
    // Process and insert tasks if provided
    let projectTasks = [];
    if (tasks && tasks.length > 0) {
      const taskInserts = tasks.map((task, index) => ({
        project_id: dbProject.id,
        title: task.title,
        description: task.description,
        status: task.status || 'pending',
        assigned_to: task.assignedTo,
        due_date: task.dueDate,
        estimated_hours: task.estimatedHours,
        actual_hours: task.actualHours,
        cost: task.cost,
        sort_order: index
      }));
      
      projectTasks = await db('project_tasks')
        .insert(taskInserts)
        .returning(['id', 'project_id', 'title', 'description', 'status', 'assigned_to', 'due_date', 'estimated_hours', 'actual_hours', 'cost', 'sort_order', 'created_at', 'updated_at']);
        
      // Transform tasks to expected format
      projectTasks = projectTasks.map(task => ({
        id: task.id,
        projectId: task.project_id,
        title: task.title,
        description: task.description,
        status: task.status,
        assignedTo: task.assigned_to,
        dueDate: task.due_date,
        estimatedHours: task.estimated_hours,
        actualHours: task.actual_hours,
        cost: task.cost,
        sortOrder: task.sort_order,
        createdAt: task.created_at,
        updatedAt: task.updated_at
      }));
    }
    
    // Transform project to expected format
    const newProject = {
      id: dbProject.id,
      propertyId: dbProject.property_id,
      title: dbProject.title,
      description: dbProject.description,
      status: dbProject.status,
      priority: dbProject.priority,
      budget: dbProject.budget,
      actualCost: dbProject.actual_cost,
      startDate: dbProject.start_date,
      endDate: dbProject.end_date,
      dueDate: dbProject.due_date,
      tasks: projectTasks,
      createdBy: dbProject.created_by,
      createdAt: dbProject.created_at,
      updatedAt: dbProject.updated_at
    };

    // Return response
    const responseData = {
      project: newProject
    };

    return res.status(201).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Project creation error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * GET /api/v1/projects
 * Get all projects accessible to the authenticated user
 */
router.get('/', authenticate, async (req, res) => {
  try {
    const { page, limit, sortBy, sortOrder, ...filters } = req.query;

    // Get user's accessible projects
    const ownedProjectsQuery = db('projects')
      .join('properties', 'projects.property_id', 'properties.id')
      .where('properties.owner_id', req.user.id)
      .select('projects.*');
    
    const accessibleProjectsQuery = db('projects')
      .join('property_permissions', 'projects.property_id', 'property_permissions.property_id')
      .where('property_permissions.user_id', req.user.id)
      .select('projects.*');
    
    const assignedProjectsQuery = db('projects')
      .join('project_assignments', 'projects.id', 'project_assignments.project_id')
      .where('project_assignments.user_id', req.user.id)
      .select('projects.*');
    
    const [ownedProjects, accessibleProjects, assignedProjects] = await Promise.all([
      ownedProjectsQuery,
      accessibleProjectsQuery,
      assignedProjectsQuery
    ]);
    
    // Combine and deduplicate projects
    const allDbProjects = [...ownedProjects, ...accessibleProjects, ...assignedProjects];
    const uniqueProjects = allDbProjects.filter((project, index, self) => 
      index === self.findIndex(p => p.id === project.id)
    );
    
    // Transform projects to expected format
    let userProjects = uniqueProjects.map(dbProject => ({
      id: dbProject.id,
      propertyId: dbProject.property_id,
      title: dbProject.title,
      description: dbProject.description,
      status: dbProject.status,
      priority: dbProject.priority,
      budget: dbProject.budget,
      actualCost: dbProject.actual_cost,
      startDate: dbProject.start_date,
      endDate: dbProject.end_date,
      dueDate: dbProject.due_date,
      createdBy: dbProject.created_by,
      createdAt: dbProject.created_at,
      updatedAt: dbProject.updated_at
    }));

    // Apply filters
    userProjects = filterByQuery(userProjects, filters);

    // Apply sorting
    userProjects = sortItems(userProjects, sortBy, sortOrder);

    // Apply pagination
    const result = paginateResults(userProjects, page, limit);

    // Return response
    const responseData = {
      projects: result.items,
      pagination: result.pagination
    };

    return res.status(200).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Projects retrieval error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * GET /api/v1/projects/:id
 * Get a specific project by ID
 */
router.get('/:id', authenticate, validateProjectAccess, async (req, res) => {
  try {
    // Project is available in req.project from middleware, but we need to get tasks
    const dbTasks = await db('project_tasks')
      .where('project_id', req.params.id)
      .orderBy('sort_order');
    
    // Transform tasks to expected format
    const tasks = dbTasks.map(task => ({
      id: task.id,
      projectId: task.project_id,
      title: task.title,
      description: task.description,
      status: task.status,
      assignedTo: task.assigned_to,
      dueDate: task.due_date,
      estimatedHours: task.estimated_hours,
      actualHours: task.actual_hours,
      cost: task.cost,
      sortOrder: task.sort_order,
      createdAt: task.created_at,
      updatedAt: task.updated_at
    }));
    
    const responseData = {
      project: {
        ...req.project,
        tasks
      }
    };

    return res.status(200).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Project retrieval error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * PUT /api/v1/projects/:id
 * Update a specific project
 */
router.put('/:id', authenticate, validateProjectAccess, async (req, res) => {
  try {
    // Check if user has permission to edit projects
    const canEdit = req.property.ownerId === req.user.id || 
      (req.userRole && req.userRole.permissions.editProjects) ||
      req.projectAssignment; // Assigned users can edit

    if (!canEdit) {
      const { error: errorObj, statusCode } = createErrorResponse('Permission denied to edit this project', 403);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Validate request body
    const { error, value } = projectSchemas.update.validate(req.body);
    if (error) {
      const validationError = formatValidationError(error);
      const { error: errorObj, statusCode } = createErrorResponse(validationError.message, 400, validationError.details);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Update project in database
    const updateData = {
      updated_at: new Date()
    };
    
    // Map frontend field names to database column names
    if (value.title !== undefined) updateData.title = value.title;
    if (value.description !== undefined) updateData.description = value.description;
    if (value.status !== undefined) updateData.status = value.status;
    if (value.priority !== undefined) updateData.priority = value.priority;
    if (value.budget !== undefined) updateData.budget = value.budget;
    if (value.actualCost !== undefined) updateData.actual_cost = value.actualCost;
    if (value.startDate !== undefined) updateData.start_date = value.startDate;
    if (value.endDate !== undefined) updateData.end_date = value.endDate;
    if (value.dueDate !== undefined) updateData.due_date = value.dueDate;
    
    const [dbProject] = await db('projects')
      .where('id', req.params.id)
      .update(updateData)
      .returning(['id', 'property_id', 'title', 'description', 'status', 'priority', 'budget', 'actual_cost', 'start_date', 'end_date', 'due_date', 'created_by', 'created_at', 'updated_at']);
    
    if (!dbProject) {
      const { error: errorObj, statusCode } = createErrorResponse('Project not found', 404);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }
    
    // Handle tasks update if provided
    let projectTasks = [];
    if (value.tasks) {
      // Delete existing tasks
      await db('project_tasks').where('project_id', req.params.id).del();
      
      // Insert new tasks
      if (value.tasks.length > 0) {
        const taskInserts = value.tasks.map((task, index) => ({
          project_id: req.params.id,
          title: task.title,
          description: task.description,
          status: task.status || 'pending',
          assigned_to: task.assignedTo,
          due_date: task.dueDate,
          estimated_hours: task.estimatedHours,
          actual_hours: task.actualHours,
          cost: task.cost,
          sort_order: index
        }));
        
        projectTasks = await db('project_tasks')
          .insert(taskInserts)
          .returning(['id', 'project_id', 'title', 'description', 'status', 'assigned_to', 'due_date', 'estimated_hours', 'actual_hours', 'cost', 'sort_order', 'created_at', 'updated_at']);
          
        // Transform tasks to expected format
        projectTasks = projectTasks.map(task => ({
          id: task.id,
          projectId: task.project_id,
          title: task.title,
          description: task.description,
          status: task.status,
          assignedTo: task.assigned_to,
          dueDate: task.due_date,
          estimatedHours: task.estimated_hours,
          actualHours: task.actual_hours,
          cost: task.cost,
          sortOrder: task.sort_order,
          createdAt: task.created_at,
          updatedAt: task.updated_at
        }));
      }
    } else {
      // Get existing tasks
      const dbTasks = await db('project_tasks')
        .where('project_id', req.params.id)
        .orderBy('sort_order');
      
      projectTasks = dbTasks.map(task => ({
        id: task.id,
        projectId: task.project_id,
        title: task.title,
        description: task.description,
        status: task.status,
        assignedTo: task.assigned_to,
        dueDate: task.due_date,
        estimatedHours: task.estimated_hours,
        actualHours: task.actual_hours,
        cost: task.cost,
        sortOrder: task.sort_order,
        createdAt: task.created_at,
        updatedAt: task.updated_at
      }));
    }
    
    // Transform project to expected format
    const updatedProject = {
      id: dbProject.id,
      propertyId: dbProject.property_id,
      title: dbProject.title,
      description: dbProject.description,
      status: dbProject.status,
      priority: dbProject.priority,
      budget: dbProject.budget,
      actualCost: dbProject.actual_cost,
      startDate: dbProject.start_date,
      endDate: dbProject.end_date,
      dueDate: dbProject.due_date,
      tasks: projectTasks,
      createdBy: dbProject.created_by,
      createdAt: dbProject.created_at,
      updatedAt: dbProject.updated_at
    };

    // Return response
    const responseData = {
      project: updatedProject
    };

    return res.status(200).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Project update error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * DELETE /api/v1/projects/:id
 * Delete a specific project
 */
router.delete('/:id', authenticate, validateProjectAccess, async (req, res) => {
  try {
    // Check if user has permission to delete projects
    const canDelete = req.property.ownerId === req.user.id || 
      (req.userRole && req.userRole.permissions.deleteProjects);

    if (!canDelete) {
      const { error: errorObj, statusCode } = createErrorResponse('Permission denied to delete this project', 403);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Delete project and related data (cascade will handle most)
    const deletedRows = await db('projects')
      .where('id', req.params.id)
      .del();
    
    if (deletedRows === 0) {
      const { error: errorObj, statusCode } = createErrorResponse('Project not found', 404);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Return response
    const responseData = {
      message: 'Project deleted successfully'
    };

    return res.status(200).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Project deletion error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * POST /api/v1/projects/:id/assign
 * Assign a user to a project
 */
router.post('/:id/assign', authenticate, validateProjectAccess, async (req, res) => {
  try {
    // Only property owner or users with edit permission can assign
    const canAssign = req.property.ownerId === req.user.id || 
      (req.userRole && req.userRole.permissions.editProjects);

    if (!canAssign) {
      const { error: errorObj, statusCode } = createErrorResponse('Permission denied to assign users to this project', 403);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Validate request body
    const { error, value } = projectSchemas.assign.validate(req.body);
    if (error) {
      const validationError = formatValidationError(error);
      const { error: errorObj, statusCode } = createErrorResponse(validationError.message, 400, validationError.details);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    const { userId, role } = value;

    // Check if user exists
    const userToAssign = await db('users').where('id', userId).first();
    if (!userToAssign) {
      const { error: errorObj, statusCode } = createErrorResponse('User not found', 404);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Check if assignment already exists
    const existingAssignment = await db('project_assignments')
      .where({
        user_id: userId,
        project_id: req.params.id
      })
      .first();

    if (existingAssignment) {
      // Update existing assignment
      await db('project_assignments')
        .where('id', existingAssignment.id)
        .update({
          role,
          updated_at: new Date()
        });
    } else {
      // Create new assignment
      await db('project_assignments')
        .insert({
          user_id: userId,
          project_id: req.params.id,
          role
        });
    }

    // Return response
    const responseData = {
      message: 'User assigned to project successfully'
    };

    return res.status(200).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Project assignment error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * DELETE /api/v1/projects/:id/assign/:userId
 * Unassign a user from a project
 */
router.delete('/:id/assign/:userId', authenticate, validateProjectAccess, async (req, res) => {
  try {
    // Only property owner or users with edit permission can unassign
    const canUnassign = req.property.ownerId === req.user.id || 
      (req.userRole && req.userRole.permissions.editProjects);

    if (!canUnassign) {
      const { error: errorObj, statusCode } = createErrorResponse('Permission denied to unassign users from this project', 403);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    const { userId } = req.params;

    // Delete assignment
    const deletedRows = await db('project_assignments')
      .where({
        user_id: userId,
        project_id: req.params.id
      })
      .del();

    if (deletedRows === 0) {
      const { error: errorObj, statusCode } = createErrorResponse('Project assignment not found', 404);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Return response
    const responseData = {
      message: 'User unassigned from project successfully'
    };

    return res.status(200).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Project unassignment error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * GET /api/v1/projects/:id/assignments
 * Get all assignments for a project
 */
router.get('/:id/assignments', authenticate, validateProjectAccess, async (req, res) => {
  try {
    // Get project assignments with user information
    const assignments = await db('project_assignments')
      .join('users', 'project_assignments.user_id', 'users.id')
      .where('project_assignments.project_id', req.params.id)
      .select(
        'project_assignments.id',
        'project_assignments.project_id',
        'project_assignments.user_id',
        'project_assignments.role',
        'project_assignments.created_at',
        'project_assignments.updated_at',
        'users.email',
        'users.first_name',
        'users.last_name',
        'users.user_type'
      );

    // Transform to expected format
    const enrichedAssignments = assignments.map(assignment => ({
      id: assignment.id,
      userId: assignment.user_id,
      projectId: assignment.project_id,
      role: assignment.role,
      assignedBy: req.user.id, // This should ideally be stored in the database
      createdAt: assignment.created_at,
      updatedAt: assignment.updated_at,
      user: {
        id: assignment.user_id,
        firstName: assignment.first_name,
        lastName: assignment.last_name,
        email: assignment.email,
        userType: assignment.user_type
      }
    }));

    // Return response
    const responseData = {
      assignments: enrichedAssignments
    };

    return res.status(200).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Project assignments retrieval error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

module.exports = router;