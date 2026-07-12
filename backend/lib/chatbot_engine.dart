import 'db_service.dart';

class ChatbotEngine {
  static Future<String> generateResponse(int userId, String userMessage) async {
    final lowerMsg = userMessage.toLowerCase();
    
    // Fetch user context for personalization
    final workouts = await DBService.getWorkouts(userId);
    final meals = await DBService.getMeals(userId);
    final stats = await DBService.getStats(userId);
    
    String response = "";

    // 1. Check for specific fitness queries
    if (lowerMsg.contains('workout') || lowerMsg.contains('exercise')) {
      if (workouts.isNotEmpty) {
        final lastWorkout = workouts.first;
        final workoutDate = lastWorkout['workout_date'].toString().split(' ')[0];
        response = "I see your last workout was '${lastWorkout['name']}' on $workoutDate. Great job! ";
      } else {
        response = "You haven't logged any workouts yet! Tracking your exercise is the best way to see progress. ";
      }
      response += "Remember to stay consistent. A mix of strength training and cardio is ideal. What's your focus for today?";
    } 
    else if (lowerMsg.contains('meal') || lowerMsg.contains('food') || lowerMsg.contains('diet') || lowerMsg.contains('ate')) {
      if (meals.isNotEmpty) {
        final totalCals = meals.fold(0, (sum, m) => sum + (int.tryParse(m['calories'].toString()) ?? 0));
        response = "You've logged ${meals.length} meals today totaling $totalCals calories. ";
      } else {
        response = "You haven't logged any meals today. Good nutrition is 70% of the fitness journey! ";
      }
      response += "Make sure you're getting enough protein and staying hydrated! 🥗";
    }
    else if (lowerMsg.contains('progress') || lowerMsg.contains('stats') || lowerMsg.contains('how am i doing')) {
      if (stats.isNotEmpty) {
        final s = stats.first;
        final steps = s['steps'] ?? 0;
        response = "You've taken $steps steps today. ";
        if (steps < 5000) {
          response += "A bit low on the steps! How about a quick 15-minute walk? 🚶‍♂️";
        } else {
          response += "Excellent activity level! Keep it up! 🚀";
        }
      } else {
        response = "You're doing great! Keep tracking your daily activities to see your progress.";
      }
    }
    else if (lowerMsg.contains('hello') || lowerMsg.contains('hi')) {
      response = "Hello! I'm your personal fitness coach. Ready to smash some goals today? 💪";
    }
    else if (lowerMsg.contains('motivation') || lowerMsg.contains('motivate')) {
      response = "Remember why you started. Every drop of sweat is a step closer to your goal. You've got this! 🌟";
    }
    else if (lowerMsg.contains('weight') || lowerMsg.contains('lose')) {
      if (stats.isNotEmpty && stats.first['weight'] != null) {
        response = "Your current weight is logged at ${stats.first['weight']}kg. ";
      }
      response += "For sustainable weight loss, aim for a small caloric deficit and regular strength training. Consistency is key! ⚖️";
    }
    else if (lowerMsg.contains('tip') || lowerMsg.contains('health')) {
      final tips = [
        "Drink at least 3 liters of water daily! 💧",
        "Try to get at least 7-8 hours of sleep for recovery. 😴",
        "Don't skip your warm-up! 🤸‍♂️",
        "Focus on whole foods instead of processed ones. 🍎"
      ];
      final randomTip = tips[DateTime.now().millisecond % tips.length];
      response = "Here's a health tip: $randomTip";
    }
    else {
      response = "That's interesting! As your coach, I recommend staying tracked with your workouts and nutrition. Anything specific you'd like to discuss about your fitness journey? 🎯";
    }

    return response;
  }
}
