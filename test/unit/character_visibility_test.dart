import 'package:flutter_test/flutter_test.dart';
import 'package:wuwei_dictionary/features/domain/character_visibility.dart';
import 'package:wuwei_dictionary/features/domain/models.dart';

ChineseEntry entry({
  required CharacterScript script,
  int level = 1,
}) =>
    ChineseEntry(
      character: '字',
      pinyin: const ['zì'],
      radical: '子',
      strokeCount: 6,
      structure: '上下',
      unicode: 'U+5B57',
      senses: const [],
      sourceId: 'test',
      script: script,
      characterLevel: level,
    );

void main() {
  test('简繁模式只排除另一套专属字形', () {
    final common = entry(script: CharacterScript.common);
    final simplified = entry(script: CharacterScript.simplified);
    final traditional = entry(script: CharacterScript.traditional);

    expect(
      common.isVisibleFor(display: ScriptDisplay.simplified, maxLevel: 3),
      isTrue,
    );
    expect(
      simplified.isVisibleFor(display: ScriptDisplay.simplified, maxLevel: 3),
      isTrue,
    );
    expect(
      traditional.isVisibleFor(display: ScriptDisplay.simplified, maxLevel: 3),
      isFalse,
    );
    expect(
      simplified.isVisibleFor(display: ScriptDisplay.traditional, maxLevel: 3),
      isFalse,
    );
  });

  test('最高字级过滤与边界一致', () {
    expect(
      entry(script: CharacterScript.common, level: 2)
          .isVisibleFor(display: ScriptDisplay.simplified, maxLevel: 2),
      isTrue,
    );
    expect(
      entry(script: CharacterScript.common, level: 3)
          .isVisibleFor(display: ScriptDisplay.simplified, maxLevel: 2),
      isFalse,
    );
  });
}
