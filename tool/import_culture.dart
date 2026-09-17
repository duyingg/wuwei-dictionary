import 'dart:convert';
import 'dart:io';

void main() {
  final surnameFile = File('Aatime/百家姓.txt');
  if (!surnameFile.existsSync()) {
    stderr.writeln('未找到 Aatime/百家姓.txt');
    exitCode = 1;
    return;
  }

  final normalizedSurnameReading = surnameFile
      .readAsLinesSync()
      .where((line) => line.trim().isNotEmpty && !line.contains('百家姓终'))
      .join('\n')
      // 原文件中的几处括号、空格录入错误会破坏姓氏与读音的配对。
      .replaceAll('郤(xì)) 璩(qú) 桑(sāng 桂(guì)', '郤(xì) 璩(qú) 桑(sāng) 桂(guì)')
      .replaceAll('汝(rǔ)鄢(yān)', '汝(rǔ) 鄢(yān)')
      .replaceAll('归(guī) 海 (hǎi)', '归海(guī hǎi)')
      .replaceAll('微(wēi) 生(shēng)', '微生(wēi shēng)');
  final surnameEntries = <(String, String)>[];
  for (final match in RegExp(r'([^\s()]+)\(([^)]+)\)')
      .allMatches(normalizedSurnameReading)) {
    surnameEntries.add((match.group(1)!, match.group(2)!.trim()));
  }
  // 结尾也是正文的一部分：第五言福｜百家姓终。
  surnameEntries.addAll(const [
    ('百', 'bǎi'),
    ('家', 'jiā'),
    ('姓', 'xìng'),
    ('终', 'zhōng'),
  ]);
  final surnameSentences = _surnameSentences(surnameEntries);
  final surnameContent = surnameSentences
      .map((sentence) => sentence.map((entry) => entry.$1).join())
      .join('\n');
  final surnameReading = surnameSentences
      .map((sentence) =>
          sentence.map((entry) => '${entry.$1}(${entry.$2})').join(' '))
      .join('\n');

  final items = <Map<String, dynamic>>[
    ..._schools,
    {
      'id': 'other-surnames',
      'category': 'other',
      'title': '百家姓',
      'subtitle': '单姓与复姓蒙学读本',
      'summary': '已导入姓氏原文和逐姓读音。',
      'content': surnameContent,
      'readingContent': surnameReading,
      'sourceId': 'user-provided-baijiaxing',
    },
    for (final title in ['千字文', '三字经', '道德经'])
      {
        'id': 'other-placeholder-${_stableId(title)}',
        'category': 'other',
        'title': title,
        'subtitle': '内容待导入',
        'summary': '条目已建立，正文暂未实装。',
        'content': '',
        'sourceId': 'placeholder',
      },
    {
      'id': 'other-solar',
      'category': 'other',
      'title': '二十四节气',
      'subtitle': '四时流转与节气歌',
      'summary': '完整收录二十四节气及大致公历时间。',
      'content': _solarTerms,
      'sourceId': 'app-original',
    },
    {
      'id': 'other-festival',
      'category': 'other',
      'title': '传统节日',
      'subtitle': '按年内时序排列',
      'summary': '左侧列节日，右侧列时间，暂不加解释。',
      'content': _festivals,
      'sourceId': 'app-original',
    },
    {
      'id': 'other-allusion',
      'category': 'other',
      'title': '典故',
      'subtitle': '古籍故事与文化用语',
      'summary': '认识成语和诗文背后的故事。',
      'content': '典故是具有出处的故事或词句，常被后世文章引用。后续可按人物、时代和主题扩展。',
      'sourceId': 'app-original',
    },
    {
      'id': 'other-title',
      'category': 'other',
      'title': '古代称谓',
      'subtitle': '姓名、亲属与礼貌称呼',
      'summary': '读懂古文中的人物关系。',
      'content': '古代称谓因身份、年龄、关系和场合而异。理解称谓有助于把握文献中的礼仪与人物关系。',
      'sourceId': 'app-original',
    },
  ];

  File('assets/data/culture_items_v2.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(items)}\n',
  );
  stdout.writeln('导入文化条目 ${items.length} 条。');
}

List<List<(String, String)>> _surnameSentences(List<(String, String)> entries) {
  final lines = <List<(String, String)>>[];
  var current = <(String, String)>[];
  var characterCount = 0;
  for (final entry in entries) {
    final length = entry.$1.runes.length;
    if (characterCount + length > 4) {
      throw FormatException(
          '无法在不拆分复姓的情况下组成四字句：${current.map((e) => e.$1).join()}');
    }
    current.add(entry);
    characterCount += length;
    if (characterCount == 4) {
      lines.add(current);
      current = [];
      characterCount = 0;
    }
  }
  if (current.isNotEmpty) throw const FormatException('百家姓末句不足四字');
  return lines;
}

String _stableId(String value) => value.runes
    .fold<int>(0, (hash, rune) => (hash * 31 + rune) & 0x7fffffff)
    .toRadixString(16);

