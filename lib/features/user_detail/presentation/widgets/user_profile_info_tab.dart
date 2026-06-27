import 'package:flutter/material.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';
import 'package:url_launcher/url_launcher.dart';

class UserProfileInfoBody extends StatelessWidget {
  const UserProfileInfoBody({required this.detail, required this.physics, this.sliverHeader, super.key});

  final UserDetailResult detail;
  final ScrollPhysics? physics;
  final Widget? sliverHeader;

  @override
  Widget build(BuildContext context) {
    final entries = _profileEntries(detail.profile, t);

    return CustomScrollView(
      physics: physics,
      slivers: [
        ?sliverHeader,
        if (entries.isEmpty)
          _ProfileViewportLockSliver(
            centerInViewport: true,
            child: EmptyContent(icon: Icons.info_outline, title: context.t.user.empty.profile),
          )
        else
          _ProfileViewportLockSliver(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var index = 0; index < entries.length; index++) ...[if (index > 0) const SizedBox(height: 8), _ProfileInfoTile(entry: entries[index])],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProfileViewportLockSliver extends StatelessWidget {
  const _ProfileViewportLockSliver({required this.child, this.centerInViewport = false});

  final Widget child;
  final bool centerInViewport;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final viewportExtent = constraints.viewportMainAxisExtent;

        return SliverToBoxAdapter(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: viewportExtent),
            child: centerInViewport ? SizedBox(height: viewportExtent, child: child) : child,
          ),
        );
      },
    );
  }
}

class _ProfileEntry {
  const _ProfileEntry({required this.icon, required this.label, required this.value, this.url});

  final IconData icon;
  final String label;
  final String value;
  final String? url;
}

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({required this.entry});

  final _ProfileEntry entry;

  @override
  Widget build(BuildContext context) {
    final url = entry.url;

    return EnergeticCard(
      onTap: url == null ? null : () => _openUrl(url),
      child: ListTile(
        leading: Icon(entry.icon),
        title: Text(entry.label),
        subtitle: Text(entry.value),
        trailing: url == null ? null : IconButton(tooltip: t.user.profile.openLink, icon: const Icon(Icons.open_in_new), onPressed: () => _openUrl(url)),
      ),
    );
  }
}

List<_ProfileEntry> _profileEntries(UserProfile profile, Translations translations) {
  final birthday = _birthday(profile);

  return [
    if (birthday != null) _ProfileEntry(icon: Icons.cake_outlined, label: translations.user.profile.birthday, value: birthday),
    if (_hasValue(profile.region)) _ProfileEntry(icon: Icons.public_outlined, label: translations.user.profile.region, value: profile.region),
    if (_hasValue(profile.job)) _ProfileEntry(icon: Icons.work_outline, label: translations.user.profile.job, value: profile.job),
    if (_hasValue(profile.webpage))
      _ProfileEntry(icon: Icons.link_outlined, label: translations.user.profile.webpage, value: profile.webpage!, url: profile.webpage),
    if (_hasValue(profile.twitterUrl))
      _ProfileEntry(icon: Icons.alternate_email, label: translations.user.profile.twitter, value: profile.twitterUrl!, url: profile.twitterUrl),
    if (_hasValue(profile.pawooUrl))
      _ProfileEntry(icon: Icons.chat_bubble_outline, label: translations.user.profile.pawoo, value: profile.pawooUrl!, url: profile.pawooUrl),
  ];
}

String? _birthday(UserProfile profile) {
  if (_hasValue(profile.birth) && profile.birth != '0000-00-00') {
    return profile.birth;
  }

  final parts = <String>[];
  if (profile.birthYear > 0) {
    parts.add('${profile.birthYear}');
  }
  if (_hasValue(profile.birthDay)) {
    parts.add(profile.birthDay);
  }

  if (parts.isEmpty) {
    return null;
  }

  return parts.join('-');
}

bool _hasValue(String? value) {
  if (value == null) {
    return false;
  }

  final trimmed = value.trim();
  return trimmed.isNotEmpty && trimmed != '0';
}

Future<void> _openUrl(String value) async {
  final uri = _uriFor(value);
  if (uri == null) {
    return;
  }

  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Uri? _uriFor(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final parsed = Uri.tryParse(trimmed);
  if (parsed == null) {
    return null;
  }

  if (parsed.hasScheme) {
    return parsed;
  }

  return Uri.tryParse('https://$trimmed');
}
