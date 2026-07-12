import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_providers.dart';
import '../widgets/custom_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _workoutReminders = true;
  bool _mealReminders = true;
  TimeOfDay _workoutTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _mealTime = const TimeOfDay(hour: 12, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              title: const Text('Workout Reminders'),
              subtitle: const Text('Get notified to exercise daily'),
              value: _workoutReminders,
              onChanged: (value) => setState(() => _workoutReminders = value),
              secondary: const Icon(Icons.fitness_center),
            ),
          ),
          if (_workoutReminders)
            Card(
              child: ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Workout Time'),
                subtitle: Text(_workoutTime.format(context)),
                onTap: _selectWorkoutTime,
              ),
            ),
          Card(
            child: SwitchListTile(
              title: const Text('Meal Reminders'),
              subtitle: const Text('Get notified for meal times'),
              value: _mealReminders,
              onChanged: (value) => setState(() => _mealReminders = value),
              secondary: const Icon(Icons.restaurant),
            ),
          ),
          if (_mealReminders)
            Card(
              child: ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Meal Time'),
                subtitle: Text(_mealTime.format(context)),
                onTap: _selectMealTime,
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reminder settings saved!')),
              );
              Navigator.pop(context);
            },
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectWorkoutTime() async {
    final time = await showTimePicker(context: context, initialTime: _workoutTime);
    if (time != null) setState(() => _workoutTime = time);
  }

  Future<void> _selectMealTime() async {
    final time = await showTimePicker(context: context, initialTime: _mealTime);
    if (time != null) setState(() => _mealTime = time);
  }
}

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final friends = [
      {'name': 'Sarah Johnson', 'points': 2840, 'avatar': 'SJ', 'color': Colors.purple},
      {'name': 'Mike Chen', 'points': 2650, 'avatar': 'MC', 'color': Colors.blue},
      {'name': 'Emma Wilson', 'points': 2420, 'avatar': 'EW', 'color': Colors.pink},
      {'name': 'Alex Rivera', 'points': 2190, 'avatar': 'AR', 'color': Colors.orange},
      {'name': 'Jessica Lee', 'points': 1980, 'avatar': 'JL', 'color': Colors.teal},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friend = friends[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: friend['color'] as Color,
                child: Text(friend['avatar'] as String),
              ),
              title: Text(friend['name'] as String),
              subtitle: Text('${friend['points']} points'),
              trailing: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          );
        },
      ),
    );
  }
}