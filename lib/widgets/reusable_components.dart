import 'package:flutter/material.dart';

/// Reusable primary button (teal background, white text).
/// Matches your design's primary action button.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;

  const PrimaryButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.height = 56,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF005F54), // Teal
          disabledBackgroundColor: const Color(0xFFCCCCCC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 4,
          shadowColor: const Color(0xFF005F54).withOpacity(0.3),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

/// Secondary button (outline style).
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const SecondaryButton({
    Key? key,
    required this.label,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF005F54), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF005F54),
          ),
        ),
      ),
    );
  }
}

/// Reusable card container (rounded, shadow, padding).
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color backgroundColor;
  final double borderRadius;
  final Border? border;

  const CustomCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.backgroundColor = Colors.white,
    this.borderRadius = 24,
    this.border,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Slider with label and value display.
/// Shows min/max and current value.
class LabeledSlider extends StatefulWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final Function(double) onChanged;
  final String? suffix; // e.g., "hours" or "cycles"

  const LabeledSlider({
    Key? key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.suffix,
  }) : super(key: key);

  @override
  State<LabeledSlider> createState() => _LabeledSliderState();
}

class _LabeledSliderState extends State<LabeledSlider> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF757575),
              ),
            ),
            Text(
              '${_currentValue.toStringAsFixed(0)} ${widget.suffix ?? ''}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF005F54),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Slider(
          value: _currentValue,
          min: widget.min,
          max: widget.max,
          divisions: (widget.max - widget.min).toInt(),
          onChanged: (value) {
            setState(() {
              _currentValue = value;
            });
            widget.onChanged(value);
          },
          activeColor: const Color(0xFF005F54),
          inactiveColor: const Color(0xFFE0E0E0),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${widget.min.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFFBDBDBD)),
            ),
            Text(
              '${widget.max.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFFBDBDBD)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Toggle button group for age selection (New, Standard, Old, Inverter).
class AgeToggleButtons extends StatefulWidget {
  final String selected;
  final Function(String) onSelected;

  const AgeToggleButtons({
    Key? key,
    required this.selected,
    required this.onSelected,
  }) : super(key: key);

  @override
  State<AgeToggleButtons> createState() => _AgeToggleButtonsState();
}

class _AgeToggleButtonsState extends State<AgeToggleButtons> {
  final List<String> options = ['standard', 'new', 'old', 'inverter'];
  final Map<String, String> labels = {
    'standard': 'Standard',
    'new': 'New',
    'old': 'Old',
    'inverter': 'Inverter',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map(
            (option) => GestureDetector(
              onTap: () => widget.onSelected(option),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: widget.selected == option
                      ? const Color(0xFFE0F2F1)
                      : const Color(0xFFF5F5F5),
                  border: Border.all(
                    color: widget.selected == option
                        ? const Color(0xFF005F54)
                        : const Color(0xFFE0E0E0),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  labels[option]!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.selected == option
                        ? const Color(0xFF005F54)
                        : const Color(0xFF757575),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

/// Bottom navigation bar (3 main screens: Dashboard, What-If, Advisor).
class BottomNav extends StatelessWidget {
  final String currentRoute;
  final Function(String) onNavigate;

  const BottomNav({
    Key? key,
    required this.currentRoute,
    required this.onNavigate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(
            icon: Icons.pie_chart,
            label: 'Dashboard',
            isActive: currentRoute == '/dashboard',
            onTap: () => onNavigate('/dashboard'),
          ),
          _NavItem(
            icon: Icons.science,
            label: 'What-If',
            isActive: currentRoute == '/what-if',
            onTap: () => onNavigate('/what-if'),
          ),
          _NavItem(
            icon: Icons.chat_bubble,
            label: 'Advisor',
            isActive: currentRoute == '/advisor',
            onTap: () => onNavigate('/advisor'),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF005F54) : const Color(0xFFBDBDBD),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive
                  ? const Color(0xFF005F54)
                  : const Color(0xFFBDBDBD),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header bar with back button, title, and optional action button.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final VoidCallback? onBackPressed;
  final Widget? actionWidget;
  final bool showBackButton;

  const CustomAppBar({
    Key? key,
    this.title,
    this.onBackPressed,
    this.actionWidget,
    this.showBackButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.black),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            )
          : null,
      title: title != null
          ? Text(
              title!,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
      centerTitle: true,
      actions: actionWidget != null ? [actionWidget!] : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
