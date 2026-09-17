enum DailyContentType { character, word, idiom, verse }

extension DailyContentTypeLabel on DailyContentType {
  String get label => switch (this) {
        DailyContentType.character => '文字',
        DailyContentType.word => '词语',
        DailyContentType.idiom => '成语',
        DailyContentType.verse => '诗句',
      };
}

enum AppFontScale { small, standard, large, extraLarge }

enum CharacterScript { simplified, traditional, common }

extension CharacterScriptLabel on CharacterScript {
  String get label => switch (this) {
        CharacterScript.simplified => '简体字',
        CharacterScript.traditional => '繁体字',
        CharacterScript.common => '简繁同形',
      };
}

enum ScriptDisplay { simplified, traditional }

extension ScriptDisplayLabel on ScriptDisplay {
  String get label => switch (this) {
        ScriptDisplay.simplified => '简体',
        ScriptDisplay.traditional => '繁体',
      };
}

enum AppSkin { parchment, jade, night, imported }

extension AppSkinLabel on AppSkin {
  String get label => switch (this) {
        AppSkin.parchment => '宣纸棕',
        AppSkin.jade => '青玉绿',
        AppSkin.night => '墨夜蓝',
        AppSkin.imported => '导入皮肤',
      };
}

class ImportedSkin {
  const ImportedSkin({
    required this.name,
    required this.description,
    required this.background,
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.text,
    required this.border,
    this.mutedText = 0xFF7D7770,
    this.onPrimary = 0xFFFFFFFF,
    this.error = 0xFFB5483A,
    this.success = 0xFF32735E,
    this.icons = const {},
    this.assets = const {},
    this.backgroundAsset,
    this.backgroundFit = 'cover',
    this.backgroundOpacity = 1,
    this.surfaceOpacity = 1,
    this.cardRadius = 16,
    this.inputRadius = 14,
    this.buttonRadius = 12,
    this.cardElevation = 0,
    this.fontFamily = '',
  });

  final String name;
  final String description;
  final int background;
  final int surface;
  final int primary;
  final int secondary;
  final int text;
  final int border;
  final int mutedText;
  final int onPrimary;
  final int error;
  final int success;
  final Map<String, String> icons;
  final Map<String, String> assets;
  final String? backgroundAsset;
  final String backgroundFit;
  final double backgroundOpacity;
  final double surfaceOpacity;
  final double cardRadius;
  final double inputRadius;
  final double buttonRadius;
  final double cardElevation;
  final String fontFamily;

