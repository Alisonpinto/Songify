import 'package:flutter/material.dart';

class LoginSignupButton extends StatelessWidget {

  final Color? color;
  final void Function()? onPressed;

  const LoginSignupButton({super.key, this.color, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 4,
      ),
      child: const Text("Log In or Sign Up", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
