import 'package:flutter/material.dart';
import 'theme.dart';

class SkillCard extends StatelessWidget {
  final String skillName;
  final String instructor;
  final String time;
  final String rating;
  final List<String>? exchangeFor;
  final dynamic price;
  final VoidCallback? onTap;

  const SkillCard({
    Key? key,
    required this.skillName,
    required this.instructor,
    required this.time,
    required this.rating,
    required this.exchangeFor,
    required this.price,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Exchange chips
    final bool showExchange = (exchangeFor != null && exchangeFor!.isNotEmpty);
    final List<Widget> exchangeChips = showExchange
        ? exchangeFor!
        .map((skill) => Container(
      margin: const EdgeInsets.only(right: 6, bottom: 2),
      child: Chip(
        label: Text(
          skill,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        backgroundColor: AppColors.primary.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      ),
    ))
        .toList()
        : [];

    // Show price if not null/empty/<=0
    final bool showPrice = price != null && (price is num && price > 0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      splashColor: AppColors.primary.withOpacity(0.08),
      highlightColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row with price badge (show only if price available)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      skillName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showPrice)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.09),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Rs ${price.toString()}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  const Icon(Icons.person, color: AppColors.primary, size: 18),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      instructor,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, size: 16, color: AppColors.primary),
                        const SizedBox(width: 5),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.17),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 5),
                        Text(
                          rating,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.amber,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (showExchange) ...[
                const SizedBox(height: 14),
                Text(
                  "Wants to Learn:",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary.withOpacity(0.85),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  children: exchangeChips,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}