import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Pixel-perfect vector icons matching the MI Notes visual language.
class MiIcons {
  MiIcons._();

  /// Notes tab icon (rounded squircle with folded page bookmark notch)
  static Widget notesTab({required bool isSelected, double size = 26}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: isSelected ? null : Border.all(color: AppColors.iconSecondary, width: 1.8),
      ),
      child: CustomPaint(
        painter: _NotesTabPainter(isSelected: isSelected),
      ),
    );
  }

  /// Tasks tab icon (rounded squircle with checkmark)
  static Widget tasksTab({required bool isSelected, double size = 26}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: isSelected ? null : Border.all(color: AppColors.iconSecondary, width: 1.8),
      ),
      child: Center(
        child: Icon(
          Icons.check_rounded,
          size: size * 0.68,
          color: isSelected ? Colors.black : AppColors.iconSecondary,
        ),
      ),
    );
  }

  /// Settings Hexagon Nut / Gear icon
  static Widget settingsHexagon({double size = 24, Color color = AppColors.iconSecondary}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HexagonSettingsPainter(color: color),
      ),
    );
  }

  /// Folder outline icon for filter chips
  static Widget folder({double size = 18, Color color = AppColors.accent}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FolderPainter(color: color),
      ),
    );
  }

  /// Pin / Star icon on cards
  static Widget pinStar({double size = 14, Color color = AppColors.accent}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PinStarPainter(color: color),
      ),
    );
  }

  /// Vault key / lock icon on password cards
  static Widget vaultKey({double size = 14, Color color = AppColors.accent}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _VaultKeyPainter(color: color),
      ),
    );
  }

  /// Empty notes illustration (stacked note papers with pencil)
  static Widget emptyNotesGraphic({double size = 80}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _EmptyNotesPainter(),
      ),
    );
  }

  /// Empty tasks illustration (stacked checklists)
  static Widget emptyTasksGraphic({double size = 80}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _EmptyTasksPainter(),
      ),
    );
  }

  /// Shirt / Theme icon in note detail header
  static Widget shirtTheme({double size = 22, Color color = AppColors.iconPrimary}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ShirtThemePainter(color: color),
      ),
    );
  }

  /// Share tray icon with arrow
  static Widget shareTray({double size = 22, Color color = AppColors.iconPrimary}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ShareTrayPainter(color: color),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PAINTERS
// ---------------------------------------------------------------------------

class _NotesTabPainter extends CustomPainter {
  final bool isSelected;
  _NotesTabPainter({required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isSelected ? Colors.black : AppColors.iconSecondary
      ..style = PaintingStyle.fill;

    // A clean central notch/folded bookmark shape inside the rounded square
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w * 0.38, h * 0.28)
      ..lineTo(w * 0.62, h * 0.28)
      ..lineTo(w * 0.62, h * 0.68)
      ..lineTo(w * 0.50, h * 0.56)
      ..lineTo(w * 0.38, h * 0.68)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _NotesTabPainter oldDelegate) =>
      oldDelegate.isSelected != isSelected;
}

class _HexagonSettingsPainter extends CustomPainter {
  final Color color;
  _HexagonSettingsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.44;

    // Hexagon vertices
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, strokePaint);

    // Inner circle
    canvas.drawCircle(Offset(cx, cy), r * 0.35, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _HexagonSettingsPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _FolderPainter extends CustomPainter {
  final Color color;
  _FolderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Folder outline
    final path = Path()
      ..moveTo(w * 0.15, h * 0.35)
      ..lineTo(w * 0.40, h * 0.35)
      ..lineTo(w * 0.50, h * 0.45)
      ..lineTo(w * 0.85, h * 0.45)
      ..arcToPoint(Offset(w * 0.90, h * 0.50), radius: const Radius.circular(2))
      ..lineTo(w * 0.90, h * 0.80)
      ..arcToPoint(Offset(w * 0.85, h * 0.85), radius: const Radius.circular(2))
      ..lineTo(w * 0.15, h * 0.85)
      ..arcToPoint(Offset(w * 0.10, h * 0.80), radius: const Radius.circular(2))
      ..lineTo(w * 0.10, h * 0.40)
      ..arcToPoint(Offset(w * 0.15, h * 0.35), radius: const Radius.circular(2))
      ..close();

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _FolderPainter oldDelegate) => oldDelegate.color != color;
}

class _PinStarPainter extends CustomPainter {
  final Color color;
  _PinStarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width * 0.48;
    final innerR = outerR * 0.45;

    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = (i * 36 - 90) * math.pi / 180;
      final r = i.isEven ? outerR : innerR;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinStarPainter oldDelegate) => oldDelegate.color != color;
}

class _VaultKeyPainter extends CustomPainter {
  final Color color;
  _VaultKeyPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final cx = size.width * 0.35;
    final cy = size.height * 0.5;
    final r = size.width * 0.22;

    // Key ring
    canvas.drawCircle(Offset(cx, cy), r, strokePaint);

    // Key shaft
    canvas.drawLine(Offset(cx + r, cy), Offset(size.width * 0.88, cy), strokePaint);

