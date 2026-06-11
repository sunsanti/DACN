import 'package:flutter/material.dart';

/// Icon for a shift type code (morning/afternoon/evening).
IconData shiftIcon(String type) {
  switch (type) {
    case 'morning':
      return Icons.wb_sunny;
    case 'afternoon':
      return Icons.wb_cloudy;
    case 'evening':
      return Icons.nightlight_round;
    default:
      return Icons.schedule;
  }
}
