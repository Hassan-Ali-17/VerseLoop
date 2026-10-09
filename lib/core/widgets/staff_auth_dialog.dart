import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/configuration/app_config.dart';
import '../../app/theme/ember_theme.dart';
import '../../data/providers/app_providers.dart';

class StaffAuthDialog extends ConsumerStatefulWidget {
  const StaffAuthDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const StaffAuthDialog(),
    );
  }

  @override
  ConsumerState<StaffAuthDialog> createState() => _StaffAuthDialogState();
}

class _StaffAuthDialogState extends ConsumerState<StaffAuthDialog> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _obscureText = true;
  String? _errorMessage;

  // Accepted staff authorization passcodes
  static const Set<String> _validPasscodes = {
    '1234',
    'staff',
    'admin',
    'staff123',
    'loopserve',
    'loopverse',
  };

  @override
  void initState() {
    super.initState();
    // Auto focus the input field on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _verifyAndProceed() {
    final input = _pinController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter staff passcode or PIN.';
      });
      return;
    }

    if (_validPasscodes.contains(input.toLowerCase())) {
      // Authentication successful
      ref.read(userRoleProvider.notifier).setRole(UserRole.staff);
      Navigator.of(context).pop(true);
      context.go('/staff/dashboard');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: EmberColors.surfaceElevated,
          content: Text(
            '✓ Staff authentication verified. Welcome to Operations Dashboard.',
            style: TextStyle(color: EmberColors.primary, fontWeight: FontWeight.bold),
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'Incorrect passcode. Access denied. (Hint: Default PIN is 1234)';
        _pinController.clear();
      });
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: EmberColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: EmberColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Security Badge Icon Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: EmberColors.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: EmberColors.primary.withOpacity(0.4)),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: EmberColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Staff Security Gate',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: EmberColors.textMain,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Authentication required for kitchen operations',
                          style: TextStyle(
                            fontSize: 12,
                            color: EmberColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: EmberColors.textMuted, size: 20),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(color: EmberColors.border, height: 1),
              const SizedBox(height: 24),

              const Text(
                'Enter Staff Passcode / PIN',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: EmberColors.textMain,
                ),
              ),
              const SizedBox(height: 10),

              // PIN / Password Input
              TextField(
                controller: _pinController,
                focusNode: _focusNode,
                obscureText: _obscureText,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _verifyAndProceed(),
                style: const TextStyle(fontSize: 18, letterSpacing: 2, color: EmberColors.textMain),
                decoration: InputDecoration(
                  hintText: 'Enter 1234',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    letterSpacing: 0,
                    color: EmberColors.textMuted.withOpacity(0.6),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline, color: EmberColors.primary, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: EmberColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  ),
                  filled: true,
                  fillColor: EmberColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: EmberColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: _errorMessage != null ? EmberColors.error : EmberColors.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: _errorMessage != null ? EmberColors.error : EmberColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              // Error Message
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.error_outline, size: 14, color: EmberColors.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: EmberColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Quick Hint Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: EmberColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: EmberColors.border.withOpacity(0.6)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: EmberColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Default Staff PIN: 1234 (or "staff")',
                        style: TextStyle(
                          fontSize: 12,
                          color: EmberColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: EmberColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: EmberColors.textMuted, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EmberColors.primary,
                        foregroundColor: EmberColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text(
                        'Verify & Enter',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _verifyAndProceed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