    // Key teeth
    canvas.drawLine(
      Offset(size.width * 0.72, cy),
      Offset(size.width * 0.72, cy + size.height * 0.2),
      strokePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.88, cy),
      Offset(size.width * 0.88, cy + size.height * 0.2),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _VaultKeyPainter oldDelegate) => oldDelegate.color != color;
}

class _EmptyNotesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Back card
    final backPaint = Paint()..color = const Color(0xFF1E1E1E);
    final backRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.14, w * 0.60, h * 0.70),
      const Radius.circular(12),
    );
    canvas.drawRRect(backRRect, backPaint);

    // Front card
    final frontPaint = Paint()..color = const Color(0xFF282828);
    final frontRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.24, h * 0.22, w * 0.60, h * 0.70),
      const Radius.circular(12),
    );
    canvas.drawRRect(frontRRect, frontPaint);

    // Horizontal lines on front card
    final linePaint = Paint()
      ..color = const Color(0xFF3E3E3E)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(w * 0.35, h * 0.40), Offset(w * 0.65, h * 0.40), linePaint);
    canvas.drawLine(Offset(w * 0.35, h * 0.50), Offset(w * 0.70, h * 0.50), linePaint);
    canvas.drawLine(Offset(w * 0.35, h * 0.60), Offset(w * 0.55, h * 0.60), linePaint);

    // Pencil overlay
    final pencilPaint = Paint()
      ..color = const Color(0xFF484848)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(w * 0.78, h * 0.42), Offset(w * 0.58, h * 0.68), pencilPaint);
  }

  @override
  bool shouldRepaint(covariant _EmptyNotesPainter oldDelegate) => false;
}

class _EmptyTasksPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Back card
    final backPaint = Paint()..color = const Color(0xFF1E1E1E);
    final backRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.14, w * 0.60, h * 0.70),
      const Radius.circular(12),
    );
    canvas.drawRRect(backRRect, backPaint);

    // Front card
    final frontPaint = Paint()..color = const Color(0xFF282828);
    final frontRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.24, h * 0.22, w * 0.60, h * 0.70),
      const Radius.circular(12),
    );
    canvas.drawRRect(frontRRect, frontPaint);

    // Checkmarks and lines
    final checkPaint = Paint()
      ..color = const Color(0xFF4A4A4A)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePaint = Paint()
      ..color = const Color(0xFF3E3E3E)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // Task 1 check
    final p1 = Path()
      ..moveTo(w * 0.35, h * 0.42)
      ..lineTo(w * 0.40, h * 0.47)
      ..lineTo(w * 0.48, h * 0.38);
    canvas.drawPath(p1, checkPaint);
    canvas.drawLine(Offset(w * 0.55, h * 0.43), Offset(w * 0.72, h * 0.43), linePaint);

    // Task 2 check
    final p2 = Path()
      ..moveTo(w * 0.35, h * 0.58)
      ..lineTo(w * 0.40, h * 0.63)
      ..lineTo(w * 0.48, h * 0.54);
    canvas.drawPath(p2, checkPaint);
    canvas.drawLine(Offset(w * 0.55, h * 0.59), Offset(w * 0.72, h * 0.59), linePaint);
  }

  @override
  bool shouldRepaint(covariant _EmptyTasksPainter oldDelegate) => false;
}

class _ShirtThemePainter extends CustomPainter {
  final Color color;
  _ShirtThemePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w * 0.35, h * 0.25)
      ..lineTo(w * 0.20, h * 0.35)
      ..lineTo(w * 0.28, h * 0.50)
      ..lineTo(w * 0.33, h * 0.45)
      ..lineTo(w * 0.33, h * 0.85)
      ..lineTo(w * 0.67, h * 0.85)
      ..lineTo(w * 0.67, h * 0.45)
      ..lineTo(w * 0.72, h * 0.50)
      ..lineTo(w * 0.80, h * 0.35)
      ..lineTo(w * 0.65, h * 0.25)
      ..quadraticBezierTo(w * 0.50, h * 0.35, w * 0.35, h * 0.25)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ShirtThemePainter oldDelegate) => oldDelegate.color != color;
}

class _ShareTrayPainter extends CustomPainter {
  final Color color;
  _ShareTrayPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Tray box
    final boxPath = Path()
      ..moveTo(w * 0.25, h * 0.45)
      ..lineTo(w * 0.25, h * 0.80)
      ..lineTo(w * 0.75, h * 0.80)
      ..lineTo(w * 0.75, h * 0.45);
    canvas.drawPath(boxPath, strokePaint);

    // Up arrow
    canvas.drawLine(Offset(w * 0.50, h * 0.20), Offset(w * 0.50, h * 0.62), strokePaint);
    final arrowHead = Path()
      ..moveTo(w * 0.35, h * 0.35)
      ..lineTo(w * 0.50, h * 0.20)
      ..lineTo(w * 0.65, h * 0.35);
    canvas.drawPath(arrowHead, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _ShareTrayPainter oldDelegate) => oldDelegate.color != color;
}
