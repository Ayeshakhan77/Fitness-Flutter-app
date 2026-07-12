import 'package:flutter/foundation.dart';

class User {
  String id;
  String name;
  String email;
  String password;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
  });
}

class Workout {
  String id;
  String name;
  int duration; // in minutes
  int caloriesBurned;
  DateTime date;

  Workout({
    required this.id,
    required this.name,
    required this.duration,
    required this.caloriesBurned,
    required this.date,
  });

  Workout copyWith({
    String? id,
    String? name,
    int? duration,
    int? caloriesBurned,
    DateTime? date,
  }) {
    return Workout(
      id: id ?? this.id,
      name: name ?? this.name,
      duration: duration ?? this.duration,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      date: date ?? this.date,
    );
  }
}

class Meal {
  String id;
  String name;
  String type; // Breakfast, Lunch, Dinner, Snack
  int calories;
  DateTime time;
  DateTime date;

  Meal({
    required this.id,
    required this.name,
    required this.type,
    required this.calories,
    required this.time,
    required this.date,
  });

  Meal copyWith({
    String? id,
    String? name,
    String? type,
    int? calories,
    DateTime? time,
    DateTime? date,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      calories: calories ?? this.calories,
      time: time ?? this.time,
      date: date ?? this.date,
    );
  }
}

class ChatMessage {
  String id;
  String text;
  bool isUser;
  DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class FitnessStats {
  int steps;
  int caloriesBurned;
  int caloriesConsumed;
  int workoutProgress; // percentage
  double weight; // in kg

  FitnessStats({
    this.steps = 0,
    this.caloriesBurned = 0,
    this.caloriesConsumed = 0,
    this.workoutProgress = 0,
    this.weight = 70.0,
  });
}