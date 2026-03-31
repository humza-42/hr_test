import 'package:flutter/material.dart';

class AttendanceHelpers {
  static IconData getBreakTypeIcon(String? name) {
    if (name == null) return Icons.help_outline;

    final lowerName = name.toLowerCase();
    if (lowerName.contains('meeting')) return Icons.people;
    if (lowerName.contains('official') || lowerName.contains('duty'))
      return Icons.business;
    if (lowerName.contains('prayer')) return Icons.favorite;
    if (lowerName.contains('restroom')) return Icons.wc;
    if (lowerName.contains('cleaning')) return Icons.cleaning_services;
    if (lowerName.contains('maintenance')) return Icons.build;
    if (lowerName.contains('sanitization') ||
        lowerName.contains('sanitisation'))
      return Icons.star_outline;
    if (lowerName.contains('equipment') || lowerName.contains('setup'))
      return Icons.settings;
    if (lowerName.contains('inventory')) return Icons.inventory_2;
    if (lowerName.contains('inspection') || lowerName.contains('area'))
      return Icons.remove_red_eye;
    if (lowerName.contains('documentation') || lowerName.contains('document'))
      return Icons.description;
    if (lowerName.contains('training')) return Icons.school;
    if (lowerName.contains('briefing') || lowerName.contains('team'))
      return Icons.groups;
    if (lowerName.contains('extra')) return Icons.add;
    if (lowerName.contains('lunch')) return Icons.restaurant;

    return Icons.help_outline;
  }

  static String formatTime12Hour(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }
}
