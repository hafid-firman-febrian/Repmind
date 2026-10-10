import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/repmind_decorations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/primary_button.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: RepmindDecorations.limeHero(colors),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -40,
                        bottom: -30,
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 280,
                          color: colors.onLime.withValues(alpha: 0.08),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  color: colors.violet,
                                  size: 26,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'REPMIND',
                                  style: text.title.copyWith(
                                    color: colors.onLime,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              'YOUR AI\nFITNESS\nCOACH',
                              style: text.display.copyWith(
                                color: colors.onLime,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Personalized workout plans and a coach that knows your goals.',
                              style: text.body.copyWith(
                                color: colors.onLime.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Get started',
                onPressed: () => context.push(AppRoutes.signUp),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.push(AppRoutes.signIn),
                child: Text(
                  'I already have an account',
                  style: text.subtitle.copyWith(color: colors.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
