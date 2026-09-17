import 'package:flutter/material.dart';

/// 拖动时只更新本地位置，松手后提交一次，避免异步持久化竞争导致滑块回跳。
class CommittedSlider extends StatefulWidget {
  const CommittedSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.labelBuilder,
    required this.onCommitted,
    this.onChanged,
    this.tickLabels = const [],
    this.compact = false,
    super.key,
  });

  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double value) labelBuilder;
  final ValueChanged<double> onCommitted;
  final ValueChanged<double>? onChanged;
  final List<String> tickLabels;
  final bool compact;

  @override
  State<CommittedSlider> createState() => _CommittedSliderState();
}

class _CommittedSliderState extends State<CommittedSlider> {
  late double _value = widget.value;
  var _dragging = false;

  @override
  void didUpdateWidget(covariant CommittedSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging && widget.value != _value) _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    final slider = Slider(
      value: _value.clamp(widget.min, widget.max),
      min: widget.min,
      max: widget.max,
      divisions: widget.divisions,
      label: widget.labelBuilder(_value),
      onChangeStart: (_) => _dragging = true,
      onChanged: (value) {
        setState(() => _value = value);
        widget.onChanged?.call(value);
      },
      onChangeEnd: (value) {
        _dragging = false;
        widget.onCommitted(value);
      },
    );
    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (widget.compact)
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: slider,
        )
      else
        slider,
      if (widget.tickLabels.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final label in widget.tickLabels)
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
    ]);
  }
}
