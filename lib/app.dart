import 'package:flutter/material.dart';

class VaultApp extends StatefulWidget {
  const VaultApp({required this.initializeFirebase, super.key});

  final Future<void> Function() initializeFirebase;

  @override
  State<VaultApp> createState() => _VaultAppState();
}

class _VaultAppState extends State<VaultApp> {
  late Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = widget.initializeFirebase();
  }

  void _retry() {
    final nextInitialization = widget.initializeFirebase();
    setState(() {
      _initialization = nextInitialization;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vault Board',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5D4037)),
        scaffoldBackgroundColor: const Color(0xFFFFF8F1),
        useMaterial3: true,
      ),
      home: FutureBuilder<void>(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return InitializationErrorScreen(onRetry: _retry);
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const SplashScreen();
          }
          return const SetupCompleteScreen();
        },
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3E2723), Color(0xFF8D4B32)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.forum_rounded, size: 84, color: Color(0xFFFFCC80)),
              SizedBox(height: 24),
              Text(
                'VAULT BOARD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Messages worth keeping',
                style: TextStyle(color: Color(0xFFFFE0B2), fontSize: 16),
              ),
              SizedBox(height: 36),
              CircularProgressIndicator(color: Color(0xFFFFCC80)),
            ],
          ),
        ),
      ),
    );
  }
}

class InitializationErrorScreen extends StatelessWidget {
  const InitializationErrorScreen({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 72),
                const SizedBox(height: 20),
                Text(
                  'Could not open the vault',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Check your connection and try again. No account data was changed.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SetupCompleteScreen extends StatelessWidget {
  const SetupCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Firebase connected')));
  }
}
