import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const HomeSkilletsApp());
}

class HomeSkilletsApp extends StatelessWidget {
  const HomeSkilletsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Skillet',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  String _message = '';

  Future<void> _authenticate() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final endpoint = _isLogin ? 'login' : 'register';
      final body = _isLogin
          ? {
              'email': _emailController.text,
              'password': _passwordController.text,
            }
          : {
              'firstName': _nameController.text.split(' ').first,
              'lastName': _nameController.text.split(' ').length > 1 
                  ? _nameController.text.split(' ').sublist(1).join(' ') 
                  : 'User',
              'email': _emailController.text,
              'password': _passwordController.text,
              'userType': 'property_owner',
            };

      final response = await http.post(
        Uri.parse('https://web-production-8014.up.railway.app/api/v1/auth/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MainScreen(
              token: data['data']['token'],
              userName: '${data['data']['user']['firstName'] ?? ''} ${data['data']['user']['lastName'] ?? ''}'.trim(),
            ),
          ),
        );
      } else {
        final error = json.decode(response.body);
        String errorMessage = error['error']?['message'] ?? error['message'] ?? 'Authentication failed';
        
        // Add details if validation errors exist
        if (error['error']?['details'] != null) {
          final details = error['error']['details'] as List;
          errorMessage += '\n' + details.map((d) => d['message']).join('\n');
        }
        
        setState(() {
          _message = errorMessage;
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Network error. Please check your internet connection';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Register'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.home_work,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            const Text(
              'Home Skillet',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            if (!_isLogin) ...[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                helperText: _isLogin ? null : 'Min 8 chars with uppercase, lowercase, number & symbol',
                helperMaxLines: 2,
              ),
            ),
            const SizedBox(height: 20),
            if (_message.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _message.contains('success') ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _message,
                  style: TextStyle(
                    color: _message.contains('success') ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _authenticate,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_isLogin ? 'Login' : 'Register'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLogin = !_isLogin;
                  _message = '';
                });
              },
              child: Text(
                _isLogin
                    ? "Don't have an account? Register"
                    : 'Already have an account? Login',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final String token;
  final String userName;

  const MainScreen({
    Key? key,
    required this.token,
    required this.userName,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<dynamic> _properties = [];
  List<dynamic> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load properties
      final propertiesResponse = await http.get(
        Uri.parse('https://web-production-8014.up.railway.app/api/v1/properties'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      // Load projects
      final projectsResponse = await http.get(
        Uri.parse('https://web-production-8014.up.railway.app/api/v1/projects'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (propertiesResponse.statusCode == 200 && projectsResponse.statusCode == 200) {
        final propertiesData = json.decode(propertiesResponse.body);
        final projectsData = json.decode(projectsResponse.body);

        setState(() {
          _properties = propertiesData['data'] ?? [];
          _projects = projectsData['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add Property Dialog
  void _showAddPropertyDialog() {
    final _propertyNameController = TextEditingController();
    final _propertyAddressController = TextEditingController();
    String _propertyType = 'residential';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Property'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _propertyNameController,
                decoration: const InputDecoration(
                  labelText: 'Property Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _propertyAddressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _propertyType,
                decoration: const InputDecoration(
                  labelText: 'Property Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'residential', child: Text('Residential')),
                  DropdownMenuItem(value: 'commercial', child: Text('Commercial')),
                  DropdownMenuItem(value: 'industrial', child: Text('Industrial')),
                  DropdownMenuItem(value: 'mixed-use', child: Text('Mixed Use')),
                ],
                onChanged: (value) {
                  _propertyType = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_propertyNameController.text.isNotEmpty) {
                await _createProperty(
                  _propertyNameController.text,
                  _propertyAddressController.text,
                  _propertyType,
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add Property'),
          ),
        ],
      ),
    );
  }

  Future<void> _createProperty(String name, String address, String type) async {
    try {
      final response = await http.post(
        Uri.parse('https://web-production-8014.up.railway.app/api/v1/properties'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'address': address,
          'type': type,
          'description': 'Property created from mobile app',
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Property added successfully!')),
        );
        _loadData(); // Refresh the data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add property')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error')),
      );
    }
  }

  // Add Project Dialog
  void _showAddProjectDialog() {
    final _projectTitleController = TextEditingController();
    final _projectDescriptionController = TextEditingController();
    String? _selectedPropertyId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Project'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _projectTitleController,
                decoration: const InputDecoration(
                  labelText: 'Project Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _projectDescriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPropertyId,
                decoration: const InputDecoration(
                  labelText: 'Select Property',
                  border: OutlineInputBorder(),
                ),
                items: _properties.map<DropdownMenuItem<String>>((property) {
                  return DropdownMenuItem<String>(
                    value: property['id'].toString(),
                    child: Text(property['name'] ?? 'Unnamed Property'),
                  );
                }).toList(),
                onChanged: (value) {
                  _selectedPropertyId = value;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_projectTitleController.text.isNotEmpty && _selectedPropertyId != null) {
                await _createProject(
                  _projectTitleController.text,
                  _projectDescriptionController.text,
                  int.parse(_selectedPropertyId!),
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add Project'),
          ),
        ],
      ),
    );
  }

  Future<void> _createProject(String title, String description, int propertyId) async {
    try {
      final response = await http.post(
        Uri.parse('https://web-production-8014.up.railway.app/api/v1/projects'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'title': title,
          'description': description,
          'property_id': propertyId,
          'status': 'pending',
          'priority': 'medium',
          'tasks': []
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project added successfully!')),
        );
        _loadData(); // Refresh the data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add project')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error')),
      );
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${widget.userName}!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Properties', '${_properties.length}', Icons.home, Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard('Projects', '${_projects.length}', Icons.work, Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showAddPropertyDialog,
                  icon: const Icon(Icons.add_home),
                  label: const Text('Add Property'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showAddProjectDialog,
                  icon: const Icon(Icons.add_task),
                  label: const Text('Add Project'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Recent Properties',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          ..._properties.take(3).map((property) => _buildPropertyCard(property)),
          const SizedBox(height: 20),
          const Text(
            'Recent Projects',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          ..._projects.take(3).map((project) => _buildProjectCard(project)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(title, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyCard(dynamic property) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.home_outlined),
        title: Text(property['name'] ?? 'Unnamed Property'),
        subtitle: Text(property['address'] ?? 'No address'),
        trailing: Text(property['type'] ?? 'residential'),
      ),
    );
  }

  Widget _buildProjectCard(dynamic project) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.work_outline),
        title: Text(project['title'] ?? 'Unnamed Project'),
        subtitle: Text(project['description'] ?? 'No description'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(project['status']),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            project['status'] ?? 'pending',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPropertiesTab() {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'My Properties',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (_properties.isEmpty)
                    const Center(
                      child: Column(
                        children: [
                          Icon(Icons.home_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No properties yet', style: TextStyle(fontSize: 16)),
                          SizedBox(height: 8),
                          Text('Tap the + button to add your first property'),
                        ],
                      ),
                    )
                  else
                    ..._properties.map((property) => _buildPropertyCard(property)),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "properties_fab",
        onPressed: _showAddPropertyDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProjectsTab() {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'My Projects',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (_projects.isEmpty)
                    const Center(
                      child: Column(
                        children: [
                          Icon(Icons.work_outline, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No projects yet', style: TextStyle(fontSize: 16)),
                          SizedBox(height: 8),
                          Text('Tap the + button to add your first project'),
                        ],
                      ),
                    )
                  else
                    ..._projects.map((project) => _buildProjectCard(project)),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "projects_fab",
        onPressed: _showAddProjectDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProfileTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    child: Icon(Icons.person, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.userName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text('${_properties.length} Properties • ${_projects.length} Projects'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon!')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help section coming soon!')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AuthScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildDashboard(),
      _buildPropertiesTab(),
      _buildProjectsTab(),
      _buildProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Skillet'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Properties',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}