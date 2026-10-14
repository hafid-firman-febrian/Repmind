import 'package:repmind/features/plan/domain/models/workout_plan_model.dart';

Map<String, dynamic> exerciseRow(
  String id,
  String name, {
  String focus = 'upper',
  String muscle = 'Chest',
  List<String> equipment = const [],
}) => {
  'id': id,
  'name': name,
  'focus': focus,
  'primary_muscle': muscle,
  'equipment': equipment,
};

Map<String, dynamic> planExerciseRow(
  int position,
  Map<String, dynamic> exercise, {
  int sets = 3,
  String reps = '10',
  int rest = 60,
}) => {
  'id': 'pe-${exercise['id']}',
  'position': position,
  'exercise_id': exercise['id'],
  'sets': sets,
  'reps': reps,
  'rest_seconds': rest,
  'exercises': exercise,
};

Map<String, dynamic> planDayRow({
  required int dayNumber,
  required int weekday,
  required String title,
  required String focus,
  required int minutes,
  required List<Map<String, dynamic>> exercises,
}) => {
  'id': 'day-$dayNumber',
  'plan_id': 'plan-1',
  'day_number': dayNumber,
  'weekday': weekday,
  'title': title,
  'focus': focus,
  'estimated_minutes': minutes,
  'plan_exercises': exercises,
};

