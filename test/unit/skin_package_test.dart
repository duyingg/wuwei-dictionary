import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuwei_dictionary/core/design/app_theme.dart';
import 'package:wuwei_dictionary/core/design/skin_package_loader.dart';
import 'package:wuwei_dictionary/features/domain/models.dart';

void main() {
  test('ZIP 皮肤包可解析背景和资源图标', () {
    final manifest = jsonEncode({
      'name': '纹样测试',
      'colors': {
        'background': '#F4F7F3',
        'surface': '#FFFFFF',
        'primary': '#315C4D',
        'secondary': '#9A6A45',
        'text': '#202723',
        'border': '#D3DDD7',
      },
      'appearance': {
        'backgroundAsset': 'paper',
        'backgroundFit': 'cover',
      },
      'assets': {
        'paper': 'assets/paper.webp',
        'home': 'icons/home.png',
      },
      'icons': {'nav.home': 'asset:home'},
    });
    final archive = Archive()
      ..addFile(ArchiveFile(
          'theme/skin.json', manifest.length, utf8.encode(manifest)))
      ..addFile(ArchiveFile('theme/assets/paper.webp', 4, [1, 2, 3, 4]))
      ..addFile(ArchiveFile('theme/icons/home.png', 4, [5, 6, 7, 8]));
    final bytes = ZipEncoder().encodeBytes(archive);

    final skin = SkinPackageLoader.parse(bytes, 'theme.hanzi-skin');
    final spec = AppSkinRegistry.of(AppSkin.imported, skin);
    expect(skin.assets, hasLength(2));
    expect(spec.backgroundAsset, startsWith('data:image/webp;base64,'));
    expect(spec.iconAsset('nav.home'), startsWith('data:image/png;base64,'));
  });

  test('皮肤包拒绝路径穿越', () {
    final archive = Archive()
      ..addFile(ArchiveFile('skin.json', 2, utf8.encode('{}')))
      ..addFile(ArchiveFile('../escape.png', 1, [1]));
    final bytes = ZipEncoder().encodeBytes(archive);
    expect(
      () => SkinPackageLoader.parse(bytes, 'unsafe.zip'),
      throwsFormatException,
    );
  });
}
