import 'package:flutter/material.dart';

class GameColors {
  static const Color firstColor = Color(0xFFF8961E);
  static const Color secondColor = Color(0xFFF4A261);
  static const Color thirdColor = Color(0xFFE76F51);
  static const Color fourthColor = Color(0xFFE9C46A);
  static const Color fifthColor = Color(0xFF2A9D8F);
}

class GameCellShape {
  static BoxShape firstShape = BoxShape.circle;
  static BoxShape secondShape = BoxShape.rectangle;
}

class GameCell extends StatelessWidget {
  final String cellText;
  final Color color;
  bool isSelected;
  final BoxShape shape;
  GameCell({
    super.key,
    this.isSelected = false,
    required this.cellText,
    required this.color,
    required this.shape,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      decoration: BoxDecoration(
          color: color.withOpacity((isSelected) ? 0.5 : 1), shape: shape),
      child: Center(
        child: Text(cellText),
      ),
    );
  }
}

List<String> files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
Map<String, int> points = {
  "A": 1,
  "B": 3,
  "C": 4,
  "Ç": 4,
  "D": 3,
  "E": 1,
  "F": 7,
  "G": 5,
  "Ğ": 8,
  "H": 5,
  "I": 2,
  "İ": 1,
  "J": 10,
  "K": 1,
  "L": 1,
  "M": 2,
  "N": 1,
  "O": 2,
  "Ö": 7,
  "P": 5,
  "R": 1,
  "S": 2,
  "Ş": 4,
  "T": 1,
  "U": 2,
  "Ü": 3,
  "V": 7,
  "Y": 3,
  "Z": 4
};
