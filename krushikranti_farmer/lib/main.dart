import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_routes.dart';
import 'core/providers/locale_provider.dart';
import 'core/onboarding/onboarding_controller.dart';
import 'core/services/deep_link_service.dart';
import 'l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => LocaleProvider()..loadSavedLocale(),
      child: ChangeNotifierProvider(
        create: (_) => OnboardingController(),
        child: const KrushiKrantiApp(),
      ),
    ),
  );
}

class KrushiKrantiApp extends StatefulWidget {
  const KrushiKrantiApp({super.key});

  @override
  State<KrushiKrantiApp> createState() => _KrushiKrantiAppState();
}

class _KrushiKrantiAppState extends State<KrushiKrantiApp> {
  final DeepLinkService _deepLinkService = DeepLinkService();

  @override
  void initState() {
    super.initState();
    // Initialize deep link handling
    _deepLinkService.init();
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return MaterialApp(
          onGenerateTitle: (context) =>
              AppLocalizations.of(context)?.appTitle ?? 'Krushi Kranti',
          debugShowCheckedModeBanner: false,
          
          // Use the global navigator key for deep link navigation
          navigatorKey: DeepLinkService.navigatorKey,
          
          // --- THEME ---
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.brandGreen),
            textTheme: GoogleFonts.poppinsTextTheme(), 
          ),

          // --- DYNAMIC LOCALIZATION ---
          locale: localeProvider.locale,
          localeResolutionCallback: (locale, supportedLocales) {
            if (locale == null) {
              return const Locale('en');
            }
            if (locale.languageCode == 'en' ||
                locale.languageCode == 'hi' ||
                locale.languageCode == 'mr') {
              return Locale(locale.languageCode);
            }
            if (kDebugMode) {
              debugPrint(
                'l10n: Unsupported locale $locale, falling back to English',
              );
            }
            return const Locale('en');
          },
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
      },
    );
  }
}
