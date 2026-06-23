import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../services/pin_service.dart';
import 'home_screen.dart';

enum PinMode { unlock, setup, confirm, change, verify }

class PinScreen extends StatefulWidget {
  final PinMode mode;
  final String? confirmPin;

  const PinScreen({super.key, required this.mode, this.confirmPin});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen>
    with SingleTickerProviderStateMixin {
  final _pinService = PinService();
  String _entered = '';
  String? _error;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  String _title(AppLocalizations l) {
    switch (widget.mode) {
      case PinMode.unlock: return l.pinUnlockTitle;
      case PinMode.setup:  return l.pinSetupTitle;
      case PinMode.confirm: return l.pinConfirmTitle;
      case PinMode.change: return l.pinChangeTitle;
      case PinMode.verify: return l.pinUnlockTitle;
    }
  }

  String _subtitle(AppLocalizations l) {
    switch (widget.mode) {
      case PinMode.unlock: return l.pinUnlockSub;
      case PinMode.setup:  return l.pinSetupSub;
      case PinMode.confirm: return l.pinConfirmSub;
      case PinMode.change: return l.pinChangeSub;
      case PinMode.verify: return l.pinUnlockSub;
    }
  }

  Future<void> _onDigit(String digit) async {
    if (_entered.length >= 4) return;
    HapticFeedback.selectionClick();
    setState(() {
      _entered += digit;
      _error = null;
    });
    if (_entered.length == 4) {
      await Future.delayed(const Duration(milliseconds: 100));
      await _handleComplete();
    }
  }

  void _onDelete() {
    if (_entered.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _handleComplete() async {
    final l = AppLocalizations.of(context);
    switch (widget.mode) {
      case PinMode.unlock:
        final ok = await _pinService.verifyPin(_entered);
        if (ok) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const HomeScreen(),
                transitionsBuilder: (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          }
        } else {
          _shake(l.pinWrong);
        }
        break;

      case PinMode.verify:
        final ok = await _pinService.verifyPin(_entered);
        if (ok) {
          if (mounted) Navigator.of(context).pop(true);
        } else {
          _shake(l.pinWrong);
        }
        break;

      case PinMode.setup:
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  PinScreen(mode: PinMode.confirm, confirmPin: _entered),
            ),
          );
        }
        break;

      case PinMode.confirm:
        if (_entered == widget.confirmPin) {
          await _pinService.setPin(_entered);
          if (mounted) {
            // Pop confirm, then pop setup — returning true all the way to caller
            Navigator.of(context).pop(true); // pop confirm
            Navigator.of(context).pop(true); // pop setup → result reaches settings
          }
        } else {
          _shake(l.pinMismatch);
        }
        break;

      case PinMode.change:
        final ok = await _pinService.verifyPin(_entered);
        if (ok) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const PinScreen(mode: PinMode.setup),
              ),
            );
          }
        } else {
          _shake(l.pinWrong);
        }
        break;
    }
  }

  void _shake(String msg) {
    HapticFeedback.vibrate();
    setState(() {
      _entered = '';
      _error = msg;
    });
    _shakeCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final bg = theme.scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: bg,
      appBar: (widget.mode == PinMode.unlock || widget.mode == PinMode.verify)
          ? null
          : AppBar(
              backgroundColor: bg,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              title: Text(_title(l),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.mode == PinMode.unlock
                    ? Icons.lock_outline_rounded
                    : Icons.lock_open_rounded,
                color: theme.colorScheme.onPrimaryContainer,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),

            Text(_title(l),
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(_subtitle(l),
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 32),

            // PIN dots
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, child) {
                final shake =
                    (_shakeAnim.value * 12 * (1 - _shakeAnim.value))
                        .toDouble();
                return Transform.translate(
                  offset: Offset(shake, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _entered.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: _error != null
                            ? Colors.red.shade400
                            : filled
                                ? theme.colorScheme.primary
                                : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 12),
            AnimatedOpacity(
              opacity: _error != null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                _error ?? '',
                style: TextStyle(
                    color: Colors.red.shade500, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),

            // Keypad
            _Keypad(onDigit: _onDigit, onDelete: _onDelete),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  const _Keypad({required this.onDigit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: rows.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) {
            if (key.isEmpty) return const SizedBox(width: 80, height: 72);
            return _KeyButton(
              label: key,
              onTap: key == '⌫' ? () => onDelete() : () => onDigit(key),
              isDelete: key == '⌫',
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDelete;

  const _KeyButton({
    required this.label,
    required this.onTap,
    this.isDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 80,
      height: 72,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(40),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDelete
                    ? Colors.transparent
                    : theme.colorScheme.surfaceVariant.withAlpha(120),
              ),
              child: Center(
                child: isDelete
                    ? Icon(Icons.backspace_outlined,
                        size: 22, color: Colors.grey.shade600)
                    : Text(
                        label,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