  factory ImportedSkin.fromJson(Map<String, dynamic> json) {
    final colors = Map<String, dynamic>.from(
      json['colors'] as Map? ?? const <String, dynamic>{},
    );
    final name = json['name']?.toString().trim() ?? '';
    if (name.isEmpty || name.length > 32) {
      throw const FormatException('皮肤名称不能为空且不能超过32个字符');
    }
    int readColor(String key, [int? fallback]) {
      final raw = colors[key]?.toString().trim() ?? '';
      if (raw.isEmpty && fallback != null) return fallback;
      final normalized = raw.startsWith('#') ? raw.substring(1) : raw;
      final value = int.tryParse(normalized, radix: 16);
      if (value == null || (normalized.length != 6 && normalized.length != 8)) {
        throw FormatException('颜色 $key 必须使用 #RRGGBB 或 #AARRGGBB');
      }
      return normalized.length == 6 ? 0xFF000000 | value : value;
    }

    final rawIcons = Map<String, dynamic>.from(
      json['icons'] as Map? ?? const <String, dynamic>{},
    );
    final rawAssets = Map<String, dynamic>.from(
      json['assets'] as Map? ?? const <String, dynamic>{},
    );
    final appearance = Map<String, dynamic>.from(
      json['appearance'] as Map? ?? const <String, dynamic>{},
    );
    double readNumber(String key, double fallback, double min, double max) =>
        ((appearance[key] as num?)?.toDouble() ?? fallback).clamp(min, max);
    return ImportedSkin(
      name: name,
      description: json['description']?.toString().trim().isNotEmpty == true
          ? json['description'].toString().trim()
          : '从本地 JSON 文件导入',
      background: readColor('background'),
      surface: readColor('surface'),
      primary: readColor('primary'),
      secondary: readColor('secondary'),
      text: readColor('text'),
      border: readColor('border'),
      mutedText: readColor('mutedText', 0xFF7D7770),
      onPrimary: readColor('onPrimary', 0xFFFFFFFF),
      error: readColor('error', 0xFFB5483A),
      success: readColor('success', 0xFF32735E),
      icons: {
        for (final entry in rawIcons.entries)
          if (entry.key.length <= 64 && entry.value.toString().length <= 64)
            entry.key: entry.value.toString(),
      },
      assets: {
        for (final entry in rawAssets.entries)
          if (entry.key.length <= 128 &&
              entry.value.toString().length <= 28000000)
            entry.key: entry.value.toString(),
      },
      backgroundAsset: appearance['backgroundAsset']?.toString(),
      backgroundFit: appearance['backgroundFit']?.toString() ?? 'cover',
      backgroundOpacity: readNumber('backgroundOpacity', 1, 0, 1),
      surfaceOpacity: readNumber('surfaceOpacity', 1, 0, 1),
      cardRadius: readNumber('cardRadius', 16, 0, 40),
      inputRadius: readNumber('inputRadius', 14, 0, 40),
      buttonRadius: readNumber('buttonRadius', 12, 0, 40),
      cardElevation: readNumber('cardElevation', 0, 0, 16),
      fontFamily: json['fontFamily']?.toString().trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'colors': {
          'background': _hex(background),
          'surface': _hex(surface),
          'primary': _hex(primary),
          'secondary': _hex(secondary),
          'text': _hex(text),
          'border': _hex(border),
          'mutedText': _hex(mutedText),
          'onPrimary': _hex(onPrimary),
          'error': _hex(error),
          'success': _hex(success),
        },
        if (icons.isNotEmpty) 'icons': icons,
        if (assets.isNotEmpty) 'assets': assets,
        'appearance': {
          if (backgroundAsset != null) 'backgroundAsset': backgroundAsset,
          'backgroundFit': backgroundFit,
          'backgroundOpacity': backgroundOpacity,
          'surfaceOpacity': surfaceOpacity,
          'cardRadius': cardRadius,
          'inputRadius': inputRadius,
          'buttonRadius': buttonRadius,
          'cardElevation': cardElevation,
        },
        if (fontFamily.isNotEmpty) 'fontFamily': fontFamily,
      };

  static String _hex(int value) =>
      '#${value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
}

extension AppFontScaleValue on AppFontScale {
  String get label => switch (this) {
        AppFontScale.small => '小',
        AppFontScale.standard => '标准',
        AppFontScale.large => '大',
        AppFontScale.extraLarge => '特大',
      };
  double get factor => switch (this) {
        AppFontScale.small => .9,
        AppFontScale.standard => 1,
        AppFontScale.large => 1.15,
        AppFontScale.extraLarge => 1.3,
      };
}

class AppSettings {
  const AppSettings({
    this.dailyContentType = DailyContentType.character,
    this.fontScale = AppFontScale.standard,
    this.keepSearchHistory = true,
    this.autofocusAfterClear = true,
    this.reduceDecoration = false,
    this.fullPoetryLibrary = false,
    this.scriptDisplay = ScriptDisplay.simplified,
    this.maxCharacterLevel = 3,
    this.skin = AppSkin.parchment,
    this.importedSkin,
    this.importedSkins = const [],
    this.sidebarWidth = 68,
  });
  final DailyContentType dailyContentType;
  final AppFontScale fontScale;
  final bool keepSearchHistory;
  final bool autofocusAfterClear;
  final bool reduceDecoration;
  final bool fullPoetryLibrary;
  final ScriptDisplay scriptDisplay;
  final int maxCharacterLevel;
  final AppSkin skin;
  final ImportedSkin? importedSkin;
  final List<ImportedSkin> importedSkins;
  final double sidebarWidth;

