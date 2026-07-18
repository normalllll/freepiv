import 'package:flutter/material.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/shared/widgets/error.dart';

class UserSliverFillBody extends StatelessWidget {
  const UserSliverFillBody({required this.child, required this.physics, this.sliverHeader, super.key});

  final Widget child;
  final ScrollPhysics? physics;
  final Widget? sliverHeader;

  @override
  Widget build(BuildContext context) {
    return DataSliverFillBody(physics: physics, sliverHeader: sliverHeader, child: child);
  }
}

class UserErrorBody extends StatelessWidget {
  const UserErrorBody({required this.error, required this.onRetry, required this.physics, this.sliverHeader, super.key});

  final Object error;
  final VoidCallback onRetry;
  final ScrollPhysics? physics;
  final Widget? sliverHeader;

  @override
  Widget build(BuildContext context) {
    return UserSliverFillBody(
      physics: physics,
      sliverHeader: sliverHeader,
      child: ErrorContent.fromError(error: error, onRetry: onRetry),
    );
  }
}

class UserEmptyBody extends StatelessWidget {
  const UserEmptyBody({required this.icon, required this.title, required this.physics, this.message, this.sliverHeader, super.key});

  final IconData icon;
  final String title;
  final String? message;
  final ScrollPhysics? physics;
  final Widget? sliverHeader;

  @override
  Widget build(BuildContext context) {
    return UserSliverFillBody(
      physics: physics,
      sliverHeader: sliverHeader,
      child: EmptyContent(icon: icon, title: title, message: message),
    );
  }
}
