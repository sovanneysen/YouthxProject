import 'package:flutter_test/flutter_test.dart';
import 'package:youthx/modules/finance/models/saving_goal_model.dart';

void main() {
  group('SavingGoalModel parsing', () {
    test('reads the backend SavingGoalResponse fields', () {
      final goal = SavingGoalModel.fromJson({
        'id': 7,
        'name': 'New laptop',
        'targetAmount': 1500,
        'currentAmount': 300.5,
        'progressPercent': 20,
      });

      expect(goal.id, '7');
      expect(goal.name, 'New laptop');
      expect(goal.targetAmount, 1500.0);
      expect(goal.currentAmount, 300.5);
      expect(goal.progressPercent, 20.0);
    });

    test('falls back to zeroes when optional fields are missing', () {
      final goal = SavingGoalModel.fromJson({'id': 1});

      expect(goal.name, '');
      expect(goal.targetAmount, 0.0);
      expect(goal.currentAmount, 0.0);
      expect(goal.progressPercent, 0.0);
    });

    test('request bodies carry only the fields the backend accepts', () {
      const goal = SavingGoalModel(
        id: '1',
        name: 'Trip',
        targetAmount: 800,
        currentAmount: 0,
        progressPercent: 0,
      );

      expect(goal.toCreateBody(), {'name': 'Trip', 'targetAmount': 800.0});
      expect(goal.toDepositBody(25.5), {'amount': 25.5});
    });
  });

  group('progressFraction stays inside 0.0-1.0', () {
    test('converts the backend percentage to a fraction', () {
      const goal = SavingGoalModel(
        id: '1',
        name: 'Trip',
        targetAmount: 200,
        currentAmount: 50,
        progressPercent: 25,
      );

      expect(goal.progressFraction, 0.25);
    });

    test('clamps an overshot goal to a full bar', () {
      // The backend computes current * 100 / target, so a deposit past the
      // target yields a value above 100, which LinearProgressIndicator rejects.
      const goal = SavingGoalModel(
        id: '1',
        name: 'Trip',
        targetAmount: 200,
        currentAmount: 260,
        progressPercent: 130,
      );

      expect(goal.progressFraction, 1.0);
    });

    test('clamps a negative percentage to zero', () {
      const goal = SavingGoalModel(
        id: '1',
        name: 'Trip',
        targetAmount: 200,
        currentAmount: 0,
        progressPercent: -5,
      );

      expect(goal.progressFraction, 0.0);
    });
  });

  group('remainingAmount', () {
    test('reports the gap to the target', () {
      const goal = SavingGoalModel(
        id: '1',
        name: 'Trip',
        targetAmount: 200,
        currentAmount: 50,
        progressPercent: 25,
      );

      expect(goal.remainingAmount, 150.0);
    });

    test('never goes negative once the goal is met', () {
      const goal = SavingGoalModel(
        id: '1',
        name: 'Trip',
        targetAmount: 200,
        currentAmount: 260,
        progressPercent: 130,
      );

      expect(goal.remainingAmount, 0.0);
    });
  });

  group('isComplete', () {
    test('is false while the target is still outstanding', () {
      const goal = SavingGoalModel(
        id: '1',
        name: 'Trip',
        targetAmount: 200,
        currentAmount: 199.99,
        progressPercent: 99,
      );

      expect(goal.isComplete, isFalse);
    });

    test('is true once the current amount reaches the target', () {
      const goal = SavingGoalModel(
        id: '1',
        name: 'Trip',
        targetAmount: 200,
        currentAmount: 200,
        progressPercent: 100,
      );

      expect(goal.isComplete, isTrue);
    });

    test('is false for a malformed zero target', () {
      const goal = SavingGoalModel(
        id: '1',
        name: 'Trip',
        targetAmount: 0,
        currentAmount: 0,
        progressPercent: 0,
      );

      expect(goal.isComplete, isFalse);
    });
  });

  group('displayName', () {
    test('trims surrounding whitespace', () {
      const goal = SavingGoalModel(
        id: '1',
        name: '  New laptop  ',
        targetAmount: 100,
        currentAmount: 0,
        progressPercent: 0,
      );

      expect(goal.displayName, 'New laptop');
    });

    test('substitutes a label for a blank name', () {
      const goal = SavingGoalModel(
        id: '1',
        name: '   ',
        targetAmount: 100,
        currentAmount: 0,
        progressPercent: 0,
      );

      expect(goal.displayName, 'Untitled goal');
    });
  });
}
