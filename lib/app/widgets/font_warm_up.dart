import 'package:freepiv/i18n/strings.g.dart';
import 'package:flutter/material.dart';

class FontWarmUp extends StatefulWidget {
  const FontWarmUp({required this.child, super.key});

  final Widget child;

  @override
  State<FontWarmUp> createState() => _FontWarmUpState();
}

class _FontWarmUpState extends State<FontWarmUp> {
  int? _warmedConfiguration;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final textTheme = Theme.of(context).textTheme;
    final baseStyle = textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
    final configuration = Object.hash(baseStyle.fontFamily, Object.hashAll(baseStyle.fontFamilyFallback ?? const []), Localizations.localeOf(context));

    if (_warmedConfiguration == configuration) {
      return;
    }

    _warmedConfiguration = configuration;
    _warmUp(baseStyle);
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _warmUp(TextStyle baseStyle) {
    final t = context.t;
    final samples = [
      ..._samples,
      _FontWarmUpSample(
        locale: Localizations.localeOf(context),
        text: [t.navigation.home, t.navigation.search, t.navigation.settings, t.navigation.activity, t.navigation.me].join(' '),
      ),
    ];
    for (final weight in _fontWeights) {
      final style = baseStyle.copyWith(fontWeight: weight);

      for (final sample in samples) {
        final painter = TextPainter(
          text: TextSpan(text: sample.text, style: style),
          textDirection: TextDirection.ltr,
          locale: sample.locale,
          maxLines: 1,
        )..layout(maxWidth: 2048);
        painter.dispose();
      }
    }
  }
}

const _fontWeights = [FontWeight.w400, FontWeight.w700];

const _samples = <_FontWarmUpSample>[
  _FontWarmUpSample(locale: Locale('en', 'US'), text: 'freepiv Search Settings Proxy Address Port 0123456789'),
  _FontWarmUpSample(locale: Locale('en', 'US'), text: '★ ☆ ♥ ✓ × … — () [] {} / : @ #'),
];

class _FontWarmUpSample {
  const _FontWarmUpSample({required this.locale, required this.text});

  final Locale locale;
  final String text;
}
