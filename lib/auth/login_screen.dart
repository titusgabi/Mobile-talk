import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flip_talk3/controllers/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(hintText: 'Email'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(hintText: 'Password'),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                await authController.login(
                  _emailController.text.trim(),
                  _passwordController.text.trim(),
                );
              },
              child: Text('Login'),
            ),
            TextButton(
              onPressed: () {
                // Navigate to registration
              },
              child: Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}