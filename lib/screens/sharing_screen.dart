import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/profile.dart';
import '../services/bump_share_nfc.dart';
import '../services/profile_store.dart';
import '../widgets/bump_share_logo.dart';
class SharingScreen extends StatefulWidget {
  const SharingScreen({
    super.key,
    this.shareUrl,
    this.timeout = const Duration(seconds: 15),
  });
  final String? shareUrl;
  final Duration timeout;
  @override
  State<SharingScreen> createState() => _SharingScreenState();
}
class _SharingScreenState extends State<SharingScreen> {
  final BumpShareNfcService _nfc = BumpShareNfcService.instance;
  StreamSubscription<void>? _tapSubscription;
  Timer? _timer;
  String? _url;
  bool _timedOut = false;
  bool _completed = false;
  @override
  void initState() {
    super.initState();
    _url = widget.shareUrl;
    _tapSubscription = _nfc.onSharingComplete.listen((_) => _onTapped());
    _startTimer();
  }
  @override
  void dispose() {
    _timer?.cancel();
    _tapSubscription?.cancel();
    unawaited(_nfc.stopSharing());
    super.dispose();
  }
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(widget.timeout, _onTimeout);
  }
  Future<void> _safeHaptic(Future<void> Function() feedback) async {
    try {
      await feedback();
    } catch (_) {
    }
  }
  Future<void> _onTapped() async {
    if (_completed) return;
    _completed = true;
    _timer?.cancel();
    _timer = null;
    unawaited(_nfc.stopSharing());
    await ProfileStore.recordShare();
    if (!mounted) return;
    unawaited(_safeHaptic(() => HapticFeedback.mediumImpact()));
    await Navigator.pushReplacementNamed(context, '/success');
  }
  void _onTimeout() {
    if (_completed || !mounted) return;
    _timer = null;
    unawaited(_nfc.stopSharing());
    unawaited(_safeHaptic(() => HapticFeedback.selectionClick()));
    setState(() => _timedOut = true);
  }
  Future<void> _retry() async {
    if (_url == null || _url!.isEmpty) {
      final Profile profile = await ProfileStore.load();
      _url = profile.nfcShareUrl;
    }
    final bool armed = await _nfc.startSharing(_url ?? '');
    if (!mounted) return;
    if (!armed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not restart NFC sharing.')),
      );
      return;
    }
    setState(() => _timedOut = false);
    _startTimer();
  }
  Future<void> _showQr() async {
    final Profile profile = await ProfileStore.load();
    if (!mounted) return;
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Share via QR code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 224,
              height: 224,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: profile.toVCard(includePhoto: false),
                version: QrVersions.auto,
                size: 200,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Scan to save the contact — works without NFC.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  Future<void> _cancel() async {
    _timer?.cancel();
    unawaited(_nfc.stopSharing());
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const BumpShareLogo(size: 72),
                  const SizedBox(height: 22),
                  Text(
                    _timedOut ? 'No tap detected' : 'Ready to share',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _timedOut
                        ? 'The bump did not register. Try again or use the QR code.'
                        : 'Keep this screen open and your phone unlocked.',
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
                      color: _timedOut
                          ? colors.errorContainer
                          : colors.primaryContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: <Widget>[
                        _PulseIcon(
                          color: _timedOut
                              ? colors.onErrorContainer
                              : colors.primary,
                          paused: _timedOut,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _timedOut ? 'Try another bump' : 'Waiting for a tap…',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _timedOut ? colors.onErrorContainer : null,
                          ),
                        ),
                        if (_timedOut) ...<Widget>[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              OutlinedButton.icon(
                                onPressed: _retry,
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Try again'),
                              ),
                              const SizedBox(width: 8),
                              FilledButton.icon(
                                onPressed: _showQr,
                                icon: const Icon(Icons.qr_code_2, size: 18),
                                label: const Text('Use QR code'),
                              ),
                            ],
                          ),
                        ],
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
  const _PulseIcon({required this.color, this.paused = false});
  final Color color;
  final bool paused;
  @override
  Widget build(BuildContext context) {
    if (paused) {
      return Icon(Icons.error_outline, size: 56, color: color);
    }
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
