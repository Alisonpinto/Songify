import 'package:flutter/material.dart';

class ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final void Function()? onPressed;

  const ActionPill({super.key, required this.icon, required this.label, required this.color, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: color.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: Colors.white),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
