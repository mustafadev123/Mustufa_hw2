import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/board_service.dart';
import 'auth_screen.dart';
import 'board_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({required this.authService, super.key});
  final AuthService authService;
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: authService.authStateChanges,
    initialData: authService.currentUser,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.data == null) return AuthScreen(authService: authService);
      return BoardScreen(
        user: snapshot.data!,
        authService: authService,
        boardService: BoardService(),
      );
    },
  );
}
