import 'package:flutter/material.dart';

/// Switch cập nhật visual ngay khi chạm — không chờ async parent.
class InstantSwitch extends StatefulWidget {
  const InstantSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  State<InstantSwitch> createState() => _InstantSwitchState();
}

class _InstantSwitchState extends State<InstantSwitch> {
  late bool _local;

  @override
  void initState() {
    super.initState();
    _local = widget.value;
  }

  @override
  void didUpdateWidget(InstantSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _local = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: _local,
      onChanged: (v) {
        setState(() => _local = v);
        widget.onChanged(v);
      },
    );
  }
}
