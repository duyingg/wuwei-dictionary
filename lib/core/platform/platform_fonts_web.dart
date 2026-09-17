// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/services.dart';

const _webCjkFamily = 'HanziWebCJK';
const platformPrimaryFontFamily = _webCjkFamily;

const platformFontFallback = <String>[
  _webCjkFamily,
  'STKaiti',
  'KaiTi',
  'Noto Serif CJK SC',
];

Future<void> initializePlatformFonts() async {
  try {
    final request = await html.HttpRequest.request(
      'fonts/NotoSansCJKsc-Regular.otf',
      responseType: 'arraybuffer',
    );
    final response = request.response;
    if (response is! ByteBuffer) return;
    final loader = FontLoader(_webCjkFamily)
      ..addFont(Future.value(ByteData.view(response)));
    await loader.load();
  } on Object {
    // Web 字体失败时继续启动，字形组件和系统字体仍会按顺序回退。
  }
}
