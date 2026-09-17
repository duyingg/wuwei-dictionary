import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';

import '../../features/dictionary/single_han_validator.dart';

/// 将正文中的每个汉字变成独立入口；标点、数字和空白保持普通文本。
class TappableHanText extends StatelessWidget {
  const TappableHanText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.start,
    this.anchorKeys,
    this.anchorPrefix = 'text',
    this.anchorStart = 0,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final Map<String, GlobalKey>? anchorKeys;
  final String anchorPrefix;
  final int anchorStart;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = DefaultTextStyle.of(context).style.merge(style);
    final values = text.characters.toList();
    return Text.rich(
      TextSpan(
        children: [
          for (final indexed in values.indexed)
            if (_isHan(indexed.$2))
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                // Match the surrounding TextSpan baseline. Using the
                // ideographic baseline here made individually tappable Han
                // glyphs jump vertically among punctuation and rare glyphs.
                baseline: TextBaseline.alphabetic,
                child: Semantics(
                  key: anchorKeys?.putIfAbsent(
                    '$anchorPrefix-${anchorStart + indexed.$1}',
                    GlobalKey.new,
                  ),
                  button: true,
                  label: '查询${indexed.$2}',
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () =>
                          context.push(AppRoutes.character(indexed.$2)),
                      child: Text(indexed.$2, style: effectiveStyle),
                    ),
                  ),
                ),
              )
            else
              TextSpan(text: indexed.$2),
        ],
      ),
      textAlign: textAlign,
      style: effectiveStyle,
    );
  }

  bool _isHan(String value) =>
      const SingleHanValidator().validate(value) is ValidHan;
}

String? topVisibleHanAnchor(
  Map<String, GlobalKey> anchorKeys,
  GlobalKey viewportKey,
) {
  final viewportBox =
      viewportKey.currentContext?.findRenderObject() as RenderBox?;
  if (viewportBox == null || !viewportBox.hasSize) return null;
  final viewportTop = viewportBox.localToGlobal(Offset.zero).dy;
  final viewportBottom = viewportTop + viewportBox.size.height;
  String? best;
  var bestDistance = double.infinity;
  for (final entry in anchorKeys.entries) {
    final box = entry.value.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) continue;
    final top = box.localToGlobal(Offset.zero).dy;
    final bottom = top + box.size.height;
    if (bottom < viewportTop || top > viewportBottom) continue;
    final distance = (top - viewportTop).abs();
    if (distance < bestDistance) {
      bestDistance = distance;
      best = entry.key;
    }
  }
  return best;
}

Future<void> restoreHanAnchor(
  Map<String, GlobalKey> anchorKeys,
  String anchor,
) async {
  for (final delay in const [0, 16, 50, 150]) {
    if (delay > 0) await Future<void>.delayed(Duration(milliseconds: delay));
    final context = anchorKeys[anchor]?.currentContext;
    if (context == null || !context.mounted) continue;
    await Scrollable.ensureVisible(
      context,
      alignment: 0,
      duration: const Duration(milliseconds: 1),
    );
    return;
  }
}
