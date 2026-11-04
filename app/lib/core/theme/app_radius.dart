import 'package:flutter/material.dart';

class AppRadius {
  static const double md = 8;
  static const BorderRadius border = BorderRadius.all(Radius.circular(md));
  static const RoundedRectangleBorder shape = RoundedRectangleBorder(
    borderRadius: border,
  );
}
