import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:freepiv/shared/ui/app_dialog.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/energetic_card.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/fanbox.dart';
import 'widgets.dart' show FanboxImageView, fanboxDate, fanboxFee, openFanboxLink;

class _PreviewText extends StatelessWidget {
  const _PreviewText(this.text, {this.lines = 1, this.style});
  final String text;
  final int lines;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) {
    final resolved = style ?? Theme.of(context).textTheme.bodyMedium!;
    if (text.trim().isEmpty && !(Skeletonizer.maybeOf(context)?.enabled ?? false)) return const SizedBox.shrink();
    final painter = TextPainter(
      text: TextSpan(text: 'Ag', style: resolved),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final height = painter.preferredLineHeight * lines;
    painter.dispose();
    if (Skeletonizer.maybeOf(context)?.enabled ?? false) {
      return SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < lines; index++)
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FractionallySizedBox(
                    widthFactor: index == lines - 1 ? .68 : 1,
                    child: Bone(height: height / lines * .6, width: double.infinity),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    return Text(text, maxLines: lines, overflow: TextOverflow.ellipsis, style: resolved);
  }
}

class _Cover extends StatelessWidget {
  const _Cover(this.url, {this.height});
  final String? url;
  final double? height;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      width: double.infinity,
      height: height ?? (constraints.maxWidth * 9 / 16).clamp(160.0, 280.0),
      child: Skeleton.replace(
        width: double.infinity,
        height: double.infinity,
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: url == null || url!.isEmpty ? const Center(child: Icon(Icons.article_outlined, size: 40)) : FanboxImageView(url),
        ),
      ),
    ),
  );
}

double _actionHeight(BuildContext context) => math.max(48, MediaQuery.textScalerOf(context).scale(14) * 1.5 + 16);

Future<void> _showDescription(BuildContext context, String title, String body) => showAppDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    scrollable: true,
    title: Text(title),
    content: SizedBox(width: 560, child: SelectableText(body)),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.t.fanbox.done))],
  ),
);

class FanboxPostCard extends StatelessWidget {
  const FanboxPostCard({required this.post, required this.onTap, required this.onCreator, super.key});
  final FanboxPost post;
  final VoidCallback onTap;
  final VoidCallback onCreator;
  @override
  Widget build(BuildContext context) {
    final t = context.t.fanbox;
    return EnergeticCard(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 680 && MediaQuery.textScalerOf(context).scale(14) <= 20;
          final hasCover = post.coverUrl?.isNotEmpty == true || (Skeletonizer.maybeOf(context)?.enabled ?? false);
          final authorLine = Row(
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: _actionHeight(context)),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: onCreator,
                      child: Text(post.user.name.isEmpty ? post.creatorId : post.user.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  fanboxDate(context, post.publishedDatetime),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          );
          final details = Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide && hasCover) authorLine,
                _PreviewText(post.title, lines: 2, style: Theme.of(context).textTheme.titleLarge),
                if (post.excerpt.trim().isNotEmpty) ...[const SizedBox(height: 6), _PreviewText(post.excerpt, lines: 2)],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(post.isRestricted ? Icons.lock_outline : Icons.lock_open, size: 16),
                    Text(post.feeRequired > 0 ? t.restricted(fee: fanboxFee(context, post.feeRequired)) : t.free, style: Theme.of(context).textTheme.bodySmall),
                    if (!post.isRestricted && post.feeRequired > 0) Text(t.readable, style: Theme.of(context).textTheme.bodySmall),
                    Text('♡ ${post.likeCount} · ${post.commentCount} ${t.comments}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          );
          if (wide && hasCover) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 280, child: _Cover(post.coverUrl, height: 220)),
                Expanded(child: details),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: authorLine),
              if (hasCover) _Cover(post.coverUrl),
              details,
            ],
          );
        },
      ),
    );
  }
}

class FanboxPlanCard extends StatelessWidget {
  const FanboxPlanCard(this.plan, {super.key});
  final FanboxPlan plan;
  @override
  Widget build(BuildContext context) => EnergeticCard(
    onTap: () => _showDescription(context, plan.title, plan.description),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (plan.coverUrl?.isNotEmpty == true || (Skeletonizer.maybeOf(context)?.enabled ?? false)) _Cover(plan.coverUrl),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PreviewText(plan.title, lines: 2, style: Theme.of(context).textTheme.titleLarge),
              _PreviewText(
                context.t.fanbox.monthlyFee(fee: fanboxFee(context, plan.fee)),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: FreepivThemeTokens.of(context).textPrimary),
              ),
              _PreviewText(plan.user.name),
              if (plan.description.trim().isNotEmpty) ...[const SizedBox(height: 8), _PreviewText(plan.description, lines: 2)],
              const SizedBox(height: 12),
              SizedBox(
                height: _actionHeight(context),
                child: OutlinedButton.icon(
                  onPressed: () =>
                      openFanboxLink(context, 'https://www.fanbox.cc/@${Uri.encodeComponent(plan.creatorId)}/plans/${Uri.encodeComponent(plan.id)}'),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(context.t.fanbox.supportOnWebsite, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class FanboxCreatorCard extends StatelessWidget {
  const FanboxCreatorCard(this.creator, {required this.onTap, super.key});
  final FanboxCreator creator;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => EnergeticCard(
    onTap: onTap,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(
      children: [
        SizedBox.square(
          dimension: 56,
          child: ClipOval(child: Skeleton.replace(width: 56, height: 56, child: FanboxImageView(creator.user.iconUrl))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PreviewText(creator.user.name, style: Theme.of(context).textTheme.titleMedium),
              if (creator.description.trim().isNotEmpty) ...[const SizedBox(height: 6), _PreviewText(creator.description, lines: 2)],
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right, size: 20),
      ],
    ),
  );
}

class FanboxTagCard extends StatelessWidget {
  const FanboxTagCard(this.tag, {required this.onTap, super.key});
  final FanboxTag tag;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => EnergeticCard(
    onTap: onTap,
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Expanded(child: _PreviewText('#${tag.name}')),
        const SizedBox(width: 12),
        Text(tag.count?.toString() ?? ''),
      ],
    ),
  );
}

class FanboxNoticeCard extends StatelessWidget {
  const FanboxNoticeCard(this.notice, {this.onPost, this.onCreator, super.key});
  final FanboxNotice notice;
  final VoidCallback? onPost;
  final VoidCallback? onCreator;
  @override
  Widget build(BuildContext context) {
    final t = context.t.fanbox;
    final title = notice.title.isEmpty ? t.unknownNotice : notice.title;
    return EnergeticCard(
      onTap: () => _showDescription(context, title, notice.body),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PreviewText(title, lines: 2, style: Theme.of(context).textTheme.titleMedium),
          _PreviewText('${notice.userName} · ${fanboxDate(context, notice.date)}', style: Theme.of(context).textTheme.bodySmall),
          if (notice.isUnread) _PreviewText(t.newNotice, style: Theme.of(context).textTheme.bodySmall),
          if (notice.body.trim().isNotEmpty) ...[const SizedBox(height: 8), _PreviewText(notice.body, lines: 2)],
          if (onPost != null || onCreator != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: _actionHeight(context),
              child: Row(
                children: [
                  if (onPost != null)
                    Expanded(
                      child: TextButton(
                        onPressed: onPost,
                        child: Text(t.posts, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  if (onCreator != null)
                    Expanded(
                      child: TextButton(
                        onPressed: onCreator,
                        child: Text(t.searchCreators, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