const _schools = <Map<String, dynamic>>[
  {
    'id': 'school-ru',
    'category': 'schools',
    'title': '儒家',
    'subtitle': '仁者爱人，克己复礼',
    'summary': '代表人物：孔子、孟子、荀子',
    'content': '儒家重视仁义礼智信，强调个人修养、家庭伦理与社会责任。',
    'sourceId': 'app-original'
  },
  {
    'id': 'school-dao',
    'category': 'schools',
    'title': '道家',
    'subtitle': '道法自然，无为而治',
    'summary': '代表人物：老子、庄子',
    'content': '道家以“道”为核心，强调顺应自然规律与精神自由。',
    'sourceId': 'app-original'
  },
  {
    'id': 'school-mo',
    'category': 'schools',
    'title': '墨家',
    'subtitle': '兼爱非攻，尚贤尚同',
    'summary': '代表人物：墨子',
    'content': '墨家主张兼爱、非攻、节用和尚贤，重视实践效用。',
    'sourceId': 'app-original'
  },
  {
    'id': 'school-fa',
    'category': 'schools',
    'title': '法家',
    'subtitle': '以法治国，赏罚分明',
    'summary': '代表人物：韩非、商鞅、申不害',
    'content': '法家强调法、术、势与治理效能。',
    'sourceId': 'app-original'
  },
  {
    'id': 'school-ming',
    'category': 'schools',
    'title': '名家',
    'subtitle': '辨名析理，察同异',
    'summary': '代表人物：惠施、公孙龙',
    'content': '名家关注名实关系、概念界限和辩论方法。',
    'sourceId': 'app-original'
  },
  {
    'id': 'school-yinyang',
    'category': 'schools',
    'title': '阴阳家',
    'subtitle': '阴阳消长，五行相生',
    'summary': '代表人物：邹衍',
    'content': '阴阳家以阴阳、五行解释自然、历法和人事变化。',
    'sourceId': 'app-original'
  },
  {
    'id': 'school-zongheng',
    'category': 'schools',
    'title': '纵横家',
    'subtitle': '合纵连横，因势设谋',
    'summary': '代表人物：苏秦、张仪',
    'content': '纵横家长于外交辩说、形势判断和国际策略。',
    'sourceId': 'app-original'
  },
  {
    'id': 'school-za',
    'category': 'schools',
    'title': '杂家',
    'subtitle': '兼儒墨，合名法',
    'summary': '代表人物：吕不韦、尸佼',
    'content': '杂家博采诸家所长，尝试建立综合性的治理与知识体系。',
    'sourceId': 'app-original'
  },
  {
    'id': 'school-nong',
    'category': 'schools',
    'title': '农家',
    'subtitle': '播百谷，劝耕桑',
    'summary': '代表人物：许行',
    'content': '农家重视农业生产、农时、土地和自给经济。',
    'sourceId': 'app-original'
  },
  {
    'id': 'school-xiaoshuo',
    'category': 'schools',
    'title': '小说家',
    'subtitle': '街谈巷语，道听途说',
    'summary': '代表：稗官采集的民间言论',
    'content': '小说家汇集民间故事、风俗与议论，保留社会生活的侧面记录。',
    'sourceId': 'app-original'
  },
  {
    'id': 'school-bing',
    'category': 'schools',
    'title': '兵家',
    'subtitle': '知己知彼，百战不殆',
    'summary': '代表人物：孙武、吴起、孙膑',
    'content': '兵家研究战争规律、组织策略、地形与谋略。',
    'sourceId': 'app-original'
  },
  {
    'id': 'school-yi',
    'category': 'schools',
    'title': '医家',
    'subtitle': '辨证论治，养生济人',
    'summary': '代表人物：扁鹊、仓公',
    'content': '医家累积疾病诊疗、药物、养生和生命观念方面的知识。',
    'sourceId': 'app-original'
  },
];

const _solarTerms = '''
立春|2月3–5日
雨水|2月18–20日
惊蛰|3月5–7日
春分|3月20–22日
清明|4月4–6日
谷雨|4月19–21日
立夏|5月5–7日
小满|5月20–22日
芒种|6月5–7日
夏至|6月21–22日
小暑|7月6–8日
大暑|7月22–24日
立秋|8月7–9日
处暑|8月22–24日
白露|9月7–9日
秋分|9月22–24日
寒露|10月8–9日
霜降|10月23–24日
立冬|11月7–8日
小雪|11月22–23日
大雪|12月6–8日
冬至|12月21–23日
小寒|1月5–7日
大寒|1月20–21日

节气歌
春雨惊春清谷天，夏满芒夏暑相连。
秋处露秋寒霜降，冬雪雪冬小大寒。
每月两节不变更，最多相差一两天。
上半年来六廿一，下半年是八廿三。
''';

const _festivals = '''
春节|农历正月初一
人日|农历正月初七
元宵节|农历正月十五
填仓节|农历正月廿五
龙抬头|农历二月初二
花朝节|农历二月十二或十五
上巳节|农历三月初三
寒食节|清明前一或二日
清明节|公历4月4–6日
端午节|农历五月初五
七夕节|农历七月初七
中元节|农历七月十五
中秋节|农历八月十五
重阳节|农历九月初九
寒衣节|农历十月初一
下元节|农历十月十五
冬至节|公历12月21–23日
腊八节|农历腊月初八
小年|农历腊月廿三或廿四
除夕|农历腊月最后一日
''';
