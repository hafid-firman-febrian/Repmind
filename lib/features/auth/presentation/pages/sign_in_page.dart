import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/repmind_text_field.dart';
import '../../application/services/auth_validators.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_form_error.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_snack_bar.dart';
import '../widgets/google_sign_in_button.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authControllerProvider.notifier)
        .signIn(email: _email.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    listenForAuthSnackBar(context, ref);
    final state = ref.watch(authControllerProvider);

    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to continue with your plan.',
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RepmindTextField(
                key: const ValueKey('sign-in-email'),
                label: 'Email',
                controller: _email,
                hintText: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: AuthValidators.email,
              ),
              const SizedBox(height: 16),
              RepmindTextField(
                key: const ValueKey('sign-in-password'),
                label: 'Password',
                controller: _password,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                autofillHints: const [AutofillHints.password],
                validator: AuthValidators.signInPassword,
              ),
              AuthFormError(message: visibleAuthError(state)),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Sign in',
                isLoading: state.isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 12),
              const GoogleSignInButton(),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  ref.invalidate(authControllerProvider);
                  context.pushReplacement(AppRoutes.signUp);
                },
                child: Text(
                  'New here? Create an account',
                  style: context.textStyles.body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
