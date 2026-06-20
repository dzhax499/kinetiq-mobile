import 'package:flutter/material.dart';
import '../models/pcd_filter.dart';
import '../utils/constants.dart';

class FilterButton extends StatefulWidget {
  final PCDFilter filter;
  final bool isSelected;
  final bool isDisabled;
  final int? orderNumber;
  final VoidCallback? onTap;

  const FilterButton({
    super.key,
    required this.filter,
    this.isSelected = false,
    this.isDisabled = false,
    this.orderNumber,
    this.onTap,
  });

  @override
  State<FilterButton> createState() => _FilterButtonState();
}

class _FilterButtonState extends State<FilterButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
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
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        if (!widget.isDisabled) {
          widget.onTap?.call();
        }
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          height: AppSizes.filterButtonHeight,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingMd,
            vertical: AppSizes.paddingSm,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.filter.color.withValues(alpha: 0.25)
                : widget.isDisabled
                    ? AppColors.surface.withValues(alpha: 0.3)
                    : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            border: Border.all(
              color: widget.isSelected
                  ? widget.filter.color
                  : widget.isDisabled
                      ? AppColors.cardBorder.withValues(alpha: 0.3)
                      : AppColors.cardBorder,
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.filter.color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.orderNumber != null) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: widget.filter.color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.orderNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                widget.filter.icon,
                color: widget.isDisabled
                    ? AppColors.textMuted
                    : widget.filter.color,
                size: 22,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.filter.name,
                      style: TextStyle(
                        color: widget.isDisabled
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.filter.description,
                      style: TextStyle(
                        color: widget.isDisabled
                            ? AppColors.textMuted.withValues(alpha: 0.5)
                            : AppColors.textSecondary,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (widget.isSelected)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.check_circle,
                    color: widget.filter.color,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
