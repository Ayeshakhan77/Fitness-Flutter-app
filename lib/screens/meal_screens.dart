import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../providers/app_providers.dart';
import '../widgets/custom_widgets.dart';

class MealListScreen extends StatelessWidget {
  const MealListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Meals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MealSearchScreen())),
          ),
        ],
      ),
      body: Consumer<MealProvider>(
        builder: (context, provider, _) {
          if (provider.meals.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No meals logged yet', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Tap + to log your first meal'),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.meals.length,
            itemBuilder: (context, index) {
              final meal = provider.meals[index];
              return MealCard(
                meal: meal,
                onEdit: () => _editMeal(context, meal),
                onDelete: () => _deleteMeal(context, provider, meal.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addMeal(context),
        icon: const Icon(Icons.add),
        label: const Text('Log Meal'),
      ),
    );
  }

  void _addMeal(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const MealFormScreen(isEditing: false)));
  }

  void _editMeal(BuildContext context, Meal meal) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => MealFormScreen(isEditing: true, meal: meal)));
  }

  void _deleteMeal(BuildContext context, MealProvider provider, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal'),
        content: const Text('Are you sure you want to delete this meal?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.deleteMeal(id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meal deleted')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class MealFormScreen extends StatefulWidget {
  final bool isEditing;
  final Meal? meal;
  
  const MealFormScreen({super.key, required this.isEditing, this.meal});

  @override
  State<MealFormScreen> createState() => _MealFormScreenState();
}

class _MealFormScreenState extends State<MealFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  String _selectedType = 'Breakfast';
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime _selectedDate = DateTime.now();
  
  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.meal != null) {
      _nameController.text = widget.meal!.name;
      _caloriesController.text = widget.meal!.calories.toString();
      _selectedType = widget.meal!.type;
      _selectedTime = TimeOfDay.fromDateTime(widget.meal!.time);
      _selectedDate = widget.meal!.date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Meal' : 'Log Meal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _nameController,
                label: 'Meal Name',
                icon: Icons.restaurant,
                validator: (value) => value?.isEmpty ?? true ? 'Meal name required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Meal Type',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.breakfast_dining),
                ),
                items: _mealTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _caloriesController,
                label: 'Calories',
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
                leading: const Icon(Icons.access_time),
                title: const Text('Time'),
                subtitle: Text(_selectedTime.format(context)),
                onTap: _selectTime,
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date'),
                subtitle: Text(_selectedDate.toString().split(' ')[0]),
                onTap: _selectDate,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveMeal,
                child: Text(widget.isEditing ? 'Update' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(context: context, initialTime: _selectedTime);
    if (time != null) setState(() => _selectedTime = time);
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

  void _saveMeal() {
    if (_formKey.currentState!.validate()) {
      final meal = Meal(
        id: widget.isEditing ? widget.meal!.id : DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        type: _selectedType,
        calories: int.parse(_caloriesController.text),
        time: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute),
        date: _selectedDate,
      );
      
      final provider = Provider.of<MealProvider>(context, listen: false);
      if (widget.isEditing) {
        provider.updateMeal(widget.meal!.id, meal);
      } else {
        provider.addMealToServer(meal);
      }
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isEditing ? 'Meal updated' : 'Meal logged')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }
}

class MealSearchScreen extends StatefulWidget {
  const MealSearchScreen({super.key});

  @override
  State<MealSearchScreen> createState() => _MealSearchScreenState();
}

class _MealSearchScreenState extends State<MealSearchScreen> {
  final _searchController = TextEditingController();
  List<Meal> _filteredMeals = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Meals'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: CustomTextField(
              controller: _searchController,
              label: 'Search by name',
              icon: Icons.search,
              onChanged: _filterMeals,
            ),
          ),
        ),
      ),
      body: Consumer<MealProvider>(
        builder: (context, provider, _) {
          final meals = _searchController.text.isEmpty ? provider.meals : _filteredMeals;
          
          if (meals.isEmpty) {
            return const Center(child: Text('No meals found'));
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: meals.length,
            itemBuilder: (context, index) {
              return MealCard(
                meal: meals[index],
                onEdit: () {},
                onDelete: () {},
              );
            },
          );
        },
      ),
    );
  }

  void _filterMeals(String query) {
    final provider = Provider.of<MealProvider>(context, listen: false);
    setState(() {
      _filteredMeals = provider.meals.where((m) => 
        m.name.toLowerCase().contains(query.toLowerCase())
      ).toList();
    });
  }
}