import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/garden_provider.dart';
import 'providers/alert_provider.dart';
import 'providers/device_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/locale_provider.dart';
import 'theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'routes/app_router.dart';

class SmartGardenApp extends StatefulWidget {
  const SmartGardenApp({super.key});

  @override
  State<SmartGardenApp> createState() => _SmartGardenAppState();
}

class _SmartGardenAppState extends State<SmartGardenApp> {
  late final _router = AppRouter.router(
    Provider.of<AuthProvider>(context, listen: false),
  );

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    // Watch auth to trigger rebuilds on auth state changes 
    context.watch<AuthProvider>();

    return MultiProvider(
      providers: [
        ChangeNotifierProxyProvider<AuthProvider, GardenProvider>(
          create: (_) => GardenProvider(),
          update: (_, auth, prev) => prev!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AlertProvider>(
          create: (_) => AlertProvider(),
          update: (_, auth, prev) => prev!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, DeviceProvider>(
          create: (_) => DeviceProvider(),
          update: (_, auth, prev) => prev!..updateAuth(auth),
        ),
        // Settings and Locale providers already watch Auth if needed or are independent
      ],
      child: MaterialApp.router(
        title: 'Smart Garden',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: settingsProvider.themeMode,
        locale: localeProvider.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: _router,
      ),
    );
  }
}
