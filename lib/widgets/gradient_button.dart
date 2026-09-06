import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Gradient, animated-press call-to-action button used on the login
/// and signup forms (and anywhere else that wants the same look).
class GradientButton extends StatefulWidget {
  final bool loading;
  final String label;
  final VoidCallback onPressed;

  const GradientButton({
    super.key,
    required this.loading,
    required this.label,
    required this.onPressed,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.loading ? null : (_) => setState(() => _scale = 0.97),
      onTapUp: widget.loading ? null : (_) => setState(() => _scale = 1),
      onTapCancel: widget.loading ? null : () => setState(() => _scale = 1),
      onTap: widget.loading ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 52,
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: widget.loading
                  ? [Colors.grey.shade600, Colors.grey.shade500]
                  : const [AppColors.tealLight, AppColors.purple],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: widget.loading
                ? []
                : [
                    BoxShadow(
                      color: AppColors.tealLight.withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: widget.loading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}
