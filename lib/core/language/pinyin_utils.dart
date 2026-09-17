abstract final class PinyinUtils {
  static const initials = <String>[
    'b',
    'p',
    'm',
    'f',
    'd',
    't',
    'n',
    'l',
    'g',
    'k',
    'h',
    'j',
    'q',
    'x',
    'zh',
    'ch',
    'sh',
    'r',
    'z',
    'c',
    's',
  ];

  static const pinyinSections = <String>[
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',
    'y',
    'z',
  ];

  static String normalize(String value) {
    const marked = 'āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜüńňǹḿ';
    const plain = 'aaaaeeeeiiiioooouuuuvvvvvnnnm';
    var result = value
        .trim()
        .toLowerCase()
        .replaceAll('ɡ', 'g')
        .replaceAll('ɑ', 'a')
        .replaceAll('ê', 'e');
    for (var index = 0; index < marked.length; index++) {
      result = result.replaceAll(marked[index], plain[index]);
    }
    return result.replaceAll(RegExp(r'[1-5\s]'), '');
  }

  static String initialOf(String value) {
    final normalized = normalize(value);
    for (final initial in const ['zh', 'ch', 'sh']) {
      if (normalized.startsWith(initial)) return initial;
    }
    for (final initial in const [
      'b',
      'p',
      'm',
      'f',
      'd',
      't',
      'n',
      'l',
      'g',
      'k',
      'h',
      'j',
      'q',
      'x',
      'r',
      'z',
      'c',
      's',
    ]) {
      if (normalized.startsWith(initial)) return initial;
    }
    return '';
  }

  static String finalOf(String value) {
    final syllable = normalize(value);
    if (syllable.isEmpty) return '';
    if (syllable.startsWith('y')) {
      return _yFinals[syllable] ?? syllable.substring(1);
    }
    if (syllable.startsWith('w')) {
      return _wFinals[syllable] ?? syllable.substring(1);
    }
    final initial = initialOf(syllable);
    var result =
        initial.isEmpty ? syllable : syllable.substring(initial.length);
    if (const ['j', 'q', 'x'].contains(initial) && result.startsWith('u')) {
      result = 'v${result.substring(1)}';
    }
    return result;
  }

  static const _yFinals = <String, String>{
    'yi': 'i',
    'ya': 'a',
    'yo': 'o',
    'ye': 'ie',
    'yai': 'ai',
    'yao': 'ao',
    'you': 'iu',
    'yan': 'an',
    'yin': 'in',
    'yang': 'ang',
    'ying': 'ing',
    'yong': 'ong',
    'yu': 'v',
    'yue': 've',
    'yuan': 'van',
    'yun': 'vn',
  };
  static const _wFinals = <String, String>{
    'wu': 'u',
    'wa': 'ua',
    'wo': 'uo',
    'wai': 'uai',
    'wei': 'ui',
    'wan': 'uan',
    'wen': 'un',
    'wang': 'uang',
    'weng': 'ueng',
  };

  static String displayFinal(String value) => value.replaceAll('v', 'ü');

  static String displaySyllable(String value) =>
      normalize(value).replaceAll('v', 'ü');

  static String firstSyllable(String value) =>
      value.trim().split(RegExp(r'\s+')).firstOrNull ?? '';

  static bool isCompoundReading(String value) =>
      value.trim().split(RegExp(r'\s+')).length > 1;

  /// 只校验单个普通话音节的形态，用于阻止源数据中的词语、乱码进入索引。
  /// 生僻但合法的声母/韵母组合仍然保留，具体读音不由此方法改写。
  static bool isValidSyllable(String value) {
    if (value.trim().contains(RegExp(r'\s'))) return false;
    final syllable = normalize(value).replaceAll('ü', 'v');
    if (const {'m', 'n', 'ng', 'hm', 'hng'}.contains(syllable)) return true;
    if (!RegExp(r'^[a-zv]+$').hasMatch(syllable)) return false;
    final finalValue = finalOf(syllable);
    if (!_validFinals.contains(finalValue)) return false;
    if (syllable.startsWith('y') || syllable.startsWith('w')) return true;
    final initial = initialOf(syllable);
    if (initial.isEmpty) return _zeroInitialSyllables.contains(syllable);
    return syllable.length > initial.length;
  }

  static const _validFinals = <String>{
    'a',
    'o',
    'e',
    'ai',
    'ei',
    'ao',
    'ou',
    'an',
    'en',
    'ang',
    'eng',
    'ong',
    'i',
    'ia',
    'ie',
    'iao',
    'iu',
    'ian',
    'in',
    'iang',
    'ing',
    'iong',
    'u',
    'ua',
    'uo',
    'uai',
    'ui',
    'uan',
    'un',
    'uang',
    'ueng',
    'v',
    've',
    'van',
    'vn',
    'er',
  };

  static const _zeroInitialSyllables = <String>{
    'a',
    'o',
    'e',
    'ai',
    'ei',
    'ao',
    'ou',
    'an',
    'en',
    'ang',
    'eng',
    'er',
  };

  static String sectionOf(String value) {
    final syllable = displaySyllable(value);
    return syllable.isEmpty ? '' : syllable[0].replaceAll('ü', 'v');
  }

  static int toneOf(String value) {
    const toneGroups = <String>[
      'āēīōūǖ',
      'áéíóúǘńḿ',
      'ǎěǐǒǔǚň',
      'àèìòùǜǹ',
    ];
    final lower = value.toLowerCase();
    for (var index = 0; index < toneGroups.length; index++) {
      if (lower.split('').any(toneGroups[index].contains)) return index + 1;
    }
    final numbered = RegExp(r'([1-5])').firstMatch(lower);
    return numbered == null ? 5 : int.parse(numbered.group(1)!);
  }
}

