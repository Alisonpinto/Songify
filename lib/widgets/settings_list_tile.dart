import 'package:flutter/material.dart';
import 'package:songify_flutter/theme.dart';

class SettingsListTile extends StatelessWidget {
  final Widget? icon;
  final Widget title;
  final Widget subtitle;
  final void Function()? onPressed;

  const SettingsListTile({super.key, this.icon, required this.title, required this.subtitle, this.onPressed});

  @override
  Widget build(BuildContext context) {
    Widget? i;
    if (icon != null) {
      i = IconTheme.merge(
        data: IconThemeData(color: AppTheme.textSecondary),
        child: icon!,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        tileColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: i,
        title: DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          child: title,
        ),
        subtitle: DefaultTextStyle.merge(
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          child: subtitle,
        ),
        trailing: Visibility.maintain(
          visible: onPressed != null,
          child: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
        ),
        onTap: onPressed,
      ),
    );
  }
}
