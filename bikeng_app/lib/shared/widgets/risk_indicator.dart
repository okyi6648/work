import 'package:flutter/material.dart';
import '../../app/theme.dart';

class RiskIndicator extends StatelessWidget {
  final double riskScore;
  final String riskLevel;
  final double size;

  const RiskIndicator({
    super.key,
    required this.riskScore,
    required this.riskLevel,
    this.size = 80,
  });

  Color get _color => AppColors.riskColor(riskLevel);

  String get _levelText {
    switch (riskLevel.toLowerCase()) {
      case 'safe':
        return '安全';
      case 'low':
        return '低风险';
      case 'medium':
        return '中风险';
      case 'high':
        return '高风险';
      default:
        return '未知';
    }
  }

  IconData get _icon {
    switch (riskLevel.toLowerCase()) {
      case 'safe':
        return Icons.check_circle;
      case 'low':
        return Icons.info;
      case 'medium':
        return Icons.warning;
      case 'high':
        return Icons.dangerous;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: riskScore / 100,
                  strokeWidth: 6,
                  backgroundColor: _color.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(_color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_icon, color: _color, size: size * 0.3),
                  Text(
                    '${riskScore.toInt()}',
                    style: TextStyle(
                      fontSize: size * 0.2,
                      fontWeight: FontWeight.bold,
                      color: _color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _color.withOpacity(0.3)),
          ),
          child: Text(
            _levelText,
            style: TextStyle(
              color: _color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
