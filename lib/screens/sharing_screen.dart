import 'dart:async';

import 'package:flutter/material.dart';

import '../services/bump_share_nfc.dart';
import '../widgets/bump_share_logo.dart';

/// Sender-only screen. HCE is armed before this screen opens; it is always
/// disarmed when this screen closes, including via the system back button.
class SharingScreen extends StatefulWidget {
  const SharingScreen({super.key});

  @override
  State<SharingScreen> createState() => _SharingScreenState();
}

class _SharingScreenState extends State<SharingScreen> {
  final BumpShareNfcService _nfc = BumpShareNfcService.instance;
  StreamSubscription<void>? _tapSubscription;

  @override
  void initState() {
    super.initState();
    _tapSubscription = _nfc.onSharingComplete.listen((_) => _onTapped());
  }

  @override
  void dispose() {
    _tapSubscription?.cancel();
    // Cover back-gesture / app-bar back as well as the Cancel button.
    unawaited(_nfc.stopSharing());
    super.dispose();
  }

  Future<void> _onTapped() async {
    await _nfc.stopSharing();
    if (!mounted) return;
    await Navigator.pushReplacementNamed(context, '/success');
  }

  Future<void> _cancel() async {
    await _nfc.stopSharing();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return PopScope<void>(
      canPop: true,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const BumpShareLogo(size: 72),
                  const SizedBox(height: 22),
                  Text(
                    'Ready to share',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Keep this screen open and your phone unlocked.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: <Widget>[
                        _PulseIcon(color: colors.primary),
                        const SizedBox(height: 14),
                        Text(
                          'Waiting for a tap…',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _Step(
                    number: '1',
                    text: 'Hold the back of your phone against theirs.',
                  ),
                  const SizedBox(height: 12),
                  _Step(
                    number: '2',
                    text: 'They tap the link that appears — no app to install.',
                  ),
                  const SizedBox(height: 12),
                  _Step(
                    number: '3',
                    text: 'Keep the phones still for about a second.',
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _cancel,
                      child: const Text('Cancel sharing'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}

class _PulseIcon extends StatelessWidget {
  const _PulseIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.9, end: 1.08),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (BuildContext context, double scale, Widget? child) {
        return Transform.scale(
          scale: scale,
          child: Icon(Icons.nfc, size: 56, color: color),
        );
      },
    );
  }
}
