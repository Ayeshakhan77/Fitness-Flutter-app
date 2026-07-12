import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_providers.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress & Analytics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Weekly Steps', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: _buildStepsChart(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Weekly Calories Burned', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: _buildCaloriesChart(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Calories: Burned vs Consumed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: _buildPieChart(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsChart(BuildContext context) {
    final statsProvider = Provider.of<StatsProvider>(context);
    final weeklySteps = statsProvider.getWeeklySteps();
    final spots = <FlSpot>[];
    int i = 0;
    weeklySteps.forEach((date, steps) {
      spots.add(FlSpot(i.toDouble(), steps.toDouble()));
      i++;
    });

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: const FlTitlesData(show: true),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.1)),
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesChart(BuildContext context) {
    final statsProvider = Provider.of<StatsProvider>(context);
    final weeklyCalories = statsProvider.getWeeklyCalories();
    final spots = <FlSpot>[];
    int i = 0;
    weeklyCalories.forEach((date, calories) {
      spots.add(FlSpot(i.toDouble(), calories.toDouble()));
      i++;
    });

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: const FlTitlesData(show: true),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.orange,
            barWidth: 3,
            belowBarData: BarAreaData(show: true, color: Colors.orange.withOpacity(0.1)),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final mealProvider = Provider.of<MealProvider>(context);
    
    final burned = workoutProvider.totalCaloriesBurned.toDouble();
    final consumed = mealProvider.totalCaloriesConsumed.toDouble();
    
    if (burned == 0 && consumed == 0) {
      return const Center(child: Text('No data available yet'));
    }

    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: burned,
            title: 'Burned\n${burned.toInt()}',
            color: Colors.orange,
            radius: 80,
          ),
          PieChartSectionData(
            value: consumed,
            title: 'Consumed\n${consumed.toInt()}',
            color: Colors.red,
            radius: 80,
          ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }
}