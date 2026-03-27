import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/new_audit_screen.dart';
import 'screens/audit_results_screen.dart';
import 'screens/audit_history_screen.dart';

void main() {
  runApp(const FairForgeApp());
}

final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const NewAuditScreen(),
    ),
    GoRoute(
      path: '/results',
      builder: (context, state) => const AuditResultsScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const AuditHistoryScreen(),
    ),
  ],
);

class FairForgeApp extends StatelessWidget {
  const FairForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FairForge — AI Bias Audit',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        textTheme: GoogleFonts.dmSansTextTheme(
          ThemeData.dark().textTheme,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4BE277),
          secondary: Color(0xFFC0C1FF),
          surface: Color(0xFF121414),
          error: Color(0xFFFFB4AB),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF22C55E);
            }
            return const Color(0xFF0F0F0F);
          }),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          side: const BorderSide(color: Color(0xFF262626), width: 1.5),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF1B1C1C),
          contentTextStyle: GoogleFonts.dmSans(color: const Color(0xFFE5E5E5)),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
