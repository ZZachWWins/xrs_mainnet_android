import 'package:flutter/material.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';
import 'package:xeris_wallet/core/services/notification_service.dart';
import 'package:xeris_wallet/core/utils/string_extensions.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';

enum PinMode { setup, verify, setupPanic }

class PinCodeScreen extends StatefulWidget {
  final PinMode mode;
  final String? existingPin; // For verifying old PIN before change
  const PinCodeScreen({super.key, required this.mode, this.existingPin});

  @override
  State<PinCodeScreen> createState() => _PinCodeScreenState();
}

class _PinCodeScreenState extends State<PinCodeScreen> {
  String _currentInput = '';
  String _firstPin = '';
  DateTime? _lockedUntil;

  // Brute-force backoff schedule: failure-count -> lockout duration.
  // After 20 failures we wipe all wallet state.
  static const Map<int, Duration> _backoff = {
    5: Duration(seconds: 30),
    7: Duration(minutes: 1),
    10: Duration(minutes: 5),
    13: Duration(minutes: 30),
    16: Duration(hours: 1),
  };
  static const int _wipeThreshold = 20;

  @override
  void initState() {
    super.initState();
    if (widget.mode == PinMode.verify) {
      _refreshLockout();
    }
  }

  Future<void> _refreshLockout() async {
    final untilMs = await StorageService.getPinLockoutUntilMs();
    if (untilMs == null) {
      if (mounted) setState(() => _lockedUntil = null);
      return;
    }
    final until = DateTime.fromMillisecondsSinceEpoch(untilMs);
    if (until.isBefore(DateTime.now())) {
      await StorageService.setPinLockoutUntilMs(null);
      if (mounted) setState(() => _lockedUntil = null);
    } else if (mounted) {
      setState(() => _lockedUntil = until);
    }
  }

  bool get _isLocked =>
      _lockedUntil != null && _lockedUntil!.isAfter(DateTime.now());

  String _formatRemaining(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inSeconds}s';
  }

  void _onKeyPress(String key) {
    if (widget.mode == PinMode.verify && _isLocked) return;
    if (_currentInput.length < 6) {
      setState(() {
        _currentInput += key;
      });
    }

    if (_currentInput.length == 6) {
      _handleSubmit();
    }
  }

  void _onBackspace() {
    if (_currentInput.isNotEmpty) {
      setState(() {
        _currentInput = _currentInput.safeSubstring(0, _currentInput.length - 1);
      });
    }
  }

  Future<void> _handleSubmit() async {
    final l10n = AppLocalizations.of(context)!;
    if (widget.mode == PinMode.verify) {
      // Panic PIN check first — a match wipes everything.
      if (await StorageService.verifyPanicPin(_currentInput)) {
        await StorageService.clearAll();
        if (!mounted) return;
        NotificationService.show(context, l10n.panicTriggered, isError: true);
        context.go('/setup');
        return;
      }

      // Verify against a caller-supplied PIN (e.g. a change-PIN flow) or the
      // stored salted hash.
      final bool pinMatches = widget.existingPin != null
          ? _currentInput == widget.existingPin
          : await StorageService.verifyPinCode(_currentInput);

      if (pinMatches) {
        await StorageService.resetPinFailures();
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        await _registerFailedAttempt(l10n);
      }
    } else if (widget.mode == PinMode.setupPanic) {
      // Setup Panic Mode
      if (_firstPin.isEmpty) {
        setState(() {
          _firstPin = _currentInput;
          _currentInput = '';
        });
      } else {
        if (_currentInput == _firstPin) {
          await StorageService.setPanicPin(_currentInput);
          if (!mounted) return;
          Navigator.pop(context, true);
        } else {
          setState(() {
            _currentInput = '';
            _firstPin = ''; 
          });
          if (mounted) NotificationService.show(context, l10n.pinsDoNotMatch, isError: true);
        }
      }
    } else {
      // Setup Mode
      if (_firstPin.isEmpty) {
        setState(() {
          _firstPin = _currentInput;
          _currentInput = '';
        });
      } else {
        if (_currentInput == _firstPin) {
          await StorageService.setPinCode(_currentInput);
          await StorageService.setUsePin(true);
          if (!mounted) return;
          Navigator.pop(context, true);
        } else {
          setState(() {
            _currentInput = '';
            _firstPin = ''; // Reset to start over
          });
          if (mounted) NotificationService.show(context, l10n.pinsDoNotMatch, isError: true);
        }
      }
    }
  }

  Future<void> _registerFailedAttempt(AppLocalizations l10n) async {
    final newCount = await StorageService.getPinFailureCount() + 1;
    await StorageService.setPinFailureCount(newCount);

    if (newCount >= _wipeThreshold) {
      await StorageService.clearAll();
      if (!mounted) return;
      NotificationService.show(context, l10n.panicTriggered, isError: true);
      context.go('/onboarding');
      return;
    }

    final lockDuration = _backoff[newCount];
    if (lockDuration != null) {
      final until = DateTime.now().add(lockDuration);
      await StorageService.setPinLockoutUntilMs(until.millisecondsSinceEpoch);
      if (mounted) setState(() => _lockedUntil = until);
    }

    if (!mounted) return;
    setState(() {
      _currentInput = '';
    });
    NotificationService.show(context, l10n.incorrectPin, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String title = '';
    if (widget.mode == PinMode.verify) {
      title = l10n.enterPinCode;
    } else if (widget.mode == PinMode.setupPanic) {
      title = _firstPin.isEmpty ? l10n.setPanicPin : l10n.confirmPanicPin;
    } else {
      title = _firstPin.isEmpty ? l10n.setNewPin : l10n.confirmPin;
    }

    return Scaffold(
      backgroundColor: AppColors.brandNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.pinSubtitle,
            style: const TextStyle(color: AppColors.textBody),
          ),
          if (widget.mode == PinMode.verify && _isLocked) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Too many attempts. Try again in '
                '${_formatRemaining(_lockedUntil!.difference(DateTime.now()))}.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 60),

          // PIN Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              final filled = index < _currentInput.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? AppColors.brandVibrant : Colors.white.withValues(alpha: 0.1),
                  border: Border.all(
                    color: filled ? AppColors.brandVibrant : Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              );
            }),
          ),
          
          const Spacer(),
          
          // Numeric Pad
          _buildNumericPad(),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildNumericPad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['1', '2', '3'].map((n) => _buildKey(n)).toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['4', '5', '6'].map((n) => _buildKey(n)).toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['7', '8', '9'].map((n) => _buildKey(n)).toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 80),
            _buildKey('0'),
            _buildKey('backspace', icon: Icons.backspace_outlined),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(String value, {IconData? icon}) {
    return Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.all(10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => value == 'backspace' ? _onBackspace() : _onKeyPress(value),
          borderRadius: BorderRadius.circular(40),
          child: Center(
            child: icon != null 
                ? Icon(icon, color: Colors.white, size: 28)
                : Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
