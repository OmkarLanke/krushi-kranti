import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // ✅ REQUIRED: Provider Package

import 'core/constants/app_colors.dart';
import 'core/constants/app_routes.dart';
import 'core/providers/locale_provider.dart'; // ✅ Import Provider
import 'l10n/app_localizations.dart';

void main() {
  runApp(
    // ✅ WRAP APP WITH PROVIDER
    ChangeNotifierProvider(
      create: (context) => LocaleProvider()..loadSavedLocale(),
      child: const KrushiKrantiApp(),
    ),
  );
}

class KrushiKrantiApp extends StatelessWidget {
  const KrushiKrantiApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ LISTEN TO LANGUAGE CHANGES
    final provider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'Krushi Kranti',
      debugShowCheckedModeBanner: false,
      
      // --- THEME ---
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.brandGreen),
        textTheme: GoogleFonts.poppinsTextTheme(), 
      ),

      // --- DYNAMIC LOCALIZATION ---
      locale: provider.locale, // ✅ This switches the language instantly!
      
      supportedLocales: const [
        Locale('en'), 
        Locale('hi'), 
        Locale('mr'), 
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // --- NAVIGATION ---
      initialRoute: AppRoutes.splash, 
      routes: AppRoutes.routes,
    );
  }
}