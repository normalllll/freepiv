import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/fanbox.dart' show FanboxPlan;
import 'package:freepiv/ui/compositions/fanbox_rows.dart';
import 'package:frost_ui/frost_ui.dart';

import 'fanbox_actions.dart' show openFanboxLink;

/// The plan's page on FANBOX, where the reader supports the creator.
Uri fanboxPlanUrl(FanboxPlan plan) => Uri.https('www.fanbox.cc', '/@${plan.creatorId}/plans/${plan.id}');

/// A creator's plan: its title, two lines of its description and its fee;
/// it opens the whole description with the way to support it on FANBOX.
/// [showsCreator] adds the creator's avatar, for lists of several creators.
class FanboxPlanRow extends StatelessWidget {
  const FanboxPlanRow({required this.plan, this.showsCreator = false, super.key});

  final FanboxPlan plan;
  final bool showsCreator;

  @override
  Widget build(BuildContext context) {
    final description = plan.description.trim();
    return FrostListRow(
      title: plan.title,
      contentTitle: true,
      subtitle: description.isEmpty ? null : FrostRowSubtitle(description, content: true, maxLines: 2),
      leading: showsCreator ? FrostLeading.custom(AppFanboxAvatar(user: plan.user)) : null,
      value: context.t.fanbox.monthlyFee(fee: plan.fee),
      accessory: FrostRowAccessory.chevron,
      onPressed: () => unawaited(showFanboxPlan(context, plan)),
    );
  }
}

/// The plan's whole description, with the way to support it on FANBOX.
Future<void> showFanboxPlan(BuildContext context, FanboxPlan plan) {
  final t = context.t.fanbox;
  final description = plan.description.trim();
  return showFrostDialog<void>(
    context: context,
    builder: (dialogContext) => FrostDialog(
      title: plan.title,
      showsCloseButton: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FrostGap.related,
        children: [
          FrostText(t.monthlyFee(fee: plan.fee), role: FrostTextRole.headline),
          FrostText(plan.user.name, content: true, tone: FrostTextTone.secondary),
          if (description.isNotEmpty) FrostText(description, content: true),
        ],
      ),
      actions: [
        FrostDialogAction(
          label: t.supportOnWebsite,
          isDefault: true,
          onPressed: () {
            unawaited(openFanboxLink(context, '${fanboxPlanUrl(plan)}'));
            return true;
          },
        ),
      ],
    ),
  );
}
