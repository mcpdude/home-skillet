const express = require('express');
const db = require('../config/database');
const { maintenanceSchemas } = require('../utils/validation');
const { 
  formatValidationError, 
  createResponse, 
  createErrorResponse,
  filterByQuery,
  sortItems,
  paginateResults,
  calculateNextDueDate,
  hasMaintenanceAccess
} = require('../utils/helpers');
const { authenticate, validateMaintenanceAccess } = require('../middleware/auth');

const router = express.Router();

/**
 * POST /api/v1/maintenance-schedules
 * Create a new maintenance schedule
 */
router.post('/', authenticate, async (req, res) => {
  try {
    // Validate request body
    const { error, value } = maintenanceSchemas.create.validate(req.body);
    if (error) {
      const validationError = formatValidationError(error);
      const { error: errorObj, statusCode } = createErrorResponse(validationError.message, 400, validationError.details);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    const { propertyId, ...scheduleData } = value;

    // Check if user has access to the property
    const dbProperty = await db('properties').where('id', propertyId).first();
    if (!dbProperty) {
      const { error: errorObj, statusCode } = createErrorResponse('Property not found', 404);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Check property access
    const hasAccess = dbProperty.owner_id === req.user.id || 
      await db('property_permissions')
        .where({ user_id: req.user.id, property_id: propertyId, role: 'admin' })
        .orWhere({ user_id: req.user.id, property_id: propertyId, role: 'manager' })
        .orWhere({ user_id: req.user.id, property_id: propertyId, role: 'editor' })
        .first() !== undefined;

    if (!hasAccess) {
      const { error: errorObj, statusCode } = createErrorResponse('Access denied to this property', 403);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Calculate next due date if not provided
    let nextDueDate = scheduleData.nextDueDate;
    if (!nextDueDate && scheduleData.frequency !== 'as_needed') {
      nextDueDate = calculateNextDueDate(scheduleData.frequency);
    }

    // Create new maintenance schedule
    const [dbSchedule] = await db('maintenance_schedules')
      .insert({
        property_id: propertyId,
        title: scheduleData.title,
        description: scheduleData.description,
        frequency: scheduleData.frequency,
        frequency_value: scheduleData.frequencyValue || 1,
        category: scheduleData.category,
        next_due_date: nextDueDate,
        last_completed_date: scheduleData.lastCompletedDate,
        is_active: scheduleData.isActive !== undefined ? scheduleData.isActive : true,
        estimated_cost: scheduleData.estimatedCost,
        assigned_to: scheduleData.assignedTo,
        created_by: req.user.id
      })
      .returning(['id', 'property_id', 'title', 'description', 'frequency', 'frequency_value', 'category', 'next_due_date', 'last_completed_date', 'is_active', 'estimated_cost', 'assigned_to', 'created_by', 'created_at', 'updated_at']);
    
    // Transform to expected format
    const newSchedule = {
      id: dbSchedule.id,
      propertyId: dbSchedule.property_id,
      title: dbSchedule.title,
      description: dbSchedule.description,
      frequency: dbSchedule.frequency,
      frequencyValue: dbSchedule.frequency_value,
      category: dbSchedule.category,
      nextDueDate: dbSchedule.next_due_date,
      lastCompletedDate: dbSchedule.last_completed_date,
      isActive: dbSchedule.is_active,
      estimatedCost: dbSchedule.estimated_cost,
      assignedTo: dbSchedule.assigned_to,
      createdBy: dbSchedule.created_by,
      createdAt: dbSchedule.created_at,
      updatedAt: dbSchedule.updated_at
    };

    // Return response
    const responseData = {
      schedule: newSchedule
    };

    return res.status(201).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Maintenance schedule creation error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * GET /api/v1/maintenance-schedules
 * Get all maintenance schedules accessible to the authenticated user
 */
router.get('/', authenticate, async (req, res) => {
  try {
    const { page, limit, sortBy, sortOrder, ...filters } = req.query;

    // Get user's accessible maintenance schedules
    const ownedSchedulesQuery = db('maintenance_schedules')
      .join('properties', 'maintenance_schedules.property_id', 'properties.id')
      .where('properties.owner_id', req.user.id)
      .select('maintenance_schedules.*');
    
    const accessibleSchedulesQuery = db('maintenance_schedules')
      .join('property_permissions', 'maintenance_schedules.property_id', 'property_permissions.property_id')
      .where('property_permissions.user_id', req.user.id)
      .select('maintenance_schedules.*');
    
    const [ownedSchedules, accessibleSchedules] = await Promise.all([
      ownedSchedulesQuery,
      accessibleSchedulesQuery
    ]);
    
    // Combine and deduplicate schedules
    const allDbSchedules = [...ownedSchedules, ...accessibleSchedules];
    const uniqueSchedules = allDbSchedules.filter((schedule, index, self) => 
      index === self.findIndex(s => s.id === schedule.id)
    );
    
    // Transform schedules to expected format
    let userSchedules = uniqueSchedules.map(dbSchedule => ({
      id: dbSchedule.id,
      propertyId: dbSchedule.property_id,
      title: dbSchedule.title,
      description: dbSchedule.description,
      frequency: dbSchedule.frequency,
      frequencyValue: dbSchedule.frequency_value,
      category: dbSchedule.category,
      nextDueDate: dbSchedule.next_due_date,
      lastCompletedDate: dbSchedule.last_completed_date,
      isActive: dbSchedule.is_active,
      estimatedCost: dbSchedule.estimated_cost,
      assignedTo: dbSchedule.assigned_to,
      createdBy: dbSchedule.created_by,
      createdAt: dbSchedule.created_at,
      updatedAt: dbSchedule.updated_at
    }));

    // Apply filters
    userSchedules = filterByQuery(userSchedules, filters);

    // Apply sorting
    userSchedules = sortItems(userSchedules, sortBy, sortOrder);

    // Apply pagination
    const result = paginateResults(userSchedules, page, limit);

    // Return response
    const responseData = {
      schedules: result.items,
      pagination: result.pagination
    };

    return res.status(200).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Maintenance schedules retrieval error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * GET /api/v1/maintenance-schedules/:id
 * Get a specific maintenance schedule by ID
 */
router.get('/:id', authenticate, validateMaintenanceAccess, async (req, res) => {
  try {
    // Schedule is available in req.schedule from middleware
    const responseData = {
      schedule: req.schedule
    };

    return res.status(200).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Maintenance schedule retrieval error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * PUT /api/v1/maintenance-schedules/:id
 * Update a specific maintenance schedule
 */
router.put('/:id', authenticate, validateMaintenanceAccess, async (req, res) => {
  try {
    // Check if user has permission to manage maintenance
    const canManage = req.property.ownerId === req.user.id || 
      (req.userRole && req.userRole.permissions.manageMaintenance);

    if (!canManage) {
      const { error: errorObj, statusCode } = createErrorResponse('Permission denied to manage this maintenance schedule', 403);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Validate request body
    const { error, value } = maintenanceSchemas.update.validate(req.body);
    if (error) {
      const validationError = formatValidationError(error);
      const { error: errorObj, statusCode } = createErrorResponse(validationError.message, 400, validationError.details);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Update schedule in database
    const updateData = {
      updated_at: new Date()
    };
    
    // Map frontend field names to database column names
    if (value.title !== undefined) updateData.title = value.title;
    if (value.description !== undefined) updateData.description = value.description;
    if (value.frequency !== undefined) updateData.frequency = value.frequency;
    if (value.frequencyValue !== undefined) updateData.frequency_value = value.frequencyValue;
    if (value.category !== undefined) updateData.category = value.category;
    if (value.nextDueDate !== undefined) updateData.next_due_date = value.nextDueDate;
    if (value.lastCompletedDate !== undefined) updateData.last_completed_date = value.lastCompletedDate;
    if (value.isActive !== undefined) updateData.is_active = value.isActive;
    if (value.estimatedCost !== undefined) updateData.estimated_cost = value.estimatedCost;
    if (value.assignedTo !== undefined) updateData.assigned_to = value.assignedTo;
    
    // Recalculate next due date if frequency changed
    if (value.frequency && value.frequency !== req.schedule.frequency) {
      if (value.frequency !== 'as_needed') {
        updateData.next_due_date = calculateNextDueDate(value.frequency) || null;
      } else {
        updateData.next_due_date = null;
      }
    }
    
    const [dbSchedule] = await db('maintenance_schedules')
      .where('id', req.params.id)
      .update(updateData)
      .returning(['id', 'property_id', 'title', 'description', 'frequency', 'frequency_value', 'category', 'next_due_date', 'last_completed_date', 'is_active', 'estimated_cost', 'assigned_to', 'created_by', 'created_at', 'updated_at']);
    
    if (!dbSchedule) {
      const { error: errorObj, statusCode } = createErrorResponse('Maintenance schedule not found', 404);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }
    
    // Transform to expected format
    const updatedSchedule = {
      id: dbSchedule.id,
      propertyId: dbSchedule.property_id,
      title: dbSchedule.title,
      description: dbSchedule.description,
      frequency: dbSchedule.frequency,
      frequencyValue: dbSchedule.frequency_value,
      category: dbSchedule.category,
      nextDueDate: dbSchedule.next_due_date,
      lastCompletedDate: dbSchedule.last_completed_date,
      isActive: dbSchedule.is_active,
      estimatedCost: dbSchedule.estimated_cost,
      assignedTo: dbSchedule.assigned_to,
      createdBy: dbSchedule.created_by,
      createdAt: dbSchedule.created_at,
      updatedAt: dbSchedule.updated_at
    };

    // Return response
    const responseData = {
      schedule: updatedSchedule
    };

    return res.status(200).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Maintenance schedule update error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * DELETE /api/v1/maintenance-schedules/:id
 * Delete a specific maintenance schedule
 */
router.delete('/:id', authenticate, validateMaintenanceAccess, async (req, res) => {
  try {
    // Check if user has permission to manage maintenance
    const canManage = req.property.ownerId === req.user.id || 
      (req.userRole && req.userRole.permissions.manageMaintenance);

    if (!canManage) {
      const { error: errorObj, statusCode } = createErrorResponse('Permission denied to manage this maintenance schedule', 403);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Delete schedule and related data (cascade will handle records)
    const deletedRows = await db('maintenance_schedules')
      .where('id', req.params.id)
      .del();
    
    if (deletedRows === 0) {
      const { error: errorObj, statusCode } = createErrorResponse('Maintenance schedule not found', 404);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Return response
    const responseData = {
      message: 'Maintenance schedule deleted successfully'
    };

    return res.status(200).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Maintenance schedule deletion error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * POST /api/v1/maintenance-schedules/:id/complete
 * Mark a maintenance task as completed
 */
router.post('/:id/complete', authenticate, validateMaintenanceAccess, async (req, res) => {
  try {
    // Check if user has permission to manage maintenance
    const canManage = req.property.ownerId === req.user.id || 
      (req.userRole && req.userRole.permissions.manageMaintenance);

    if (!canManage) {
      const { error: errorObj, statusCode } = createErrorResponse('Permission denied to complete this maintenance task', 403);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Validate request body
    const { error, value } = maintenanceSchemas.complete.validate(req.body);
    if (error) {
      const validationError = formatValidationError(error);
      const { error: errorObj, statusCode } = createErrorResponse(validationError.message, 400, validationError.details);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    const { completedDate, notes, actualDuration, nextDueDate } = value;

    // Create maintenance record
    const [dbRecord] = await db('maintenance_records')
      .insert({
        schedule_id: req.params.id,
        completed_date: completedDate,
        notes,
        actual_cost: actualDuration, // Note: mapping actualDuration to actual_cost based on schema
        completed_by: req.user.id,
        status: 'completed'
      })
      .returning(['id', 'schedule_id', 'completed_date', 'notes', 'actual_cost', 'completed_by', 'status', 'created_at', 'updated_at']);

    // Transform to expected format
    const maintenanceRecord = {
      id: dbRecord.id,
      scheduleId: dbRecord.schedule_id,
      completedDate: dbRecord.completed_date,
      notes: dbRecord.notes,
      actualDuration: dbRecord.actual_cost, // Map back to frontend expectation
      completedBy: dbRecord.completed_by,
      status: dbRecord.status,
      createdAt: dbRecord.created_at
    };

    // Update schedule's next due date
    let calculatedNextDueDate = nextDueDate;
    
    // If no next due date provided, calculate based on frequency
    if (!calculatedNextDueDate && req.schedule.frequency !== 'as_needed') {
      calculatedNextDueDate = calculateNextDueDate(req.schedule.frequency, new Date(completedDate));
    }

    await db('maintenance_schedules')
      .where('id', req.params.id)
      .update({
        next_due_date: calculatedNextDueDate,
        last_completed_date: completedDate,
        updated_at: new Date()
      });

    // Return response
    const responseData = {
      record: maintenanceRecord
    };

    return res.status(201).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Maintenance completion error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * GET /api/v1/maintenance-schedules/:id/history
 * Get completion history for a maintenance schedule
 */
router.get('/:id/history', authenticate, validateMaintenanceAccess, async (req, res) => {
  try {
    const { page, limit, sortBy = 'completedDate', sortOrder = 'desc' } = req.query;

    // Get maintenance records for this schedule with user information
    const dbRecords = await db('maintenance_records')
      .join('users', 'maintenance_records.completed_by', 'users.id')
      .where('maintenance_records.schedule_id', req.params.id)
      .select(
        'maintenance_records.id',
        'maintenance_records.schedule_id',
        'maintenance_records.completed_date',
        'maintenance_records.notes',
        'maintenance_records.actual_cost',
        'maintenance_records.status',
        'maintenance_records.created_at',
        'maintenance_records.updated_at',
        'users.id as user_id',
        'users.email',
        'users.first_name',
        'users.last_name'
      );

    // Transform to expected format
    let maintenanceRecords = dbRecords.map(record => ({
      id: record.id,
      scheduleId: record.schedule_id,
      completedDate: record.completed_date,
      notes: record.notes,
      actualDuration: record.actual_cost, // Map back to frontend expectation
      status: record.status,
      createdAt: record.created_at,
      completedBy: {
        id: record.user_id,
        firstName: record.first_name,
        lastName: record.last_name,
        email: record.email
      }
    }));

    // Apply sorting
    maintenanceRecords = sortItems(maintenanceRecords, sortBy, sortOrder);

    // Apply pagination
    const result = paginateResults(maintenanceRecords, page, limit);

    // Return response
    const responseData = {
      records: result.items,
      pagination: result.pagination
    };

    return res.status(200).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Maintenance history retrieval error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * GET /api/v1/maintenance-schedules/due
 * Get all maintenance schedules that are due or overdue
 */
router.get('/due', authenticate, async (req, res) => {
  try {
    const currentDate = new Date().toISOString();

    // Get user's accessible maintenance schedules that are due
    const ownedDueSchedulesQuery = db('maintenance_schedules')
      .join('properties', 'maintenance_schedules.property_id', 'properties.id')
      .where('properties.owner_id', req.user.id)
      .where('maintenance_schedules.is_active', true)
      .whereNotNull('maintenance_schedules.next_due_date')
      .where('maintenance_schedules.next_due_date', '<=', currentDate)
      .select('maintenance_schedules.*');
    
    const accessibleDueSchedulesQuery = db('maintenance_schedules')
      .join('property_permissions', 'maintenance_schedules.property_id', 'property_permissions.property_id')
      .where('property_permissions.user_id', req.user.id)
      .where('maintenance_schedules.is_active', true)
      .whereNotNull('maintenance_schedules.next_due_date')
      .where('maintenance_schedules.next_due_date', '<=', currentDate)
      .select('maintenance_schedules.*');
    
    const [ownedDueSchedules, accessibleDueSchedules] = await Promise.all([
      ownedDueSchedulesQuery,
      accessibleDueSchedulesQuery
    ]);
    
    // Combine and deduplicate schedules
    const allDueSchedules = [...ownedDueSchedules, ...accessibleDueSchedules];
    const uniqueDueSchedules = allDueSchedules.filter((schedule, index, self) => 
      index === self.findIndex(s => s.id === schedule.id)
    );
    
    // Transform to expected format
    let dueSchedules = uniqueDueSchedules.map(dbSchedule => ({
      id: dbSchedule.id,
      propertyId: dbSchedule.property_id,
      title: dbSchedule.title,
      description: dbSchedule.description,
      frequency: dbSchedule.frequency,
      frequencyValue: dbSchedule.frequency_value,
      category: dbSchedule.category,
      nextDueDate: dbSchedule.next_due_date,
      lastCompletedDate: dbSchedule.last_completed_date,
      isActive: dbSchedule.is_active,
      estimatedCost: dbSchedule.estimated_cost,
      assignedTo: dbSchedule.assigned_to,
      createdBy: dbSchedule.created_by,
      createdAt: dbSchedule.created_at,
      updatedAt: dbSchedule.updated_at
    }));

    // Sort by due date (most overdue first)
    dueSchedules = sortItems(dueSchedules, 'nextDueDate', 'asc');

    // Return response
    const responseData = {
      schedules: dueSchedules,
      count: dueSchedules.length
    };

    return res.status(200).json(createResponse(true, responseData));

  } catch (error) {
    console.error('Due maintenance schedules retrieval error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

module.exports = router;