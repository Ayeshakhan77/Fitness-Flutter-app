import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import 'dart:math';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoggedIn = false;
  ThemeMode _themeMode = ThemeMode.light;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  AuthProvider() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await ApiService.init();
    final token = ApiService.getToken();
    final userId = ApiService.getUserId();
    
    if (token != null && userId != null) {
      // For a real app, we might want to fetch user profile here
      // to verify token is still valid. For now, we trust the saved token.
      _currentUser = User(
        id: userId,
        name: 'User', // Placeholder name until profile is fetched
        email: '',
        password: '',
      );
      _isLoggedIn = true;
      notifyListeners();
    }
  }

  // Updated signUp method with API integration
  Future<bool> signUp(String name, String email, String password) async {
    try {
      var response = await ApiService.signUp(name, email, password);
      if (response['success'] == true) {
        _currentUser = User(
          id: response['userId'].toString(),
          name: response['name'],
          email: response['email'],
          password: password,
        );
        _isLoggedIn = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Signup error: $e');
      return false;
    }
  }

  // Updated signIn method with API integration
  Future<bool> signIn(String email, String password) async {
    try {
      var response = await ApiService.signIn(email, password);
      if (response['success'] == true) {
        _currentUser = User(
          id: response['userId'].toString(),
          name: response['name'],
          email: response['email'],
          password: password,
        );
        _isLoggedIn = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Signin error: $e');
      return false;
    }
  }

  void signOut() {
    ApiService.clearAuth();
    _currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }


  void updateUser(String name, String email, String? password) {
    if (_currentUser != null) {
      _currentUser!.name = name;
      _currentUser!.email = email;
      if (password != null && password.isNotEmpty) {
        _currentUser!.password = password;
      }
      notifyListeners();
    }
  }

  void toggleDarkMode() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  bool resetPassword(String email) {
    // This would ideally call an API. For now, we return false as _users is removed.
    return false;
  }

  // Helper to load all data
  static void loadAllUserData(BuildContext context) {
    Provider.of<WorkoutProvider>(context, listen: false).loadWorkoutsFromServer();
    Provider.of<MealProvider>(context, listen: false).loadMealsFromServer();
    Provider.of<StatsProvider>(context, listen: false).loadStatsFromServer();
    Provider.of<ChatbotProvider>(context, listen: false).loadMessagesFromServer();
  }
}

class WorkoutProvider extends ChangeNotifier {
  List<Workout> _workouts = [];

  List<Workout> get workouts => _workouts;
  
  List<Workout> get todaysWorkouts => _workouts.where((w) => 
    w.date.year == DateTime.now().year &&
    w.date.month == DateTime.now().month &&
    w.date.day == DateTime.now().day
  ).toList();

  int get totalCaloriesBurned => _workouts.fold(0, (sum, w) => sum + w.caloriesBurned);
  int get totalWorkouts => _workouts.length;
  
  int get weeklyWorkouts => _workouts.where((w) => 
    w.date.isAfter(DateTime.now().subtract(const Duration(days: 7)))
  ).length;

  void addWorkout(Workout workout) {
    _workouts.add(workout);
    notifyListeners();
  }

  // Add workout to server and local
  Future<void> addWorkoutToServer(Workout workout) async {
    try {
      await ApiService.addWorkout(
        workout.name,
        workout.duration,
        workout.caloriesBurned,
        workout.date.toIso8601String().split('T')[0],
      );
      addWorkout(workout);
    } catch (e) {
      print('Error adding workout to server: $e');
      // Still add locally even if server fails
      addWorkout(workout);
    }
  }

  // Load workouts from server
  Future<void> loadWorkoutsFromServer() async {
    try {
      var workouts = await ApiService.getWorkouts();
      _workouts.clear();
      for (var w in workouts) {
        _workouts.add(Workout(
          id: w['workoutId'],
          name: w['name'],
          duration: w['duration'],
          caloriesBurned: w['caloriesBurned'],
          date: DateTime.parse(w['workoutDate']),
        ));
      }
      notifyListeners();
    } catch (e) {
      print('Error loading workouts from server: $e');
    }
  }

  void updateWorkout(String id, Workout updatedWorkout) {
    final index = _workouts.indexWhere((w) => w.id == id);
    if (index != -1) {
      _workouts[index] = updatedWorkout;
      notifyListeners();
    }
  }

  void deleteWorkout(String id) {
    _workouts.removeWhere((w) => w.id == id);
    notifyListeners();
  }

  List<Workout> getWeeklyWorkouts() {
    return _workouts.where((w) => 
      w.date.isAfter(DateTime.now().subtract(const Duration(days: 7)))
    ).toList();
  }
}

class MealProvider extends ChangeNotifier {
  List<Meal> _meals = [];

  List<Meal> get meals => _meals;
  
  List<Meal> get todaysMeals => _meals.where((m) => 
    m.date.year == DateTime.now().year &&
    m.date.month == DateTime.now().month &&
    m.date.day == DateTime.now().day
  ).toList();

  int get totalCaloriesConsumed => _meals.fold(0, (sum, m) => sum + m.calories);
  int get totalMeals => _meals.length;

  void addMeal(Meal meal) {
    _meals.add(meal);
    notifyListeners();
  }

  // Add meal to server and local
  Future<void> addMealToServer(Meal meal) async {
    try {
      await ApiService.addMeal(
        meal.name,
        meal.type,
        meal.calories,
        '${meal.time.hour}:${meal.time.minute}',
        meal.date.toIso8601String().split('T')[0],
      );
      addMeal(meal);
    } catch (e) {
      print('Error adding meal to server: $e');
      // Still add locally even if server fails
      addMeal(meal);
    }
  }

  // Load meals from server
  Future<void> loadMealsFromServer() async {
    try {
      var meals = await ApiService.getMeals();
      _meals.clear();
      for (var m in meals) {
        var timeParts = m['mealTime'].toString().split(':');
        var mealTime = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );
        
        _meals.add(Meal(
          id: m['mealId'],
          name: m['name'],
          type: m['type'],
          calories: m['calories'],
          time: mealTime,
          date: DateTime.parse(m['mealDate']),
        ));
      }
      notifyListeners();
    } catch (e) {
      print('Error loading meals from server: $e');
    }
  }

  void updateMeal(String id, Meal updatedMeal) {
    final index = _meals.indexWhere((m) => m.id == id);
    if (index != -1) {
      _meals[index] = updatedMeal;
      notifyListeners();
    }
  }

  void deleteMeal(String id) {
    _meals.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  List<Meal> getWeeklyMeals() {
    return _meals.where((m) => 
      m.date.isAfter(DateTime.now().subtract(const Duration(days: 7)))
    ).toList();
  }
}

class StatsProvider extends ChangeNotifier {
  FitnessStats _stats = FitnessStats();

  FitnessStats get stats => _stats;

  void updateSteps(int steps) {
    _stats.steps = steps;
    notifyListeners();
  }

  void updateWeight(double weight) {
    _stats.weight = weight;
    notifyListeners();
  }

  void updateCaloriesBurned(int calories) {
    _stats.caloriesBurned = calories;
    notifyListeners();
  }

  void updateCaloriesConsumed(int calories) {
    _stats.caloriesConsumed = calories;
    notifyListeners();
  }

  // Load stats from server
  Future<void> loadStatsFromServer() async {
    try {
      var stats = await ApiService.getStats();
      _stats.steps = stats['steps'] ?? 0;
      _stats.weight = (stats['weight'] ?? 70).toDouble();
      _stats.caloriesBurned = stats['todayCaloriesBurned'] ?? 0;
      _stats.caloriesConsumed = stats['todayCaloriesConsumed'] ?? 0;
      notifyListeners();
    } catch (e) {
      print('Error loading stats from server: $e');
    }
  }

  Map<DateTime, int> getWeeklySteps() {
    final Map<DateTime, int> weeklySteps = {};
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      weeklySteps[date] = Random().nextInt(8000) + 2000;
    }
    return weeklySteps;
  }

  Map<DateTime, int> getWeeklyCalories() {
    final Map<DateTime, int> weeklyCalories = {};
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      weeklyCalories[date] = Random().nextInt(500) + 200;
    }
    return weeklyCalories;
  }
}

