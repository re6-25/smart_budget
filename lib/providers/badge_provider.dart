import 'package:flutter/material.dart';
import '../models/badge.dart' as badge_model;

class BadgeProvider extends ChangeNotifier {
  bool _disposed = false;

  List<badge_model.Badge> _earnedBadges = [];
  int _consecutiveDaysUnderBudget = 0;

  List<badge_model.Badge> get earnedBadges => _earnedBadges;
  int get streak => _consecutiveDaysUnderBudget;

  List<badge_model.Badge> get allBadgesWithStatus {
    return badge_model.allBadges.map((badge) {
      final earned = _earnedBadges.firstWhere(
        (e) => e.id == badge.id,
        orElse: () => badge,
      );
      return earned;
    }).toList();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Safe wrapper — never calls notifyListeners after dispose.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  void checkBadges({
    required double dailyTotal,
    required double dailyLimit,
    required int totalExpenses,
  }) {
    if (_disposed) return;

    // First expense badge
    if (totalExpenses == 1) {
      _awardBadge('first_expense');
    }

    // Consecutive days under budget
    if (dailyTotal <= dailyLimit && dailyLimit > 0) {
      _consecutiveDaysUnderBudget++;
    } else {
      _consecutiveDaysUnderBudget = 0;
    }

    if (_consecutiveDaysUnderBudget >= 7) {
      _awardBadge('financial_guardian');
    }

    // Week saver: stayed under 50% for a week
    if (_consecutiveDaysUnderBudget >= 7 && dailyTotal <= dailyLimit * 0.5) {
      _awardBadge('week_saver');
    }

    notifyListeners();
  }

  void _awardBadge(String id) {
    if (_disposed) return;
    final alreadyEarned = _earnedBadges.any((b) => b.id == id);
    if (!alreadyEarned) {
      final badge = badge_model.allBadges.firstWhere((b) => b.id == id);
      _earnedBadges.add(badge_model.Badge(
        id: badge.id,
        title: badge.title,
        description: badge.description,
        iconCode: badge.iconCode,
        earnedDate: DateTime.now(),
      ));
      notifyListeners();
    }
  }
}
