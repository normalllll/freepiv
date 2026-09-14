import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'image.dart';
import 'package:freepiv/shared/widgets/energetic_card.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixivision.dart';
import 'navigation.dart';

class PixivisionBlock extends StatelessWidget {
  const PixivisionBlock({required this.block, required this.imageRatios, required this.onLink, super.key});
  final ArticleBlock block;
  final Map<String, double> imageRatios;
  final ValueChanged<String> onLink;
  @override
  Widget build(BuildContext context) {
    if (!pixivisionBlockHasContent(block)) return const SizedBox.shrink();
    final theme = Theme.of(context).textTheme;
    if (block.kind == BlockKind.pixivWork && block.works.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final work in block.works) ...[
            _ArticleTextLink(label: work.title, style: theme.titleLarge, onTap: () => onLink(work.url)),
            if (work.userId != null) ...[const SizedBox(height: 8), _AuthorLink(work: work, source: block.html, images: block.images, onLink: onLink)],
            if (work.preview case final preview?) ...[
              const SizedBox(height: 8),
              _ArticleLink(
                onTap: () => onLink(work.url),
                builder: (_) => PixivisionImage(url: preview, aspectRatio: imageRatios[preview]!, fit: BoxFit.contain),
              ),
            ],
          ],
        ],
      );
    }
    final style = switch (block.kind) {
      BlockKind.heading => (block.headingLevel ?? 2) <= 2 ? theme.headlineSmall : theme.titleLarge,
      BlockKind.code => theme.bodyMedium?.copyWith(fontFamily: 'monospace'),
      BlockKind.question => theme.titleMedium,
      _ => theme.bodyLarge?.copyWith(height: 1.6),
    };
    final fragment = html.parseFragment(block.html);
    final table = fragment.querySelector('table');
    final rows =
        table
            ?.querySelectorAll('tr')
            .map((row) => row.children.where((cell) => cell.localName == 'td' || cell.localName == 'th').toList())
            .where((row) => row.isNotEmpty)
            .toList() ??
        <List<dom.Element>>[];
    final columns = rows.fold<int>(0, (count, row) => row.length > count ? row.length : count);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (block.kind == BlockKind.divider)
          const Divider()
        else if (rows.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: [
                for (final row in rows)
                  TableRow(
                    children: [
                      for (final cell in row)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: _RichText(
                            html: cell.innerHtml,
                            fallback: cell.text,
                            style: cell.localName == 'th' ? theme.titleSmall : theme.bodyMedium,
                            onLink: onLink,
                          ),
                        ),
                      for (var i = row.length; i < columns; i++) const SizedBox.shrink(),
                    ],
                  ),
              ],
            ),
          )
        else if (block.text.trim().isNotEmpty)
          _RichText(html: block.html, fallback: block.text, style: style, onLink: onLink),
        for (final image in block.images)
          Padding(
            padding: EdgeInsets.only(top: block.text.trim().isEmpty ? 0 : 8),
            child: _ArticleLink(
              onTap: () => showDialog<void>(
                context: context,
                builder: (context) => Dialog.fullscreen(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 5,
                          child: Center(
                            child: PixivisionImage(url: image.url, fit: BoxFit.contain),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton.filledTonal(
                          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              builder: (_) => PixivisionImage(url: image.url, aspectRatio: imageRatios[image.url]!, fit: BoxFit.contain),
            ),
          ),
        for (final work in block.works)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ArticleTextLink(label: work.title, style: theme.titleLarge, onTap: () => onLink(work.url)),
                if (work.userId != null) ...[const SizedBox(height: 8), _AuthorLink(work: work, source: block.html, images: block.images, onLink: onLink)],
              ],
            ),
          ),
        for (final embed in block.embeds)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: EnergeticCard(
              onTap: () => openPixivisionLink(context, embed.url),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.play_circle_outline),
                  const SizedBox(width: 12),
                  Expanded(child: Text(embed.title ?? Uri.parse(embed.url).host)),
                  const Icon(Icons.open_in_new, size: 18),
                ],
              ),
            ),
          ),
        if (block.kind == BlockKind.articleCard || block.text.trim().isEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final link in block.links)
                TextButton.icon(
                  onPressed: () => onLink(link.url),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(link.title.isEmpty ? context.t.pixivision.openOriginal : link.title),
                ),
            ],
          ),
        if (block.kind == BlockKind.unknown && block.text.isEmpty && block.images.isEmpty && block.embeds.isEmpty) Text(context.t.pixivision.unsupported),
      ],
    );
  }
}

class _RichText extends StatefulWidget {
  const _RichText({required this.html, required this.fallback, required this.style, required this.onLink});
  final String html;
  final String fallback;
  final TextStyle? style;
  final ValueChanged<String> onLink;
  @override
  State<_RichText> createState() => _RichTextState();
}

