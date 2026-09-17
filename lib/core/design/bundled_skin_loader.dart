import 'package:flutter/services.dart';

import '../../features/domain/models.dart';
import 'skin_package_loader.dart';

abstract final class BundledSkinLoader {
  static const names = <String>{
    '丹阙鎏金',
    '华章正红',
    '鎏金墨玉·锦纹',
    '青篁晨露',
    '松月夜读',
  };

  // Keep this list explicit: skins added to UI设计工作区 later must be imported
  // manually rather than silently becoming application defaults.
  static const assetPaths = <String>[
    'assets/skins/bundled/丹阙鎏金.hanzi-skin',
    'assets/skins/bundled/华章正红.hanzi-skin',
    'assets/skins/bundled/鎏金墨玉-锦纹.hanzi-skin',
    'assets/skins/bundled/青篁晨露.hanzi-skin',
    'assets/skins/bundled/松月夜读.hanzi-skin',
  ];

  static Future<List<ImportedSkin>> loadAll() async {
    final skins = <ImportedSkin>[];
    for (final path in assetPaths) {
      final data = await rootBundle.load(path);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      skins.add(SkinPackageLoader.parse(bytes, path.split('/').last));
    }
    return skins;
  }
}