class ChatbotProvider extends ChangeNotifier {
  List<ChatMessage> _messages = [];

  List<ChatMessage> get messages => _messages;

  void addMessage(String text, bool isUser) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
    );
    _messages.add(message);
    notifyListeners();
    
    if (!isUser) return;
    
    Future.delayed(const Duration(milliseconds: 500), () {
      _getBotResponse(text);
    });
  }

  void _getBotResponse(String userMessage) {
    String response;
    final lowerMsg = userMessage.toLowerCase();
    
    if (lowerMsg.contains('hello') || lowerMsg.contains('hi')) {
      response = "Hello! I'm your fitness coach. How can I help you today? 💪";
    } else if (lowerMsg.contains('workout') || lowerMsg.contains('exercise')) {
      response = "Great! Remember to warm up for 5-10 minutes before any workout. Try mixing cardio with strength training for best results! 🏋️‍♂️";
    } else if (lowerMsg.contains('meal') || lowerMsg.contains('food') || lowerMsg.contains('diet')) {
      response = "Nutrition tip: Eat protein with every meal, stay hydrated, and include colorful vegetables in your diet! 🥗";
    } else if (lowerMsg.contains('motivation') || lowerMsg.contains('motivate')) {
      response = "You're doing amazing! Every small step counts. Keep pushing forward! 🌟";
    } else if (lowerMsg.contains('weight') || lowerMsg.contains('lose')) {
      response = "Consistency is key! Combine regular exercise with a balanced diet. Aim for 0.5-1kg loss per week for sustainable results. ⚖️";
    } else if (lowerMsg.contains('sleep')) {
      response = "Quality sleep is crucial for recovery. Aim for 7-9 hours per night! 😴";
    } else {
      response = "Thanks for your message! Remember to stay consistent with your fitness goals. Track your workouts and meals daily for best results! 🎯";
    }
    
    addMessage(response, false);
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
  
// Load messages from server
Future<void> loadMessagesFromServer() async {
  print('🔄 Loading messages from server...');
  try {
    final messages = await ApiService.getChatMessages();
    print('Received ${messages.length} messages from server');
    
    _messages.clear();
    for (var msg in messages) {
      _messages.add(ChatMessage(
        id: msg['messageId'],
        text: msg['message'],
        isUser: msg['isUser'],
        timestamp: DateTime.parse(msg['createdAt']),
      ));
    }
    notifyListeners();
    print('✅ Loaded ${_messages.length} messages');
  } catch (e) {
    print('❌ Error loading messages: $e');
  }
}

// Send message to server
Future<void> sendMessageToServer(String message) async {
  print('📤 Sending message to server: $message');
  try {
    final response = await ApiService.sendChatMessage(message);
    print('Server response: $response');
    
    if (response['success'] == true) {
      // Reload all messages from server
      await loadMessagesFromServer();
    } else {
      // Fallback to local bot
      print('Server failed, using local bot');
      addMessage(message, true);
      _getBotResponse(message);
    }
  } catch (e) {
    print('❌ Error sending message: $e');
    // Fallback to local bot
    addMessage(message, true);
    _getBotResponse(message);
  }
}
}  