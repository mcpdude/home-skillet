import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../models/project.dart';
import '../../models/task.dart';
import '../../models/property.dart';
import '../../providers/project_provider.dart';
import '../../providers/property_provider.dart';
import '../../utils/form_validators.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/error_message.dart';

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({Key? key}) : super(key: key);

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _notesController = TextEditingController();
  
  Property? _selectedProperty;
  ProjectPriority _selectedPriority = ProjectPriority.medium;
  DateTime? _selectedDueDate;
  DateTime? _selectedStartDate;
  
  final List<TaskFormData> _tasks = [];
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProperties();
    _addNewTask(); // Start with one empty task
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _notesController.dispose();
    for (final task in _tasks) {
      task.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProperties() async {
    await context.read<PropertyProvider>().loadProperties();
  }

  void _addNewTask() {
    setState(() {
      _tasks.add(TaskFormData());
    });
  }

  void _removeTask(int index) {
    if (_tasks.length > 1) { // Keep at least one task
      setState(() {
        _tasks[index].dispose();
        _tasks.removeAt(index);
      });
    }
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _selectedStartDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedProperty == null) {
      setState(() {
        _errorMessage = _selectedProperty == null 
            ? 'Please select a property for this project'
            : 'Please fix the errors in the form';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Validate tasks
      final validTasks = <TaskFormData>[];
      for (final task in _tasks) {
        if (task.titleController.text.trim().isNotEmpty) {
          validTasks.add(task);
        }
      }

      if (validTasks.isEmpty) {
        setState(() {
          _errorMessage = 'Please add at least one task';
        });
        return;
      }

      // Create project
      final now = DateTime.now();
      final project = Project(
        id: '', // Will be set by backend
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        status: ProjectStatus.planned,
        priority: _selectedPriority,
        startDate: _selectedStartDate,
        dueDate: _selectedDueDate,
        estimatedCost: _budgetController.text.trim().isEmpty 
            ? null 
            : double.tryParse(_budgetController.text.trim()),
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        propertyId: _selectedProperty!.id,
        userId: '', // Will be set by backend
        createdAt: now,
        updatedAt: now,
      );

      // Create the project first
      final success = await context.read<ProjectProvider>().createProject(project);
      
      if (success && mounted) {
        // If project creation was successful, we would typically create tasks here
        // For now, we'll navigate back and show success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else {
        setState(() {
          _errorMessage = context.read<ProjectProvider>().errorMessage ?? 
                         'Failed to create project. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isSubmitting,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Project'),
          actions: [
            TextButton(
              onPressed: _isSubmitting ? null : _submitForm,
              child: Text(
                'CREATE',
                style: TextStyle(
                  color: _isSubmitting 
                      ? Colors.grey 
                      : Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                _buildBasicInfoSection(),
                const SizedBox(height: 24),
                _buildPropertySelection(),
                const SizedBox(height: 24),
                _buildProjectDetailsSection(),
                const SizedBox(height: 24),
                _buildTasksSection(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Project Title *',
                hintText: 'e.g., Kitchen Renovation',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.construction),
              ),
              validator: FormValidators.required,
              textCapitalization: TextCapitalization.words,
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe what needs to be done...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertySelection() {
    return Consumer<PropertyProvider>(
      builder: (context, propertyProvider, child) {
        final properties = propertyProvider.properties;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Property Selection',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                if (properties.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No properties found. Please add a property first.',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  DropdownButtonFormField<Property>(
                    decoration: const InputDecoration(
                      labelText: 'Select Property *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.home),
                    ),
                    value: _selectedProperty,
                    items: properties.map((property) {
                      return DropdownMenuItem(
                        value: property,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              property.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              property.address,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (property) {
                      setState(() {
                        _selectedProperty = property;
                        _errorMessage = null; // Clear error when property is selected
                      });
                    },
                    validator: (value) => value == null ? 'Please select a property' : null,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProjectDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Priority Selection
            DropdownButtonFormField<ProjectPriority>(
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag),
              ),
              value: _selectedPriority,
              items: ProjectPriority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getPriorityColor(priority),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_getPriorityText(priority)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (priority) {
                if (priority != null) {
                  setState(() {
                    _selectedPriority = priority;
                  });
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            // Date Selection
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectStartDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start Date',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                _selectedStartDate != null
                                    ? _formatDate(_selectedStartDate!)
                                    : 'Select date',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectDueDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event, size: 20),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Due Date',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                _selectedDueDate != null
                                    ? _formatDate(_selectedDueDate!)
                                    : 'Select date',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Budget
            TextFormField(
              controller: _budgetController,
              decoration: const InputDecoration(
                labelText: 'Estimated Budget',
                hintText: 'e.g., 5000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final budget = double.tryParse(value);
                  if (budget == null || budget < 0) {
                    return 'Please enter a valid budget amount';
                  }
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                hintText: 'Any additional information...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tasks (${_tasks.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addNewTask,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Task'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Break down your project into manageable tasks',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            
            ..._tasks.asMap().entries.map((entry) {
              final index = entry.key;
              final task = entry.value;
              return _buildTaskFormItem(index, task);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskFormItem(int index, TaskFormData task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.drag_handle,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Task ${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_tasks.length > 1)
                  IconButton(
                    onPressed: () => _removeTask(index),
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.red,
                    tooltip: 'Remove task',
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            TextFormField(
              controller: task.titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                hintText: 'e.g., Remove old cabinets',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              textCapitalization: TextCapitalization.words,
            ),
            
            const SizedBox(height: 12),
            
            TextFormField(
              controller: task.descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Task details...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TaskPriority>(
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    value: task.priority,
                    items: TaskPriority.values.map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getTaskPriorityColor(priority),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(_getTaskPriorityText(priority)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (priority) {
                      if (priority != null) {
                        setState(() {
                          task.priority = priority;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: task.estimatedHoursController,
                    decoration: const InputDecoration(
                      labelText: 'Est. Hours',
                      hintText: '2',
                      border: OutlineInputBorder(),
                      isDense: true,
                      suffixText: 'hrs',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final hours = double.tryParse(value);
                        if (hours == null || hours <= 0) {
                          return 'Valid hours required';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(ProjectPriority priority) {
    switch (priority) {
      case ProjectPriority.urgent:
        return Colors.red;
      case ProjectPriority.high:
        return Colors.orange;
      case ProjectPriority.medium:
        return Colors.blue;
      case ProjectPriority.low:
        return Colors.grey;
    }
  }

  String _getPriorityText(ProjectPriority priority) {
    switch (priority) {
      case ProjectPriority.urgent:
        return 'Urgent';
      case ProjectPriority.high:
        return 'High';
      case ProjectPriority.medium:
        return 'Medium';
      case ProjectPriority.low:
        return 'Low';
    }
  }

  Color _getTaskPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return Colors.red;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.low:
        return Colors.grey;
    }
  }

  String _getTaskPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return 'Urgent';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class TaskFormData {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController estimatedHoursController = TextEditingController();
  TaskPriority priority = TaskPriority.medium;

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    estimatedHoursController.dispose();
  }
}