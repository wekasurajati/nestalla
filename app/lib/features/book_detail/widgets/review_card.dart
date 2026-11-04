import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../models/book_review.dart';
import 'rating_stars.dart';

class ReviewCard extends StatelessWidget {
  final BookReview review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final avatarImage = _avatarImage();

    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.border,
        border: Border.all(color: AppColors.grey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.lightBlue,
                backgroundImage: avatarImage,
                child: avatarImage == null
                    ? const Icon(Icons.person, size: 18, color: AppColors.navy)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  review.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RatingStars(rating: review.rating, size: 13),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              review.comment,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.dark),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? _avatarImage() {
    if (review.avatarUrl.startsWith('http')) {
      return NetworkImage(review.avatarUrl);
    }
    if (review.avatarUrl.isNotEmpty) {
      return AssetImage(review.avatarUrl);
    }
    return null;
  }
}
