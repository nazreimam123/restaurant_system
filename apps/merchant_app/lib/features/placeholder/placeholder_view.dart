import 'package:flutter/material.dart';
import 'package:app_widgets/app_widgets.dart';

/// Minimal safe placeholder screen used for merchant route registration of unimplemented screens.
/// NOTE (AGENTS.md rule 11 & 42):
/// For screens not implemented yet, do NOT generate fake completed features.
/// Use only minimal safe placeholders when navigation infrastructure requires them.
class PlaceholderView extends StatelessWidget {
  final String title;
  final String routePath;

  const PlaceholderView({
    super.key,
    required this.title,
    required this.routePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AppEmptyState(
        icon: Icons.dashboard_customize_rounded,
        title: title,
        message:
            'This screen ($routePath) is queued for subsequent implementation phases.',
      ),
    );
  }
}