class _RichTextState extends State<_RichText> {
  final _recognizers = <TapGestureRecognizer>[];
  void _clear() {
    for (final item in _recognizers) {
      item.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _clear();
    final spans = <InlineSpan>[];
    var pendingBreak = false;
    var lineStart = true;
    void write(String value, TextStyle? style, TapGestureRecognizer? recognizer, {bool verbatim = false}) {
      var text = verbatim ? value : value.replaceAll(RegExp(r'[\t\r\n ]+'), ' ');
      if (lineStart || pendingBreak) text = text.trimLeft();
      if (text.isEmpty) return;
      if (pendingBreak && spans.isNotEmpty) spans.add(const TextSpan(text: '\n'));
      pendingBreak = false;
      lineStart = false;
      spans.add(TextSpan(text: text, style: style, recognizer: recognizer));
    }

    void visit(dom.Node node, TextStyle? style, TapGestureRecognizer? inherited, bool verbatim) {
      if (node is dom.Text) {
        write(node.text, style, inherited, verbatim: verbatim);
        return;
      }
      if (node is! dom.Element) return;
      final tag = node.localName;
      if (['img', 'iframe', 'video', 'audio', 'script', 'style'].contains(tag)) return;
      if (tag == 'br') {
        pendingBreak = true;
        return;
      }
      final isBlock = ['p', 'div', 'li', 'blockquote', 'h1', 'h2', 'h3', 'h4', 'pre'].contains(tag);
      if (isBlock) pendingBreak = spans.isNotEmpty;
      var recognizer = inherited;
      final link = node.attributes['href'];
      if (tag == 'a' && link != null) {
        recognizer = TapGestureRecognizer()..onTap = () => widget.onLink(link);
        _recognizers.add(recognizer);
      }
      final childStyle = (style ?? const TextStyle()).merge(
        TextStyle(
          fontWeight: ['b', 'strong'].contains(tag) ? FontWeight.bold : null,
          fontStyle: ['i', 'em'].contains(tag) ? FontStyle.italic : null,
          color: recognizer != null ? Theme.of(context).colorScheme.primary : null,
          decoration: recognizer != null ? TextDecoration.underline : null,
        ),
      );
      if (tag == 'li') write('• ', childStyle, recognizer);
      for (final child in node.nodes) {
        visit(child, childStyle, recognizer, verbatim || tag == 'pre');
      }
      if (isBlock) pendingBreak = true;
    }

    final nodes = html.parseFragment(widget.html).nodes;
    if (nodes.isEmpty) {
      write(widget.fallback.trim(), widget.style, null);
    } else {
      for (final node in nodes) {
        visit(node, widget.style, null, false);
      }
    }
    return SelectableText.rich(TextSpan(style: widget.style, children: spans));
  }
}

bool pixivisionBlockHasContent(ArticleBlock block) =>
    block.text.trim().isNotEmpty ||
    block.images.isNotEmpty ||
    block.works.isNotEmpty ||
    block.embeds.isNotEmpty ||
    block.kind == BlockKind.divider ||
    block.kind == BlockKind.unknown;

class _AuthorLink extends StatelessWidget {
  const _AuthorLink({required this.work, required this.source, required this.images, required this.onLink});
  final FeaturedWork work;
  final String source;
  final List<ArticleImage> images;
  final ValueChanged<String> onLink;

  @override
  Widget build(BuildContext context) {
    final id = work.userId!;
    var name = work.userName?.trim() ?? '';
    String? avatar;
    // Match both author anchors: the avatar link may precede the named link.
    for (final anchor in html.parseFragment(source).querySelectorAll('a[href]')) {
      final uri = Uri.tryParse(anchor.attributes['href']!);
      if (uri == null || !['www.pixiv.net', 'pixiv.net'].contains(uri.host)) continue;
      final parts = uri.pathSegments;
      final userIndex = parts.indexOf('users');
      final candidate = userIndex >= 0 && parts.length > userIndex + 1 ? parts[userIndex + 1] : uri.queryParameters['id'];
      if (candidate != id.toString() || (userIndex < 0 && !uri.path.endsWith('/member.php'))) continue;
      if (name.isEmpty) name = anchor.text.trim();
      final imageUrl = anchor.querySelector('img')?.attributes['src'];
      if (imageUrl != null && images.any((image) => image.url == imageUrl)) avatar = imageUrl;
    }
    final label = name.isEmpty ? context.t.pixivision.userId(id: id.toString()) : name;
    final colors = Theme.of(context).colorScheme;
    final avatarFallback = ColoredBox(color: colors.surfaceContainerHighest, child: const Icon(Icons.person_outline, size: 20));
    return Align(
      alignment: Alignment.centerLeft,
      child: _ArticleLink(
        onTap: () => onLink('https://www.pixiv.net/users/$id'),
        builder: (hovered) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: IgnorePointer(
                child: SizedBox.square(
                  dimension: 32,
                  child: ClipOval(
                    child: avatar != null ? PixivisionImage(url: avatar, errorWidget: avatarFallback) : avatarFallback,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: hovered ? colors.primary : colors.onSurface)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleTextLink extends StatelessWidget {
  const _ArticleTextLink({required this.label, required this.style, required this.onTap});
  final String label;
  final TextStyle? style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: _ArticleLink(
        onTap: onTap,
        builder: (hovered) => Text(label, style: style?.copyWith(color: hovered ? colors.primary : colors.onSurface)),
      ),
    );
  }
}

class _ArticleLink extends StatefulWidget {
  const _ArticleLink({required this.onTap, required this.builder});
  final VoidCallback onTap;
  final Widget Function(bool hovered) builder;

  @override
  State<_ArticleLink> createState() => _ArticleLinkState();
}

class _ArticleLinkState extends State<_ArticleLink> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) => Semantics(
    link: true,
    child: DecoratedBox(
      position: DecorationPosition.foreground,
      // Paint focus without adding padding or shifting the article layout.
      decoration: BoxDecoration(border: Border.all(color: _focused ? Theme.of(context).colorScheme.primary : Colors.transparent)),
      child: InkWell(
        onTap: widget.onTap,
        mouseCursor: SystemMouseCursors.click,
        onHover: (value) => setState(() => _hovered = value),
        onFocusChange: (value) => setState(() => _focused = value),
        splashFactory: NoSplash.splashFactory,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        child: widget.builder(_hovered),
      ),
    ),
  );
}
