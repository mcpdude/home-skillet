const express = require('express');
const db = require('../config/database');
const { authenticate } = require('../middleware/auth');
const { 
  createResponse, 
  createErrorResponse
} = require('../utils/helpers');

const router = express.Router();

/**
 * GET /api/v1/reports/dashboard
 * Get comprehensive dashboard statistics for the authenticated user
 */
router.get('/dashboard', authenticate, async (req, res) => {
  try {
    const userId = req.user.id;

    // Get user's properties (owned + accessible)
    const userPropertiesQuery = db('properties')
      .where('owner_id', userId)
      .orWhereExists(function() {
        this.select('*')
          .from('property_permissions')
          .whereRaw('property_permissions.property_id = properties.id')
          .andWhere('property_permissions.user_id', userId);
      });

    const userProperties = await userPropertiesQuery.select('id');
    const propertyIds = userProperties.map(p => p.id);

    if (propertyIds.length === 0) {
      return res.json(createResponse(true, {
        properties: { total: 0, byType: {}, averageAge: 0, withActiveProjects: 0 },
        projects: { total: 0, byStatus: {}, byPriority: {}, overdue: 0, budget: { total: 0, actual: 0, variance: 0 } },
        tasks: { total: 0, byStatus: {}, completionRate: 0, averageCompletionDays: 0 },
        summary: { totalBudget: 0, totalSpent: 0, savings: 0, activeProjects: 0, completedTasks: 0 }
      }));
    }

    // Execute all queries in parallel for better performance
    const [
      propertyStats,
      propertyTypes,
      propertyAges,
      propertiesWithActiveProjects,
      projectStats,
      projectsByStatus,
      projectsByPriority,
      overdueProjects,
      projectBudgets,
      taskStats,
      tasksByStatus,
      completedTasksWithDuration
    ] = await Promise.all([
      // Property statistics
      db('properties')
        .whereIn('id', propertyIds)
        .count('* as total')
        .first(),

      // Properties by type
      db('properties')
        .whereIn('id', propertyIds)
        .select('type')
        .count('* as count')
        .groupBy('type'),

      // Property ages (for average calculation)
      db('properties')
        .whereIn('id', propertyIds)
        .select('year_built')
        .whereNotNull('year_built'),

      // Properties with active projects
      db('properties')
        .whereIn('properties.id', propertyIds)
        .join('projects', 'properties.id', 'projects.property_id')
        .where('projects.status', 'in_progress')
        .countDistinct('properties.id as count')
        .first(),

      // Project statistics
      db('projects')
        .whereIn('property_id', propertyIds)
        .count('* as total')
        .first(),

      // Projects by status
      db('projects')
        .whereIn('property_id', propertyIds)
        .select('status')
        .count('* as count')
        .groupBy('status'),

      // Projects by priority
      db('projects')
        .whereIn('property_id', propertyIds)
        .select('priority')
        .count('* as count')
        .groupBy('priority'),

      // Overdue projects
      db('projects')
        .whereIn('property_id', propertyIds)
        .where('due_date', '<', new Date())
        .whereNot('status', 'completed')
        .count('* as count')
        .first(),

      // Project budget analysis
      db('projects')
        .whereIn('property_id', propertyIds)
        .select(
          db.raw('SUM(budget) as total_budget'),
          db.raw('SUM(actual_cost) as total_actual'),
          db.raw('COUNT(*) as project_count')
        )
        .first(),

      // Task statistics
      db('project_tasks')
        .join('projects', 'project_tasks.project_id', 'projects.id')
        .whereIn('projects.property_id', propertyIds)
        .count('* as total')
        .first(),

      // Tasks by status
      db('project_tasks')
        .join('projects', 'project_tasks.project_id', 'projects.id')
        .whereIn('projects.property_id', propertyIds)
        .select('project_tasks.status')
        .count('* as count')
        .groupBy('project_tasks.status'),

      // Completed tasks with duration for average calculation
      db('project_tasks')
        .join('projects', 'project_tasks.project_id', 'projects.id')
        .whereIn('projects.property_id', propertyIds)
        .where('project_tasks.status', 'completed')
        .whereNotNull('project_tasks.completed_at')
        .select(
          db.raw('JULIANDAY(project_tasks.completed_at) - JULIANDAY(project_tasks.created_at) as duration_days')
        )
    ]);

    // Process property statistics
    const currentYear = new Date().getFullYear();
    const validAges = propertyAges.filter(p => p.year_built && p.year_built > 1800);
    const averageAge = validAges.length > 0 
      ? Math.round(validAges.reduce((sum, p) => sum + (currentYear - p.year_built), 0) / validAges.length)
      : 0;

    const propertyTypeMap = {};
    propertyTypes.forEach(pt => {
      propertyTypeMap[pt.type] = pt.count;
    });

    // Process project statistics
    const projectStatusMap = {};
    projectsByStatus.forEach(ps => {
      projectStatusMap[ps.status] = ps.count;
    });

    const projectPriorityMap = {};
    projectsByPriority.forEach(pp => {
      projectPriorityMap[pp.priority] = pp.count;
    });

    const totalBudget = projectBudgets.total_budget || 0;
    const totalActual = projectBudgets.total_actual || 0;
    const budgetVariance = totalBudget - totalActual;

    // Process task statistics
    const taskStatusMap = {};
    tasksByStatus.forEach(ts => {
      taskStatusMap[ts.status] = ts.count;
    });

    const completedTasks = taskStatusMap.completed || 0;
    const totalTasks = parseInt(taskStats.total) || 0;
    const completionRate = totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 0;

    const averageCompletionDays = completedTasksWithDuration.length > 0
      ? Math.round(completedTasksWithDuration.reduce((sum, task) => sum + task.duration_days, 0) / completedTasksWithDuration.length)
      : 0;

    // Build response
    const dashboardData = {
      properties: {
        total: parseInt(propertyStats.total) || 0,
        byType: propertyTypeMap,
        averageAge,
        withActiveProjects: parseInt(propertiesWithActiveProjects.count) || 0
      },
      projects: {
        total: parseInt(projectStats.total) || 0,
        byStatus: projectStatusMap,
        byPriority: projectPriorityMap,
        overdue: parseInt(overdueProjects.count) || 0,
        budget: {
          total: totalBudget,
          actual: totalActual,
          variance: budgetVariance
        }
      },
      tasks: {
        total: totalTasks,
        byStatus: taskStatusMap,
        completionRate,
        averageCompletionDays
      },
      summary: {
        totalBudget,
        totalSpent: totalActual,
        savings: budgetVariance > 0 ? budgetVariance : 0,
        activeProjects: projectStatusMap.in_progress || 0,
        completedTasks
      }
    };

    res.json(createResponse(true, dashboardData));

  } catch (error) {
    console.error('Dashboard statistics error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

/**
 * GET /api/v1/reports/properties/:id/details
 * Get detailed statistics for a specific property
 */
router.get('/properties/:id/details', authenticate, async (req, res) => {
  try {
    const propertyId = req.params.id;
    const userId = req.user.id;

    // Verify user has access to this property
    const property = await db('properties')
      .where('id', propertyId)
      .where(function() {
        this.where('owner_id', userId)
          .orWhereExists(function() {
            this.select('*')
              .from('property_permissions')
              .where('property_id', propertyId)
              .where('user_id', userId);
          });
      })
      .first();

    if (!property) {
      const { error: errorObj, statusCode } = createErrorResponse('Property not found or access denied', 404);
      return res.status(statusCode).json(createResponse(false, null, errorObj));
    }

    // Get detailed property statistics
    const [
      projectsOverview,
      tasksByProject,
      recentActivity,
      budgetAnalysis,
      timeTrackingSummary
    ] = await Promise.all([
      // Projects overview
      db('projects')
        .where('property_id', propertyId)
        .select(
          'status',
          'priority',
          db.raw('COUNT(*) as count'),
          db.raw('SUM(budget) as total_budget'),
          db.raw('SUM(actual_cost) as total_actual')
        )
        .groupBy('status', 'priority'),

      // Tasks by project
      db('projects')
        .leftJoin('project_tasks', 'projects.id', 'project_tasks.project_id')
        .where('projects.property_id', propertyId)
        .select(
          'projects.id',
          'projects.title',
          'projects.status as project_status',
          db.raw('COUNT(project_tasks.id) as task_count'),
          db.raw('SUM(CASE WHEN project_tasks.status = "completed" THEN 1 ELSE 0 END) as completed_tasks')
        )
        .groupBy('projects.id', 'projects.title', 'projects.status'),

      // Recent activity (last 30 days)
      db('project_tasks')
        .join('projects', 'project_tasks.project_id', 'projects.id')
        .leftJoin('users', 'project_tasks.assigned_to', 'users.id')
        .where('projects.property_id', propertyId)
        .where('project_tasks.updated_at', '>=', new Date(Date.now() - 30 * 24 * 60 * 60 * 1000))
        .select(
          'project_tasks.id',
          'project_tasks.title',
          'project_tasks.status',
          'project_tasks.updated_at',
          'users.first_name',
          'users.last_name',
          'projects.title as project_title'
        )
        .orderBy('project_tasks.updated_at', 'desc')
        .limit(20),

      // Budget analysis
      db('projects')
        .where('property_id', propertyId)
        .select(
          db.raw('SUM(budget) as total_budgeted'),
          db.raw('SUM(actual_cost) as total_spent'),
          db.raw('COUNT(*) as project_count'),
          db.raw('AVG(budget) as avg_budget')
        )
        .first(),

      // Time tracking summary
      db('task_time_tracking')
        .join('project_tasks', 'task_time_tracking.task_id', 'project_tasks.id')
        .join('projects', 'project_tasks.project_id', 'projects.id')
        .where('projects.property_id', propertyId)
        .where('task_time_tracking.is_active', false)
        .select(
          db.raw('SUM(duration_minutes) as total_minutes'),
          db.raw('COUNT(*) as session_count'),
          db.raw('AVG(duration_minutes) as avg_session_minutes')
        )
        .first()
    ]);

    // Process the data
    const projectsData = tasksByProject.map(project => ({
      ...project,
      completionRate: project.task_count > 0 ? Math.round((project.completed_tasks / project.task_count) * 100) : 0
    }));

    const recentActivityData = recentActivity.map(activity => ({
      ...activity,
      assignedTo: activity.first_name && activity.last_name 
        ? `${activity.first_name} ${activity.last_name}` 
        : 'Unassigned'
    }));

    const totalMinutes = timeTrackingSummary.total_minutes || 0;
    const totalHours = Math.round((totalMinutes / 60) * 100) / 100;

    const propertyDetails = {
      property: {
        id: property.id,
        name: property.name,
        address: property.address,
        type: property.type
      },
      overview: {
        totalProjects: projectsData.length,
        totalTasks: projectsData.reduce((sum, p) => sum + p.task_count, 0),
        completedTasks: projectsData.reduce((sum, p) => sum + p.completed_tasks, 0),
        totalHoursTracked: totalHours
      },
      projects: projectsData,
      budget: {
        totalBudgeted: budgetAnalysis.total_budgeted || 0,
        totalSpent: budgetAnalysis.total_spent || 0,
        variance: (budgetAnalysis.total_budgeted || 0) - (budgetAnalysis.total_spent || 0),
        averageBudget: budgetAnalysis.avg_budget || 0
      },
      timeTracking: {
        totalHours,
        sessionCount: timeTrackingSummary.session_count || 0,
        averageSessionMinutes: Math.round(timeTrackingSummary.avg_session_minutes || 0)
      },
      recentActivity: recentActivityData
    };

    res.json(createResponse(true, propertyDetails));

  } catch (error) {
    console.error('Property details error:', error);
    const { error: errorObj, statusCode } = createErrorResponse('Internal server error', 500);
    return res.status(statusCode).json(createResponse(false, null, errorObj));
  }
});

module.exports = router;