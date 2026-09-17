import 'models.dart';

extension ChineseEntryVisibility on ChineseEntry {
  bool isVisibleFor({
    required ScriptDisplay display,
    required int maxLevel,
  }) =>
      characterLevel <= maxLevel &&
      switch (display) {
        ScriptDisplay.simplified => script != CharacterScript.traditional,
        ScriptDisplay.traditional => script != CharacterScript.simplified,
      };
}
