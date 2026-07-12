import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_providers.dart';
import '../widgets/custom_widgets.dart';
import 'workout_screens.dart';
import 'meal_screens.dart';
import 'progress_screen.dart';
import 'chatbot_screen.dart';
import 'profile_screen.dart';
import 'advanced_screens.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  @override
  void initState() {
    super.initState();
    // Load all data from server on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AuthProvider.loadAllUserData(context);
    });
  }
  
  final List<Widget> _screens = [
    const DashboardScreen(),
    const WorkoutListScreen(),
    const MealListScreen(),
    const ProgressScreen(),
    const FitnessCoachScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Workouts'),
          NavigationDestination(icon: Icon(Icons.restaurant), label: 'Meals'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Progress'),
          NavigationDestination(icon: Icon(Icons.chat), label: 'Coach'),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _navigateToWorkouts(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutListScreen()));
  }

  void _navigateToMeals(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const MealListScreen()));
  }

  void _navigateToProgress(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen()));
  }

  void _navigateToChat(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const FitnessCoachScreen()));
  }

  Widget _buildMotivationalMessage() {
    final messages = [
      '🌟 "The only bad workout is the one that didn\'t happen!"',
      '💪 "Small steps every day lead to big results!"',
      '🏆 "Your only limit is you. Push harder!"',
      '🔥 "Stay focused, stay strong, stay healthy!"',
      '🎯 "Consistency is more important than perfection!"',
    ];
    final randomMessage = messages[DateTime.now().second % messages.length];
    
    return Card(
      color: Colors.green.shade100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.green, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(randomMessage, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final mealProvider = Provider.of<MealProvider>(context);
    final statsProvider = Provider.of<StatsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    final todayCaloriesBurned = workoutProvider.todaysWorkouts.fold(0, (sum, w) => sum + w.caloriesBurned);
    final todayCaloriesConsumed = mealProvider.todaysMeals.fold(0, (sum, m) => sum + m.calories);
    final workoutProgress = workoutProvider.totalWorkouts > 0 
        ? (workoutProvider.weeklyWorkouts / 5 * 100).toInt() 
        : 0;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Hello, ${authProvider.currentUser?.name ?? 'User'}!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMotivationalMessage(),
              const SizedBox(height: 20),
              
              // Compact Stats Row instead of Grid
              Row(
                children: [
                  Expanded(
                    child: CompactStatsCard(
                      title: 'Steps',
                      value: '${statsProvider.stats.steps}',
                      unit: 'steps',
                      icon: Icons.directions_walk,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CompactStatsCard(
                      title: 'Burned',
                      value: todayCaloriesBurned.toString(),
                      unit: 'kcal',
                      icon: Icons.local_fire_department,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CompactStatsCard(
                      title: 'Consumed',
                      value: todayCaloriesConsumed.toString(),
                      unit: 'kcal',
                      icon: Icons.restaurant,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CompactStatsCard(
                      title: 'Progress',
                      value: '$workoutProgress',
                      unit: '%',
                      icon: Icons.trending_up,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Section Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Quick Actions Grid - 2x2
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
                children: [
                  QuickActionCircle(
                    icon: Icons.fitness_center,
                    label: 'Workouts',
                    color: Colors.green.shade700,
                    onTap: () => _navigateToWorkouts(context),
                  ),
                  QuickActionCircle(
                    icon: Icons.restaurant,
                    label: 'Meals',
                    color: Colors.orange.shade700,
                    onTap: () => _navigateToMeals(context),
                  ),
                  QuickActionCircle(
                    icon: Icons.bar_chart,
                    label: 'Charts',
                    color: Colors.purple.shade700,
                    onTap: () => _navigateToProgress(context),
                  ),
                  QuickActionCircle(
                    icon: Icons.chat,
                    label: 'Coach',
                    color: Colors.teal.shade700,
                    onTap: () => _navigateToChat(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Today's Summary Section
              Text('Today\'s Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      title: 'Workouts',
                      count: workoutProvider.todaysWorkouts.length,
                      icon: Icons.fitness_center,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SummaryCard(
                      title: 'Meals',
                      count: mealProvider.todaysMeals.length,
                      icon: Icons.restaurant,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Feature Cards
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.emoji_events, color: Colors.amber),
                  ),
                  title: const Text('Leaderboard', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('See how you rank with friends'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.notifications, color: Colors.blue),
                  ),
                  title: const Text('Reminders', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Set workout and meal reminders'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// New compact stats card widget
class CompactStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const CompactStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          ),
          Text(
            unit,
            style: const TextStyle(fontSize: 8, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// New circular quick action button
class QuickActionCircle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const QuickActionCircle({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// New summary card widget
class SummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const SummaryCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  '$count',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}