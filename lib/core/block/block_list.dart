import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';

/// A user whose works and profile are hidden. The name is only for Settings,
/// where the list is shown; matching goes by [id].
@immutable
class BlockedUser {
  const BlockedUser({required this.id, required this.name});

  final int id;
  final String name;

  static BlockedUser? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final name = json['name'];
    return id is int && name is String ? BlockedUser(id: id, name: name) : null;
  }

  Map<String, Object> toJson() => {'id': id, 'name': name};

  @override
  int get hashCode => Object.hash(id, name);

  @override
  bool operator ==(Object other) => other is BlockedUser && other.id == id && other.name == name;
}

/// The tags and users hidden from feeds and lists on this device, shared by
/// every account. A tag matches a work's tag name exactly; a user matches the
/// work's author.
@immutable
class BlockList {
  const BlockList({this.tags = const [], this.users = const []});

  /// The list [json] stores, or null where [json] is not a map. An
  /// entry that cannot be read (a user without a whole-number ID, an empty
  /// tag) is left out and the others are kept.
  static BlockList? fromJson(Object? json) {
    if (json is! Map) return null;
    final tags = json['tags'];
    final users = json['users'];
    return BlockList(
      tags: [
        // A set keeps the first of a tag stored twice, in order.
        ...{
          if (tags is List)
            for (final tag in tags)
              if (tag is String && tag.isNotEmpty) tag,
        },
      ],
      users: [
        if (users is List)
          for (final user in users) ?BlockedUser.fromJson(user),
      ],
    );
  }

  /// [name] as a tag is stored: without spaces around it and without a leading
  /// `#`, which a tag's name never has (the app only shows one). Empty where
  /// nothing is left.
  static String normalizeTag(String name) => name.trim().replaceFirst(RegExp(r'^#+\s*'), '');

  final List<String> tags;
  final List<BlockedUser> users;

  bool get isEmpty => tags.isEmpty && users.isEmpty;

  bool blocksTag(String name) => tags.contains(name);

  bool blocksUser(int id) => users.any((user) => user.id == id);

  bool hidesIllust(Illust illust) => blocksUser(illust.user.id) || illust.tags.any((tag) => blocksTag(tag.name));

  bool hidesNovel(Novel novel) => blocksUser(novel.user.id) || novel.tags.any((tag) => blocksTag(tag.name));

  bool hidesPreview(UserPreview preview) => blocksUser(preview.user.id);

  /// This list with the tag [name] blocked, as [normalizeTag] gives it;
  /// unchanged where it already is or nothing is left of it.
  BlockList withTag(String name) {
    final tag = normalizeTag(name);
    return tag.isEmpty || blocksTag(tag) ? this : BlockList(tags: [...tags, tag], users: users);
  }

  BlockList withoutTag(String name) => BlockList(
    tags: [
      for (final tag in tags)
        if (tag != name) tag,
    ],
    users: users,
  );

  /// This list with [user] blocked, under the name given now.
  BlockList withUser(BlockedUser user) => BlockList(
    tags: tags,
    users: [
      for (final other in users)
        if (other.id != user.id) other,
      user,
    ],
  );

  BlockList withoutUser(int id) => BlockList(
    tags: tags,
    users: [
      for (final user in users)
        if (user.id != id) user,
    ],
  );

  Map<String, Object> toJson() => {
    'tags': tags,
    'users': [for (final user in users) user.toJson()],
  };

  @override
  int get hashCode => Object.hash(Object.hashAll(tags), Object.hashAll(users));

  @override
  bool operator ==(Object other) => other is BlockList && listEquals(other.tags, tags) && listEquals(other.users, users);
}
