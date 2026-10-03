import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class VaultPinDialog extends StatefulWidget {
  final bool isSettingUp;
  final ValueChanged<String> onPinSubmitted;

  const VaultPinDialog({
    super.key,
    required this.isSettingUp,
    required this.onPinSubmitted,
  });

  @override
  State<VaultPinDialog> createState() => _VaultPinDialogState();
}

class _VaultPinDialogState extends State<VaultPinDialog> {
  final _pinController = TextEditingController();
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.dialogBackground,
      title: Text(
        widget.isSettingUp ? 'Set Vault Master PIN' : 'Unlock Password Vault',
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isSettingUp
                ? 'Create a 4-digit PIN to encrypt and protect sensitive passwords.'
                : 'Enter your 4-digit PIN to decrypt your passwords (default demo PIN: 1234).',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pinController,
            autofocus: true,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 24,
              letterSpacing: 8,
              fontWeight: FontWeight.bold,
            ),
            cursorColor: AppColors.accent,
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••',
              hintStyle: const TextStyle(color: AppColors.textTertiary, letterSpacing: 8),
              errorText: _errorMessage,
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.divider)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent, width: 2)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () {
            final pin = _pinController.text.trim();
            if (pin.length < 4) {
              setState(() => _errorMessage = 'Enter at least 4 digits');
              return;
            }
            widget.onPinSubmitted(pin);
            Navigator.pop(context);
          },
          child: Text(
            widget.isSettingUp ? 'Set PIN' : 'Unlock',
            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
