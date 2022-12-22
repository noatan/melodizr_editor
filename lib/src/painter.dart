import 'package:flutter/material.dart';

class HoverLinePainter extends CustomPainter {
  final bool _fill;
  final Rect? _rect;
  final Paint _paint;

  HoverLinePainter({
    @required color,
    @required rects,
    bool fill = true,
  })  : _rect = rects,
        _fill = fill,
        _paint = Paint()
          ..color = color
          ..strokeWidth = 2;

  @override
  void paint(Canvas canvas, Size size) {
    if (_rect == null) {
      return;
    }
    _paint.style = _fill ? PaintingStyle.fill : PaintingStyle.stroke;
    canvas.drawLine(_rect!.bottomLeft, _rect!.bottomRight, _paint);
  }

  @override
  bool shouldRepaint(HoverLinePainter oldDelegate) {
    return true;
  }
}
