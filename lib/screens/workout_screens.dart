import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../providers/app_providers.dart';
import '../widgets/custom_widgets.dart';

class WorkoutListScreen extends StatelessWidget {
  const WorkoutListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Workouts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutSearchScreen())),
          ),
        ],
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, provider, _) {
          if (provider.workouts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No workouts yet', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Tap + to add your first workout'),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.workouts.length,
            itemBuilder: (context, index) {
              final workout = provider.workouts[index];
              return WorkoutCard(
                workout: workout,
                onEdit: () => _editWorkout(context, workout),
                onDelete: () => _deleteWorkout(context, provider, workout.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addWorkout(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Workout'),
      ),
    );
  }

  void _addWorkout(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutFormScreen(isEditing: false)));
  }

  void _editWorkout(BuildContext context, Workout workout) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => WorkoutFormScreen(isEditing: true, workout: workout)));
  }

  void _deleteWorkout(BuildContext context, WorkoutProvider provider, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout'),
        content: const Text('Are you sure you want to delete this workout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.deleteWorkout(id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workout deleted')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class WorkoutFormScreen extends StatefulWidget {
  final bool isEditing;
  final Workout? workout;
  
  const WorkoutFormScreen({super.key, required this.isEditing, this.workout});

  @override
  State<WorkoutFormScreen> createState() => _WorkoutFormScreenState();
}

class _WorkoutFormScreenState extends State<WorkoutFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  final _caloriesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.workout != null) {
      _nameController.text = widget.workout!.name;
      _durationController.text = widget.workout!.duration.toString();
      _caloriesController.text = widget.workout!.caloriesBurned.toString();
      _selectedDate = widget.workout!.date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Workout' : 'Add Workout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _nameController,
                label: 'Workout Name',
                icon: Icons.fitness_center,
                validator: (value) => value?.isEmpty ?? true ? 'Workout name required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _durationController,
                label: 'Duration (minutes)',
                icon: Icons.timer,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Duration required';
                  if (int.tryParse(value!) == null) return 'Must be a number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _caloriesController,
                label: 'Calories Burned',
                icon: Icons.local_fire_department,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Calories required';
                  if (int.tryParse(value!) == null) return 'Must be a number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date'),
                subtitle: Text(_selectedDate.toString().split(' ')[0]),
                onTap: _selectDate,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveWorkout,
                child: Text(widget.isEditing ? 'Update' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  void _saveWorkout() {
    if (_formKey.currentState!.validate()) {
      final workout = Workout(
        id: widget.isEditing ? widget.workout!.id : DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        duration: int.parse(_durationController.text),
        caloriesBurned: int.parse(_caloriesController.text),
        date: _selectedDate,
      );
      
      final provider = Provider.of<WorkoutProvider>(context, listen: false);
      if (widget.isEditing) {
        provider.updateWorkout(widget.workout!.id, workout);
      } else {
        provider.addWorkoutToServer(workout);
      }
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isEditing ? 'Workout updated' : 'Workout added')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }
}

class WorkoutSearchScreen extends StatefulWidget {
  const WorkoutSearchScreen({super.key});

  @override
  State<WorkoutSearchScreen> createState() => _WorkoutSearchScreenState();
}

class _WorkoutSearchScreenState extends State<WorkoutSearchScreen> {
  final _searchController = TextEditingController();
  List<Workout> _filteredWorkouts = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Workouts'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: CustomTextField(
              controller: _searchController,
              label: 'Search by name',
              icon: Icons.search,
              onChanged: _filterWorkouts,
            ),
          ),
        ),
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, provider, _) {
          final workouts = _searchController.text.isEmpty ? provider.workouts : _filteredWorkouts;
          
          if (workouts.isEmpty) {
            return const Center(child: Text('No workouts found'));
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              return WorkoutCard(
                workout: workouts[index],
                onEdit: () {},
                onDelete: () {},
              );
            },
          );
        },
      ),
    );
  }

  void _filterWorkouts(String query) {
    final provider = Provider.of<WorkoutProvider>(context, listen: false);
    setState(() {
      _filteredWorkouts = provider.workouts.where((w) => 
        w.name.toLowerCase().contains(query.toLowerCase())
      ).toList();
    });
  }
}