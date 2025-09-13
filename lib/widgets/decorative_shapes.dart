import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/app_colors.dart';

class DecorativeShapes extends StatelessWidget {
  final ShapeType type;
  final double size;
  final Color color;
  
  const DecorativeShapes({
    super.key,
    required this.type,
    this.size = 40,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    switch (type) {
      case ShapeType.star:
        return CustomPaint(
          size: Size(size, size),
          painter: StarPainter(color: color),
        );
      case ShapeType.burst:
        return CustomPaint(
          size: Size(size, size),
          painter: BurstPainter(color: color),
        );
      case ShapeType.diamond:
        return Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      case ShapeType.circle:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        );
      case ShapeType.fourPointStar:
        return CustomPaint(
          size: Size(size, size),
          painter: FourPointStarPainter(color: color),
        );
      case ShapeType.flower:
        return CustomPaint(
          size: Size(size, size),
          painter: FlowerPainter(color: color),
        );
      case ShapeType.sparkle:
        return CustomPaint(
          size: Size(size, size),
          painter: SparklePainter(color: color),
        );
    }
  }
}

enum ShapeType {
  star,
  burst,
  diamond,
  circle,
  fourPointStar,
  flower,
  sparkle,
}

class StarPainter extends CustomPainter {
  final Color color;
  
  StarPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final innerRadius = radius * 0.4;
    
    for (int i = 0; i < 10; i++) {
      final angle = (i * math.pi / 5) - math.pi / 2;
      final r = i.isEven ? radius : innerRadius;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BurstPainter extends CustomPainter {
  final Color color;
  
  BurstPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final innerRadius = radius * 0.5;
    
    for (int i = 0; i < 16; i++) {
      final angle = (i * math.pi / 8) - math.pi / 2;
      final r = i.isEven ? radius : innerRadius;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FourPointStarPainter extends CustomPainter {
  final Color color;
  
  FourPointStarPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    path.moveTo(center.dx, center.dy - radius);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + radius, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + radius);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - radius);
    
    path.close();
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FlowerPainter extends CustomPainter {
  final Color color;
  
  FlowerPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final center = Offset(size.width / 2, size.height / 2);
    final petalRadius = size.width / 4;
    
    // Draw petals
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3);
      final x = center.dx + petalRadius * math.cos(angle);
      final y = center.dy + petalRadius * math.sin(angle);
      canvas.drawCircle(Offset(x, y), petalRadius * 0.6, paint);
    }
    
    // Draw center
    final centerPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, petalRadius * 0.5, centerPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SparklePainter extends CustomPainter {
  final Color color;
  
  SparklePainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw lines
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4);
      final startX = center.dx + (radius * 0.3) * math.cos(angle);
      final startY = center.dy + (radius * 0.3) * math.sin(angle);
      final endX = center.dx + radius * math.cos(angle);
      final endY = center.dy + radius * math.sin(angle);
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint..style = PaintingStyle.stroke,
      );
    }
    
    // Draw center dot
    canvas.drawCircle(center, radius * 0.15, paint..style = PaintingStyle.fill);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Utility widget to scatter random shapes
class RandomShapesBackground extends StatelessWidget {
  final int shapeCount;
  final List<Color> colors;
  
  const RandomShapesBackground({
    super.key,
    this.shapeCount = 5,
    this.colors = const [
      AppColors.secondary,
      AppColors.tertiary,
      AppColors.accent2,
    ],
  });
  
  @override
  Widget build(BuildContext context) {
    final random = math.Random();
    final shapes = ShapeType.values;
    
    return Stack(
      children: List.generate(shapeCount, (index) {
        final shape = shapes[random.nextInt(shapes.length)];
        final color = colors[random.nextInt(colors.length)].withOpacity(0.3);
        final size = 30.0 + random.nextInt(40);
        
        return Positioned(
          top: random.nextDouble() * 200,
          left: random.nextDouble() * MediaQuery.of(context).size.width,
          child: DecorativeShapes(
            type: shape,
            color: color,
            size: size,
          ),
        );
      }),
    );
  }
}