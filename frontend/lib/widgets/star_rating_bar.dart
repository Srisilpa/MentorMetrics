import 'package:flutter/material.dart';

class StarRatingBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int rating;
  final ValueChanged<int> onRatingChanged;
  final bool readOnly;
  final double starSize;

  const StarRatingBar({
    super.key,
    required this.title,
    this.subtitle,
    required this.rating,
    required this.onRatingChanged,
    this.readOnly = false,
    this.starSize = 32.0,
  });

  static String getRatingLabel(int score) {
    switch (score) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Not Rated';
    }
  }

  static Color getRatingColor(int score) {
    switch (score) {
      case 1:
        return Colors.redAccent;
      case 2:
        return Colors.orangeAccent;
      case 3:
        return Colors.amber.shade700;
      case 4:
        return Colors.lightGreen.shade700;
      case 5:
        return const Color(0xFF1B8A5A);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (rating > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: getRatingColor(rating).withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$rating / 5 (${getRatingLabel(rating)})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: getRatingColor(rating),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              final isSelected = starIndex <= rating;

              return InkWell(
                onTap: readOnly ? null : () => onRatingChanged(starIndex),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: starSize,
                    color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