abstract final class RadicalUtils {
  static const _canonical =
      '一丨丶丿乙亅二亠人儿入八冂冖冫几凵刀力勹匕匚匸十卜卩厂厶又口囗土士夂夊夕大女子宀寸小尢尸屮山巛工己巾干部广廴廾弋弓彐彡彳心戈户手支攴文斗斤方无日曰月木欠止歹殳毋比毛氏气水火爪父爻爿片牙牛犬玄玉瓜瓦甘生用田疋疒癶白皮皿目矛矢石示禸禾穴立竹米糸缶网羊羽老而耒耳聿肉臣自至臼舌舛舟艮色艸虍虫血行衣襾見角言谷豆豕豸貝赤走足身車辛辰辵邑酉釆里金長門阜隶隹雨靑非面革韋韭音頁風飛食首香馬骨高髟鬥鬯鬲鬼魚鳥鹵鹿麥麻黃黍黑黹黽鼎鼓鼠鼻齊齒龍龜龠';

  static const _variants = <String, String>{
    '亻': '人',
    '刂': '刀',
    '忄': '心',
    '扌': '手',
    '攵': '攴',
    '氵': '水',
    '灬': '火',
    '爫': '爪',
    '犭': '犬',
    '王': '玉',
    '礻': '示',
    '糹': '糸',
    '纟': '糸',
    '罒': '网',
    '月': '肉',
    '艹': '艸',
    '衤': '衣',
    '覀': '襾',
    '见': '見',
    '讠': '言',
    '贝': '貝',
    '车': '車',
    '辶': '辵',
    '钅': '金',
    '长': '長',
    '门': '門',
    '阝': '阜',
    '韦': '韋',
    '页': '頁',
    '风': '風',
    '饣': '食',
    '马': '馬',
    '鱼': '魚',
    '鸟': '鳥',
    '卤': '鹵',
    '麦': '麥',
    '黄': '黃',
    '黾': '黽',
    '齐': '齊',
    '齿': '齒',
    '龙': '龍',
    '龟': '龜',
  };

  static int orderOf(String radical) {
    final canonical = _variants[radical] ?? radical;
    final index = _canonical.indexOf(canonical);
    return index < 0 ? 1000 + radical.runes.first : index;
  }

  static bool isStandard(String radical) {
    if (radical.isEmpty) return false;
    return _canonical.contains(_variants[radical] ?? radical);
  }
}
