import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../features/domain/models.dart';

/// Parses a data-only skin package. Packages never contain executable code.
abstract final class SkinPackageLoader {
  static const maxPackageBytes = 20 * 1024 * 1024;
  static const maxAssetBytes = 12 * 1024 * 1024;

  static ImportedSkin parse(Uint8List bytes, String fileName) {
    if (bytes.length > maxPackageBytes) {
      throw const FormatException('皮肤包不能超过 20 MB');
    }
    final lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.json')) return _parseJson(bytes);
    if (lowerName.endsWith('.zip') || lowerName.endsWith('.hanzi-skin')) {
      return _parseArchive(bytes);
    }
    throw const FormatException('仅支持 .json、.zip 或 .hanzi-skin 皮肤包');
  }

  static ImportedSkin _parseJson(Uint8List bytes) {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) throw const FormatException('JSON 顶层必须是对象');
    return ImportedSkin.fromJson(Map<String, dynamic>.from(decoded));
  }

  static ImportedSkin _parseArchive(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    final files = <String, ArchiveFile>{};
    for (final file in archive.files) {
      final name = _safePath(file.name);
      if (file.isFile) files[name] = file;
    }
    final manifestEntry = files.entries
        .where((entry) => entry.key.split('/').last == 'skin.json')
        .firstOrNull;
    if (manifestEntry == null) {
      throw const FormatException('皮肤包中缺少 skin.json');
    }
    final manifestBytes = manifestEntry.value.readBytes();
    if (manifestBytes == null) throw const FormatException('无法读取 skin.json');
    final decoded = jsonDecode(utf8.decode(manifestBytes));
    if (decoded is! Map) throw const FormatException('skin.json 顶层必须是对象');
    final manifest = Map<String, dynamic>.from(decoded);
    final manifestFolder = manifestEntry.key.contains('/')
        ? manifestEntry.key.substring(0, manifestEntry.key.lastIndexOf('/') + 1)
        : '';
    final declared = Map<String, dynamic>.from(
      manifest['assets'] as Map? ?? const <String, dynamic>{},
    );
    final embedded = <String, String>{};
    var totalAssetBytes = 0;
    for (final entry in declared.entries) {
      final declaredPath = _safePath(entry.value.toString());
      final path = files.containsKey(declaredPath)
          ? declaredPath
          : _safePath('$manifestFolder$declaredPath');
      final file = files[path];
      if (file == null) throw FormatException('皮肤资源不存在：$path');
      final content = file.readBytes();
      if (content == null) throw FormatException('无法读取皮肤资源：$path');
      if (content.length > maxAssetBytes) {
        throw FormatException('单个皮肤资源不能超过 12 MB：$path');
      }
      totalAssetBytes += content.length;
      if (totalAssetBytes > maxPackageBytes) {
        throw const FormatException('皮肤资源解压后不能超过 20 MB');
      }
      embedded[entry.key] =
          'data:${_mimeType(path)};base64,${base64Encode(content)}';
    }
    manifest['assets'] = embedded;
    return ImportedSkin.fromJson(manifest);
  }

  static String _safePath(String value) {
    final path = value.replaceAll('\\', '/').replaceFirst(RegExp(r'^/+'), '');
    if (path.isEmpty || path.split('/').contains('..')) {
      throw const FormatException('皮肤包包含不安全路径');
    }
    return path;
  }

  static String _mimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    throw FormatException('暂不支持该资源格式：$path');
  }
}
