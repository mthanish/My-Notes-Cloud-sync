import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DrawingPoint {
  final Offset point;
  final Paint paint;

  DrawingPoint({required this.point, required this.paint});
}

class DrawingCanvasModal extends StatefulWidget {
  const DrawingCanvasModal({super.key});

  @override
  State<DrawingCanvasModal> createState() => _DrawingCanvasModalState();
}

class _DrawingCanvasModalState extends State<DrawingCanvasModal> {
  final List<List<DrawingPoint>> _strokes = [];
  List<DrawingPoint> _currentStroke = [];
  Color _selectedColor = AppColors.accent;
  final double _strokeWidth = 3.5;

  final List<Color> _colors = [
    AppColors.accent,
    Colors.white,
    const Color(0xFFFF5252),
    const Color(0xFF448AFF),
    const Color(0xFF69F0AE),
    const Color(0xFFFFD740),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.iconPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Drawing Note', style: TextStyle(fontSize: 18, color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo_rounded, color: AppColors.iconSecondary),
            onPressed: () {
              if (_strokes.isNotEmpty) {
                setState(() => _strokes.removeLast());
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.iconSecondary),
            onPressed: () {
              setState(() => _strokes.clear());
            },
          ),
          IconButton(
            icon: const Icon(Icons.check_rounded, color: AppColors.accent, size: 26),
            onPressed: () {
              Navigator.pop(context, 'Drawing saved (${_strokes.length} strokes)');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Drawing Canvas
          Expanded(
            child: GestureDetector(
              onPanStart: (details) {
                final paint = Paint()
                  ..color = _selectedColor
                  ..strokeCap = StrokeCap.round
                  ..strokeWidth = _strokeWidth
                  ..isAntiAlias = true;

                setState(() {
                  _currentStroke = [DrawingPoint(point: details.localPosition, paint: paint)];
                  _strokes.add(_currentStroke);
                });
              },
              onPanUpdate: (details) {
                final paint = Paint()
                  ..color = _selectedColor
                  ..strokeCap = StrokeCap.round
                  ..strokeWidth = _strokeWidth
                  ..isAntiAlias = true;

                setState(() {
                  _currentStroke.add(DrawingPoint(point: details.localPosition, paint: paint));
                });
              },
              onPanEnd: (_) {
                _currentStroke = [];
              },
              child: CustomPaint(
                painter: _CanvasPainter(strokes: _strokes),
                size: Size.infinite,
              ),
            ),
          ),

          // Brush Color Picker Palette
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            color: AppColors.cardBackground,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _colors.map((c) {
                final isSelected = _selectedColor == c;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2.5)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<List<DrawingPoint>> strokes;

  _CanvasPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      for (int i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i].point, stroke[i + 1].point, stroke[i].paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) => true;
}
