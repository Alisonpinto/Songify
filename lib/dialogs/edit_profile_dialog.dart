import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/validators.dart';

Future<(String name, String handle)> showEditProfileDialog({
  required BuildContext context,
  required String name,
  required String handle,
  Color? color,
}) async {
  (String name, String handle)? result = await showDialog(
    context: context,
    builder: (context) {
      return EditProfileDialog(name: name, handle: handle, color: color);
    },
  );

  return result ?? (name, handle);
}

class EditProfileDialog extends StatefulWidget {
  final String name;
  final String handle;
  final Color? color;

  const EditProfileDialog({super.key, required this.name, required this.handle, this.color});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _handleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initFields();
  }

  @override
  void didUpdateWidget(covariant EditProfileDialog oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.name != widget.name || oldWidget.handle != widget.handle) {
      _initFields();
    }
  }

  void _initFields() {
    if (widget.name != _nameController.text) _nameController.text = widget.name;
    if (widget.handle != _handleController.text) _handleController.text = widget.handle;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    super.dispose();
  }

  void _onCancel(BuildContext context) => Navigator.of(context).pop();

  void _onSave(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final savedName = _nameController.text.trim();
    final savedHandle = normaliseHandle(_handleController.text);
    Navigator.of(context).pop((savedName, savedHandle));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.darkCard,
      title: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: "Name",
                labelStyle: TextStyle(color: AppTheme.textSecondary),
                errorStyle: TextStyle(color: Color(0xFFFF6B6B)),
              ),
              style: const TextStyle(color: AppTheme.textPrimary),
              controller: _nameController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) => validateName(value ?? ''),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: "Handle",
                labelStyle: TextStyle(color: AppTheme.textSecondary),
                hintText: '@yourhandle',
                hintStyle: TextStyle(color: AppTheme.textSecondary),
                errorStyle: TextStyle(color: Color(0xFFFF6B6B)),
                errorMaxLines: 2,
              ),
              style: const TextStyle(color: AppTheme.textPrimary),
              controller: _handleController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) => validateHandle(value ?? ''),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _onCancel(context),
          child: const Text("Cancel", style: TextStyle(color: AppTheme.textSecondary)),
        ),
        TextButton(
          onPressed: () => _onSave(context),
          child: Text("Save", style: TextStyle(color: widget.color)),
        ),
      ],
    );
  }
}
