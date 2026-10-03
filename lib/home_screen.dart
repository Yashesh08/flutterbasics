import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'screens/menu_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return MenuScreen(
      user: user,
      userName: user.name,
      userEmail: user.email,
    );
  }
}
