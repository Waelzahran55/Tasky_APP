import 'package:flutter/material.dart';

enum Priority {
  low('Low', Color(0xFF2E9E5B)),
  medium('Medium', Color(0xFFE08A00)),
  high('High', Color(0xFFD93B3B));

  const Priority(this.label, this.color);

  final String label;
  final Color color;
}
