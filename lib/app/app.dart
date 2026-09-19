import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/design/app_theme.dart';
import '../core/privacy/privacy_policy.dart';
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
      builder: (context, child) => _PrivacyNoticeGate(
        child: SkinBackdrop(
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.noScaling),
            child: child!,
          ),
        ),
      ),
    );
  }
}

class _PrivacyNoticeGate extends StatefulWidget {
  const _PrivacyNoticeGate({required this.child});

  final Widget child;

  @override
  State<_PrivacyNoticeGate> createState() => _PrivacyNoticeGateState();
}

class _PrivacyNoticeGateState extends State<_PrivacyNoticeGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPrivacyNoticeIfNeeded();
    });
  }

  Future<void> _showPrivacyNoticeIfNeeded() async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(PrivacyPolicy.acceptedKey) == true || !mounted) {
      return;
    }
    final navigatorContext = rootNavigatorKey.currentContext;
    if (navigatorContext == null || !navigatorContext.mounted) return;
    await showDialog<void>(
      context: navigatorContext,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          icon: const Icon(Icons.privacy_tip_outlined),
          title: const Text('隐私政策提示'),
          content: const SingleChildScrollView(
            child: Text(
              '欢迎使用五味字典。应用无需注册账号，不含广告或统计分析 SDK；搜索历史、收藏和设置默认只保存在本机。\n\n'
              '使用前请阅读《五味字典隐私政策》。点击“同意并继续”即表示您已阅读并同意本政策，此提示以后不再显示。',
              style: TextStyle(height: 1.65),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final opened = await launchUrl(
                  Uri.parse(PrivacyPolicy.url),
                  mode: LaunchMode.externalApplication,
                );
                if (!opened) {
                  await Clipboard.setData(
                    const ClipboardData(text: PrivacyPolicy.url),
                  );
                }
              },
              child: const Text('查看完整政策'),
            ),
            FilledButton(
              onPressed: () async {
                await preferences.setBool(PrivacyPolicy.acceptedKey, true);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: const Text('同意并继续'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
