import 'package:flutter/material.dart';
import '../models/potion.dart';
import '../utils/constants.dart';

class PotionCard extends StatefulWidget {
  final Potion potion;
  final bool isRevealed;
  final bool isCorrectPosition;
  final bool isWrongPosition;
  final bool isDragging;
  final VoidCallback? onTap;
  final double size;

  const PotionCard({
    super.key,
    required this.potion,
    this.isRevealed = true,
    this.isCorrectPosition = false,
    this.isWrongPosition = false,
    this.isDragging = false,
    this.onTap,
    this.size = AppSizes.potionCardSize,
  });

  @override
  State<PotionCard> createState() => _PotionCardState();
}

class _PotionCardState extends State<PotionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final borderColor = widget.isCorrectPosition
            ? AppColors.success
            : widget.isWrongPosition
                ? AppColors.error
                : widget.potion.color;

        return GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            width: widget.size,
            height: widget.size,
            transform: Matrix4.diagonal3Values(
                widget.isDragging ? 1.15 : 1.0, widget.isDragging ? 1.15 : 1.0, 1.0),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.isRevealed
                  ? AppColors.surface
                  : AppColors.bgDarkMid,
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              border: Border.all(
                color: widget.isRevealed
                    ? borderColor.withValues(alpha: 0.8)
                    : AppColors.cardBorder,
                width: widget.isCorrectPosition || widget.isWrongPosition
                    ? 3
                    : 2,
              ),
              boxShadow: widget.isRevealed
                  ? [
                      BoxShadow(
                        color: widget.potion.glowColor
                            .withValues(alpha: _glowAnimation.value * 0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: widget.potion.glowColor.withValues(alpha: 0.1),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: widget.isRevealed ? _buildRevealed() : _buildHidden(),
          ),
        );
      },
    );
  }

  Widget _buildRevealed() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.potion.emoji,
          style: TextStyle(fontSize: widget.size * 0.35),
        ),
        const SizedBox(height: 4),
        Text(
          widget.potion.name,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: widget.size * 0.11,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildHidden() {
    return Center(
      child: Icon(
        Icons.help_outline_rounded,
        color: AppColors.textMuted,
        size: widget.size * 0.35,
      ),
    );
  }
}
