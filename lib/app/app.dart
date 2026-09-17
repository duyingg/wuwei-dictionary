import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design/app_theme.dart';
import '../core/widgets/skin_widgets.dart';
import '../features/domain/models.dart';
import 'providers.dart';
import 'router.dart';

class DictionaryApp extends ConsumerStatefulWidget {
  const DictionaryApp({super.key});

  @override
  ConsumerState<DictionaryApp> createState() => _DictionaryAppState();
}

class _DictionaryAppState extends ConsumerState<DictionaryApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings = await ref.read(settingsControllerProvider.future);
      // 首帧出现后按用户选择预热诗词；Repository 会复用同一份内存缓存。
      unawaited(ref
          .read(poetryRepositoryProvider)
          .all(fullLibrary: settings.fullPoetryLibrary));
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider).valueOrNull ??
        const AppSettings();
    return MaterialApp.router(
      title: '五味字典',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(
        settings.fontScale.factor,
        settings.skin,
        settings.importedSkin,
      ),
      routerConfig: appRouter,
      builder: (context, child) => SkinBackdrop(
        child: MediaQuery(
          data:
              MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        ),
      ),
    );
  }
}
