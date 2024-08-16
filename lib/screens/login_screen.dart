import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLogin = true;

  void _switchAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        if (_isLogin) {
          await authService.signInWithEmailAndPassword(_email, _password);
        } else {
          await authService.registerWithEmailAndPassword(_email, _password);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification email sent. Please check your inbox.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Register')),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                SizedBox(height: 40),
                Lottie.asset(
                  'assets/animations/women-gif.json',
                  height: 300,
                ),
                SizedBox(height: 10),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: theme.inputDecorationTheme.labelStyle,
                  ),
                  style: theme.textTheme.bodyText1,
                  validator: (value) => value!.isEmpty ? 'Enter an email' : null,
                  onSaved: (value) => _email = value!,
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: theme.inputDecorationTheme.labelStyle,
                  ),
                  style: theme.textTheme.bodyText1,
                  obscureText: true,
                  validator: (value) => value!.length < 6 ? 'Enter a password 6+ chars long' : null,
                  onSaved: (value) => _password = value!,
                ),
                SizedBox(height: 24),
                authService.isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _submit,
                  child: Text(_isLogin ? 'Login' : 'Register'),
                  style: theme.elevatedButtonTheme.style,
                ),
                SizedBox(height: 8),
                TextButton(
                  onPressed: _switchAuthMode,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: _isLogin
                              ? 'Don\'t have an account? '
                              : 'Already have an account? ',
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: _isLogin ? 'Register' : 'Login',
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                             // fontStyle: FontStyle.italic
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}