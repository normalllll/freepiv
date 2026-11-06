import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

/// One entry of an [AppEntryRow].
@immutable
class AppEntry {
  const AppEntry({required this.icon, required this.label, required this.onPressed, this.count = 0, this.countTone = FrostCountBadgeTone.accent});

  final FrostIconData icon;
  final String label;
  final VoidCallback onPressed;

  /// A count needing attention (downloads on "Me"); none when 0.
  final int count;
  final FrostCountBadgeTone countTone;
}

/// The row of entries the search dropdown, the discover page and "Me" share:
/// a module tile per entry with its icon and label, and a
/// count badge where one is given. With a pointer the tiles keep one fixed
/// width from the start; with touch they share the row equally.
class AppEntryRow extends StatelessWidget {
  const AppEntryRow({required this.entries, super.key});

  /// The width of a tile with a pointer.
  static const pointerTileWidth = 112.0;

  final List<AppEntry> entries;

  @override
  Widget build(BuildContext context) {
    final touch = FrostInputCapability.of(context).touch;
    final tiles = [for (final entry in entries) _EntryTile(entry: entry)];
    if (touch) {
      return Row(
        spacing: FrostGap.related,
        children: [for (final tile in tiles) Expanded(child: tile)],
      );
    }
    return Wrap(
      spacing: FrostGap.related,
      runSpacing: FrostGap.related,
      children: [for (final tile in tiles) SizedBox(width: pointerTileWidth, child: tile)],
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final AppEntry entry;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(FrostRadius.lg);
    return Semantics(
      button: true,
      label: entry.count > 0 ? '${entry.label}, ${entry.count}' : entry.label,
      excludeSemantics: true,
      child: FrostClickSurface(
        shape: FrostClickShape.rounded(radius),
        onTap: entry.onPressed,
        child: FrostSurface(
          role: FrostSurfaceRole.module,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: FrostGap.related, vertical: FrostGap.group),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: FrostGap.inline,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: FrostGap.inline,
                  children: [
                    FrostIcon(entry.icon, size: FrostControlSize.large.iconSize),
                    if (entry.count > 0) FrostCountBadge(count: entry.count, tone: entry.countTone),
                  ],
                ),
                FrostText(entry.label, role: FrostTextRole.footnote, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
