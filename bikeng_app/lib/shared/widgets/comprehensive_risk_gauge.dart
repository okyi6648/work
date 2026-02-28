import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../app/theme.dart';

class ComprehensiveRiskGauge extends StatelessWidget {
  final double score;
  final double confidence;
  final double size;

  const ComprehensiveRiskGauge({
    super.key,
    required this.score,
    required this.confidence,
    this.size = 200,
  });

  Color get _scoreColor {
    if (score >= 70) return AppColors.riskHigh;
    if (score >= 40) return AppColors.riskMedium;
    if (score >= 20) return AppColors.riskLow;
    return AppColors.riskSafe;
  }

  String get _riskLabel {
    if (score >= 70) return '高风险';
    if (score >= 40) return '中风险';
    if (score >= 20) return '低风险';
    return '安全';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RiskGaugePainter(
              score: score,
              color: _scoreColor,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${score.toInt()}',
                    style: TextStyle(
                      fontSize: size * 0.22,
                      fontWeight: FontWeight.bold,
                      color: _scoreColor,
                    ),
                  ),
                  Text(
                    _riskLabel,
                    style: TextStyle(
                      fontSize: size * 0.08,
                      fontWeight: FontWeight.w600,
                      color: _scoreColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '置信度: ${confidence.toInt()}%',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _RiskGaugePainter extends CustomPainter {
  final double score;
  final Color color;

  _RiskGaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;

    // Background arc.
    final bgPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      bgPaint,
    );

    // Score arc.
    final scorePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (score / 100) * math.pi * 1.5;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      sweepAngle,
      false,
      scorePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RiskGaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}
