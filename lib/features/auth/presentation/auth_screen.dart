import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/widgets/crescendo_logo.dart';
import '../../../shared/widgets/gold_button.dart';

/// Create an account or log in. The app switches to the main tabs once logged in.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _join = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final session = AppScope.read(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_join) {
        await session.register(_username.text, _password.text);
      } else {
        await session.login(_username.text, _password.text);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: CrSpace.sm),
        child: Text(text, style: CrText.body(size: 14, weight: FontWeight.w600, color: CrColors.text2)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.7, -0.8),
            radius: 1.3,
            colors: [Color(0x38E9B54A), Color(0x00E9B54A)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(CrSpace.xl),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              const CrescendoLogo(),
              const SizedBox(height: CrSpace.xxxl),
              Text(_join ? 'FREE FOREVER · 10 SECONDS' : 'WELCOME BACK', style: CrText.eyebrow()),
              const SizedBox(height: CrSpace.md),
              Text.rich(
                TextSpan(style: CrText.display(42), children: [
                  if (_join) ...[
                    const TextSpan(text: 'Claim your '),
                    TextSpan(
                      text: 'taste.',
                      style: CrText.display(42, weight: FontWeight.w400, style: FontStyle.italic, color: CrColors.gold2),
                    ),
                  ] else
                    const TextSpan(text: 'Log in'),
                ]),
              ),
              const SizedBox(height: CrSpace.md),
              Text(
                _join
                    ? 'Rate every track you love (and the ones you don\'t). Your taste profile builds itself.'
                    : 'Good to have you back.',
                style: CrText.body(size: 16, color: CrColors.text2),
              ),
              if (_join) ...[
                const SizedBox(height: CrSpace.xl),
                Container(
                  padding: const EdgeInsets.all(CrSpace.lg),
                  decoration: BoxDecoration(
                    color: CrColors.goldSoft,
                    borderRadius: BorderRadius.circular(CrRadius.sm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final perk in const [
                        'Rate albums song by song, in half-stars',
                        'Get your Taste DNA: genres, habits, favorites',
                        'See your match % with every listener',
                      ])
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text('✦  $perk', style: CrText.body(size: 14, color: CrColors.gold2)),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: CrSpace.xl),
              _label('Username'),
              TextField(
                controller: _username,
                style: CrText.body(),
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                decoration: InputDecoration(hintText: _join ? 'letters, numbers, dots, underscores' : null),
              ),
              const SizedBox(height: CrSpace.lg),
              _label('Password'),
              TextField(
                controller: _password,
                style: CrText.body(),
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: [_join ? AutofillHints.newPassword : AutofillHints.password],
                decoration: InputDecoration(hintText: _join ? 'at least 8 characters' : null),
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: CrSpace.md),
                Text(_error!, style: CrText.body(size: 14, weight: FontWeight.w600, color: CrColors.danger)),
              ],
              const SizedBox(height: CrSpace.xl),
              GoldButton(
                label: _busy ? 'One moment…' : (_join ? 'Create my account' : 'Log in'),
                onPressed: _busy ? null : _submit,
              ),
              const SizedBox(height: CrSpace.lg),
              Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() {
                    _join = !_join;
                    _error = null;
                  }),
                  child: Padding(
                    padding: const EdgeInsets.all(CrSpace.sm),
                    child: Text.rich(TextSpan(
                      style: CrText.body(size: 15, color: CrColors.muted),
                      children: [
                        TextSpan(text: _join ? 'Already have an account? ' : 'New here? '),
                        TextSpan(
                          text: _join ? 'Log in' : 'Create an account',
                          style: CrText.body(size: 15, weight: FontWeight.w600, color: CrColors.gold2),
                        ),
                      ],
                    )),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