List<Map<String, dynamic>> sampleDayRows() => [
  planDayRow(
    dayNumber: 1,
    weekday: 1,
    title: 'Lower Body Power',
    focus: 'lower',
    minutes: 50,
    exercises: [
      planExerciseRow(
        1,
        exerciseRow(
          'goblet_squat',
          'Goblet Squat',
          focus: 'lower',
          muscle: 'Quads',
          equipment: ['dumbbell'],
        ),
        sets: 4,
        reps: '8-10',
        rest: 90,
      ),
      planExerciseRow(
        2,
        exerciseRow(
          'dumbbell_romanian_deadlift',
          'Dumbbell Romanian Deadlift',
          focus: 'lower',
          muscle: 'Hamstrings',
          equipment: ['dumbbell'],
        ),
        rest: 90,
      ),
      planExerciseRow(
        3,
        exerciseRow(
          'reverse_lunge',
          'Reverse Lunge',
          focus: 'lower',
          muscle: 'Quads',
        ),
        reps: '12',
      ),
      planExerciseRow(
        4,
        exerciseRow(
          'glute_bridge',
          'Glute Bridge',
          focus: 'lower',
          muscle: 'Glutes',
        ),
        reps: '15',
        rest: 45,
      ),
      planExerciseRow(
        5,
        exerciseRow(
          'calf_raise',
          'Calf Raise',
          focus: 'lower',
          muscle: 'Calves',
        ),
        reps: '15',
        rest: 45,
      ),
    ],
  ),
  planDayRow(
    dayNumber: 2,
    weekday: 2,
    title: 'Upper Body Push',
    focus: 'upper',
    minutes: 45,
    exercises: [
      planExerciseRow(
        1,
        exerciseRow(
          'dumbbell_bench_press',
          'Dumbbell Bench Press',
          equipment: ['dumbbell', 'bench'],
        ),
        sets: 4,
        reps: '8-10',
        rest: 90,
      ),
      planExerciseRow(
        2,
        exerciseRow(
          'dumbbell_shoulder_press',
          'Dumbbell Shoulder Press',
          muscle: 'Shoulders',
          equipment: ['dumbbell'],
        ),
        rest: 90,
      ),
      planExerciseRow(3, exerciseRow('push_up', 'Push-up'), reps: '12'),
      planExerciseRow(
        4,
        exerciseRow(
          'dumbbell_lateral_raise',
          'Dumbbell Lateral Raise',
          muscle: 'Shoulders',
          equipment: ['dumbbell'],
        ),
        reps: '15',
        rest: 45,
      ),
      planExerciseRow(
        5,
        exerciseRow(
          'dumbbell_overhead_triceps_extension',
          'Overhead Triceps Extension',
          muscle: 'Triceps',
          equipment: ['dumbbell'],
        ),
        reps: '12',
      ),
      planExerciseRow(
        6,
        exerciseRow('diamond_push_up', 'Diamond Push-up', muscle: 'Triceps'),
        sets: 2,
      ),
    ],
  ),
  planDayRow(
    dayNumber: 3,
    weekday: 4,
    title: 'Legs & Core',
    focus: 'core',
    minutes: 40,
    exercises: [
      planExerciseRow(
        1,
        exerciseRow(
          'bulgarian_split_squat',
          'Bulgarian Split Squat',
          focus: 'lower',
          muscle: 'Quads',
          equipment: ['bench'],
        ),
        rest: 90,
      ),
      planExerciseRow(
        2,
        exerciseRow('plank', 'Plank', focus: 'core', muscle: 'Core'),
        reps: '30-45s',
        rest: 45,
      ),
      planExerciseRow(
        3,
        exerciseRow('dead_bug', 'Dead Bug', focus: 'core', muscle: 'Core'),
        reps: '12',
        rest: 45,
      ),
      planExerciseRow(
        4,
        exerciseRow(
          'dumbbell_russian_twist',
          'Dumbbell Russian Twist',
          focus: 'core',
          muscle: 'Core',
          equipment: ['dumbbell'],
        ),
        reps: '20',
        rest: 45,
      ),
      planExerciseRow(
        5,
        exerciseRow('side_plank', 'Side Plank', focus: 'core', muscle: 'Core'),
        reps: '30s',
        rest: 45,
      ),
    ],
  ),
  planDayRow(
    dayNumber: 4,
    weekday: 6,
    title: 'Full Body Burn',
    focus: 'full_body',
    minutes: 45,
    exercises: [
      planExerciseRow(
        1,
        exerciseRow(
          'dumbbell_thruster',
          'Dumbbell Thruster',
          focus: 'full_body',
          muscle: 'Full body',
          equipment: ['dumbbell'],
        ),
        sets: 4,
        rest: 90,
      ),
      planExerciseRow(
        2,
        exerciseRow(
          'renegade_row',
          'Renegade Row',
          focus: 'full_body',
          muscle: 'Full body',
          equipment: ['dumbbell'],
        ),
        reps: '8',
        rest: 90,
      ),
      planExerciseRow(
        3,
        exerciseRow(
          'burpee',
          'Burpee',
          focus: 'full_body',
          muscle: 'Full body',
        ),
        reps: '12',
      ),
      planExerciseRow(
        4,
        exerciseRow(
          'mountain_climber',
          'Mountain Climber',
          focus: 'full_body',
          muscle: 'Full body',
        ),
        reps: '30s',
        rest: 45,
      ),
      planExerciseRow(
        5,
        exerciseRow(
          'dumbbell_row',
          'One-arm Dumbbell Row',
          muscle: 'Back',
          equipment: ['dumbbell'],
        ),
      ),
      planExerciseRow(
        6,
        exerciseRow(
          'jumping_jack',
          'Jumping Jack',
          focus: 'full_body',
          muscle: 'Full body',
        ),
        reps: '30s',
        rest: 30,
      ),
    ],
  ),
];

Map<String, dynamic> workoutPlanRow({
  int version = 1,
  String? instruction,
  String aiModel = 'gemini_flash',
  List<Map<String, dynamic>>? days,
}) => {
  'id': 'plan-$version',
  'user_id': 'user-1',
  'version': version,
  'title': '4-Day Upper / Lower',
  'goal': 'build_muscle',
  'level': 'intermediate',
  'days_per_week': 4,
  'ai_model': aiModel,
  'instruction': instruction,
  'archived_at': null,
  'created_at': '2026-10-13T08:00:00+00:00',
  'plan_days': days ?? sampleDayRows(),
};

WorkoutPlan samplePlan({
  int version = 1,
  String? instruction,
  String aiModel = 'gemini_flash',
}) => WorkoutPlan.fromJson(
  workoutPlanRow(version: version, instruction: instruction, aiModel: aiModel),
);
