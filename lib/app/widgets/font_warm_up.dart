import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freepiv/core/downloads/downloader.dart';

class FontWarmUp extends StatefulWidget {
  const FontWarmUp({required this.child, super.key});

  final Widget child;

  @override
  State<FontWarmUp> createState() => _FontWarmUpState();
}

class _FontWarmUpState extends State<FontWarmUp> with WidgetsBindingObserver {
  bool _warming = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() => _warming = false);
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(downloadManager.sync());
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge;

    return Stack(
      children: [
        widget.child,
        if (_warming)
          Positioned(
            left: 0,
            top: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.01,
                child: Material(
                  color: Colors.transparent,
                  child: Text('freepiv 作品タイトル 日本語 中文 한국어 123 ★ ☆ ❤', style: titleStyle),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
