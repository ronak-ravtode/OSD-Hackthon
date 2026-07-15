import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/database/database_helper.dart';
import 'data/repositories/local_screenshot_repository.dart';
import 'data/services/ocr_service.dart';
import 'presentation/providers/screenshot_provider.dart';
import 'presentation/screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SnapSearchApp());
}

class SnapSearchApp extends StatelessWidget {
  const SnapSearchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ScreenshotProvider>(
          create: (_) => ScreenshotProvider(
            LocalScreenshotRepository(
              DatabaseHelper.instance,
              OcrService(),
            ),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Trace',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF4285F4),
            secondary: Colors.white,
          ),
          useMaterial3: true,
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}
