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

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authControllerProvider.notifier)
        .signUp(name: _name.text, email: _email.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    listenForAuthSnackBar(context, ref);
    final state = ref.watch(authControllerProvider);

    return AuthScaffold(
      title: 'Create your account',
      subtitle: 'Two minutes now, a plan built for you next.',
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RepmindTextField(
                key: const ValueKey('sign-up-name'),
                label: 'Name',
                controller: _name,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: AuthValidators.name,
              ),
              const SizedBox(height: 16),
              RepmindTextField(
                key: const ValueKey('sign-up-email'),
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
                key: const ValueKey('sign-up-password'),
                label: 'Password',
                controller: _password,
                hintText:
                    'At least ${AuthValidators.minPasswordLength} characters',
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                validator: AuthValidators.password,
              ),
              AuthFormError(message: visibleAuthError(state)),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Create account',
                isLoading: state.isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 12),
              const GoogleSignInButton(),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  ref.invalidate(authControllerProvider);
                  context.pushReplacement(AppRoutes.signIn);
                },
                child: Text(
                  'Already have an account? Sign in',
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
