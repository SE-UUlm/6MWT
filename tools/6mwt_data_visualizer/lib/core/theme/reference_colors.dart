import 'package:flutter/material.dart';

Color referenceColor(int index) => const [
  Color(0xFFFF6D00),
  Color(0xFF66BB6A),
  Color(0xFFEC407A),
  Color(0xFF26C6DA),
  Color(0xFFFFCA28),
  Color(0xFFAB47BC),
][index % 6];
