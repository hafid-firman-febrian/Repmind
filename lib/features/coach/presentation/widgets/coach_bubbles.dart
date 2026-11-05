import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../../../core/theme/repmind_colors.dart';
import '../../../../core/theme/repmind_radius.dart';
import '../../../../core/theme/repmind_text.dart';
import '../../../../core/theme/theme_context.dart';
import 'streaming_dots.dart';

const _bubbleWidthFactor = 0.86;

BorderRadius _bubbleRadius({required bool fromUser}) {
  const round = Radius.circular(RepmindRadius.card);
  const tail = Radius.circular(RepmindRadius.badge);
  return BorderRadius.only(
    topLeft: round,
    topRight: round,
    bottomLeft: fromUser ? round : tail,
    bottomRight: fromUser ? tail : round,
  );
}

class UserBubble extends StatelessWidget {
  const UserBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth * _bubbleWidthFactor,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.lime,
              borderRadius: _bubbleRadius(fromUser: true),
              border: Border.all(color: colors.limeEdge),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(text, style: context.textStyles.body),
            ),
          ),
        ),
      ),
    );
  }
}

class CoachBubble extends StatelessWidget {
  const CoachBubble({
    super.key,
    required this.text,
    this.streaming = false,
    this.footer,
  });

  final String text;
  final bool streaming;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final footer = this.footer;

    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth * _bubbleWidthFactor,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: _bubbleRadius(fromUser: false),
              border: Border.all(color: colors.line),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (text.isNotEmpty)
                    MarkdownBody(
                      data: text,
                      styleSheet: _markdownStyle(colors, context.textStyles),
                      imageBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  if (streaming) ...[
                    if (text.isNotEmpty) const SizedBox(height: 8),
                    const StreamingDots(),
                  ],
                  if (footer != null) ...[const SizedBox(height: 10), footer],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ReplyFailure extends StatelessWidget {
  const ReplyFailure({
    super.key,
    required this.message,
    required this.onRetry,
    this.onChangeModel,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onChangeModel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;
    final style = TextButton.styleFrom(
      foregroundColor: colors.violet,
      textStyle: text.body.copyWith(fontWeight: FontWeight.w700),
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: text.bodySmall.copyWith(
              color: colors.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: onRetry,
                style: style,
                child: const Text('Try again'),
              ),
              if (onChangeModel != null)
                TextButton(
                  onPressed: onChangeModel,
                  style: style,
                  child: const Text('Change model'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

MarkdownStyleSheet _markdownStyle(RepmindColors colors, RepmindText text) {
  final body = text.body;
  final heading = text.subtitle;
  final block = BoxDecoration(
    color: colors.surfaceSunken,
    borderRadius: BorderRadius.circular(RepmindRadius.badge),
  );

  return MarkdownStyleSheet(
    p: body,
    a: body,
    strong: body.copyWith(fontWeight: FontWeight.w800),
    em: body.copyWith(fontStyle: FontStyle.italic),
    del: body.copyWith(decoration: TextDecoration.lineThrough),
    h1: heading,
    h2: heading,
    h3: heading,
    h4: heading,
    h5: heading,
    h6: heading,
    listBullet: body,
    code: body.copyWith(backgroundColor: colors.surfaceSunken),
    codeblockDecoration: block,
    blockquote: body.copyWith(color: colors.muted),
    blockquoteDecoration: block,
    tableHead: body.copyWith(fontWeight: FontWeight.w700),
    tableBody: body,
    blockSpacing: 8,
  );
}