  AppSettings copyWith({
    DailyContentType? dailyContentType,
    AppFontScale? fontScale,
    bool? keepSearchHistory,
    bool? autofocusAfterClear,
    bool? reduceDecoration,
    bool? fullPoetryLibrary,
    ScriptDisplay? scriptDisplay,
    int? maxCharacterLevel,
    AppSkin? skin,
    ImportedSkin? importedSkin,
    List<ImportedSkin>? importedSkins,
    bool clearImportedSkin = false,
    double? sidebarWidth,
  }) =>
      AppSettings(
        dailyContentType: dailyContentType ?? this.dailyContentType,
        fontScale: fontScale ?? this.fontScale,
        keepSearchHistory: keepSearchHistory ?? this.keepSearchHistory,
        autofocusAfterClear: autofocusAfterClear ?? this.autofocusAfterClear,
        reduceDecoration: reduceDecoration ?? this.reduceDecoration,
        fullPoetryLibrary: fullPoetryLibrary ?? this.fullPoetryLibrary,
        scriptDisplay: scriptDisplay ?? this.scriptDisplay,
        maxCharacterLevel: maxCharacterLevel ?? this.maxCharacterLevel,
        skin: skin ?? this.skin,
        importedSkin:
            clearImportedSkin ? null : importedSkin ?? this.importedSkin,
        importedSkins: importedSkins ?? this.importedSkins,
        sidebarWidth: sidebarWidth ?? this.sidebarWidth,
      );
}

class ChineseSense {
  const ChineseSense({
    required this.definition,
    required this.examples,
    this.pinyin = '',
    this.partOfSpeech = '',
  });
  final String definition;
  final List<String> examples;
  final String pinyin;
  final String partOfSpeech;
  factory ChineseSense.fromJson(Map<String, dynamic> json) => ChineseSense(
        definition: json['definition'] as String,
        examples: List<String>.from(json['examples'] as List? ?? const []),
        pinyin: json['pinyin'] as String? ?? '',
        partOfSpeech: json['partOfSpeech'] as String? ?? '',
      );
}

class ChineseEntry {
  const ChineseEntry({
    required this.character,
    required this.pinyin,
    required this.radical,
    required this.strokeCount,
    required this.structure,
    required this.unicode,
    required this.senses,
    required this.sourceId,
    this.rhyme = '',
    this.difficult = false,
    this.traditional,
    this.variants = const [],
    this.decomposition,
    this.strokeOrderAsset,
    this.script = CharacterScript.common,
    this.simplifiedForms = const [],
    this.traditionalForms = const [],
    this.characterLevel = 3,
  });
  final String character;
  final List<String> pinyin;
  final String radical;
  final int strokeCount;
  final String structure;
  final String unicode;
  final String? traditional;
  final List<String> variants;
  final List<ChineseSense> senses;
  final String rhyme;
  final bool difficult;
  final String sourceId;
  final String? decomposition;
  final String? strokeOrderAsset;
  final CharacterScript script;
  final List<String> simplifiedForms;
  final List<String> traditionalForms;
  final int characterLevel;

  factory ChineseEntry.fromJson(Map<String, dynamic> json) => ChineseEntry(
        character: json['character'] as String,
        pinyin: List<String>.from(json['pinyin'] as List),
        radical: json['radical'] as String,
        strokeCount: json['strokeCount'] as int,
        structure: json['structure'] as String,
        unicode: json['unicode'] as String,
        traditional: json['traditional'] as String?,
        variants: List<String>.from(json['variants'] as List? ?? const []),
        senses: (json['senses'] as List)
            .map((e) => ChineseSense.fromJson(e as Map<String, dynamic>))
            .toList(),
        rhyme: json['rhyme'] as String? ?? '',
        difficult: json['difficult'] as bool? ?? false,
        sourceId: json['sourceId'] as String,
        decomposition: json['decomposition'] as String?,
        strokeOrderAsset: json['strokeOrderAsset'] as String?,
        script: CharacterScript.values.byName(
          json['script'] as String? ?? 'common',
        ),
        simplifiedForms:
            List<String>.from(json['simplifiedForms'] as List? ?? const []),
        traditionalForms:
            List<String>.from(json['traditionalForms'] as List? ?? const []),
        characterLevel: json['characterLevel'] as int? ?? 3,
      );
}

class PolyphonicLesson {
  const PolyphonicLesson({
    required this.level,
    required this.character,
    required this.readings,
    required this.phrases,
    required this.meanings,
  });

