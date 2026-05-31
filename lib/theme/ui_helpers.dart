import 'package:flutter/material.dart';

class Ui {
  Ui._();


  static Widget gap(double height) => SizedBox(height: height);
  static Widget gapW(double width) => SizedBox(width: width);


  /// Vertical spacing
  static const gap4 = SizedBox(height: 4);
  static const gap8 = SizedBox(height: 8);
  static const gap12 = SizedBox(height: 12);
  static const gap16 = SizedBox(height: 16);
  static const gap20 = SizedBox(height: 20);
  static const gap24 = SizedBox(height: 24);

  /// Horizontal spacing
  static const gapW4 = SizedBox(width: 4);
  static const gapW8 = SizedBox(width: 8);
  static const gapW12 = SizedBox(width: 12);
  static const gapW16 = SizedBox(width: 16);

  /// Padding
  static const p4 = EdgeInsets.all(4);
  static const p8 = EdgeInsets.all(8);
  static const p12 = EdgeInsets.all(12);
  static const p16 = EdgeInsets.all(16);
  static const p20 = EdgeInsets.all(20);

  /// Symmetric Padding
  static const px8 = EdgeInsets.symmetric(horizontal: 8);
  static const px16 = EdgeInsets.symmetric(horizontal: 16);

  static const py8 = EdgeInsets.symmetric(vertical: 8);
  static const py16 = EdgeInsets.symmetric(vertical: 16);

  /// Border Radius
  static const r4 = BorderRadius.all(Radius.circular(4));
  static const r8 = BorderRadius.all(Radius.circular(8));
  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r16 = BorderRadius.all(Radius.circular(16));

  /// Durations
  static const fast = Duration(milliseconds: 200);
  static const normal = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 500);



  /// Divider
  static const divider = Divider(height: 1);

  /// Expanded
  static const expanded = Expanded(child: SizedBox());

  /// Spacer
  static const spacer = Spacer();

}