  final int level;
  final String character;
  final List<String> readings;
  final List<String> phrases;
  final List<String> meanings;

  factory PolyphonicLesson.fromJson(Map<String, dynamic> json) =>
      PolyphonicLesson(
        level: json['level'] as int,
        character: json['character'] as String,
        readings: List<String>.from(json['readings'] as List),
        phrases: List<String>.from(json['phrases'] as List),
        meanings: List<String>.from(json['meanings'] as List? ?? const []),
      );
}

class DailyContent {
  const DailyContent({
    required this.id,
    required this.type,
    required this.title,
    required this.summary,
    required this.sourceId,
    this.pronunciation,
    this.author,
    this.sourceTitle,
  });
  final String id;
  final DailyContentType type;
  final String title;
  final String summary;
  final String? pronunciation;
  final String? author;
  final String? sourceTitle;
  final String sourceId;
  factory DailyContent.fromJson(Map<String, dynamic> json) => DailyContent(
        id: json['id'] as String,
        type: DailyContentType.values.byName(json['type'] as String),
        title: json['title'] as String,
        summary: json['summary'] as String,
        pronunciation: json['pronunciation'] as String?,
        author: json['author'] as String?,
        sourceTitle: json['sourceTitle'] as String?,
        sourceId: json['sourceId'] as String,
      );
}

enum CultureCategory { schools, tangPoems, other }

extension CultureCategoryLabel on CultureCategory {
  String get label => switch (this) {
        CultureCategory.schools => '诸子百家',
        CultureCategory.tangPoems => '诗词',
        CultureCategory.other => '其他',
      };
}

class CultureItem {
  const CultureItem(
      {required this.id,
      required this.category,
      required this.title,
      required this.subtitle,
      required this.summary,
      required this.content,
      required this.sourceId,
      this.readingContent});
  final String id;
  final CultureCategory category;
  final String title;
  final String subtitle;
  final String summary;
  final String content;
  final String sourceId;
  final String? readingContent;
  factory CultureItem.fromJson(Map<String, dynamic> json) => CultureItem(
        id: json['id'] as String,
        category: CultureCategory.values.byName(json['category'] as String),
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
        summary: json['summary'] as String,
        content: json['content'] as String,
        sourceId: json['sourceId'] as String,
        readingContent: json['readingContent'] as String?,
      );
}

enum CultureDisplayMode { reading, notes, translation }

extension CultureDisplayModeLabel on CultureDisplayMode {
  String get label => switch (this) {
        CultureDisplayMode.reading => '读音',
        CultureDisplayMode.notes => '注释',
        CultureDisplayMode.translation => '翻译',
      };
}

class PoetryItem {
  const PoetryItem({
    required this.id,
    required this.title,
    required this.author,
    required this.dynasty,
    required this.form,
    required this.style,
    required this.theme,
    required this.emotion,
    required this.content,
    required this.shuffleKey,
    required this.sequence,
    required this.searchText,
    required this.sourceId,
    this.notes = '',
    this.translation = '',
    this.appreciation = '',
  });

  final String id;
  final String title;
  final String author;
  final String dynasty;
  final String form;
  final String style;
  final String theme;
  final String emotion;
  final String content;
  final int shuffleKey;
  final int sequence;
  final String searchText;
  final String sourceId;
  final String notes;
  final String translation;
  final String appreciation;

  factory PoetryItem.fromJson(Map<String, dynamic> json) => PoetryItem(
        id: json['id'] as String,
        title: json['title'] as String,
        author: json['author'] as String,
        dynasty: json['dynasty'] as String,
        form: json['form'] as String,
        style: json['style'] as String,
        theme: json['theme'] as String,
        emotion: json['emotion'] as String,
        content: json['content'] as String,
        shuffleKey: json['shuffleKey'] as int,
        sequence: json['sequence'] as int,
        searchText: json['searchText'] as String,
        sourceId: json['sourceId'] as String,
        notes: json['notes'] as String? ?? '',
        translation: json['translation'] as String? ?? '',
        appreciation: json['appreciation'] as String? ?? '',
      );
}
