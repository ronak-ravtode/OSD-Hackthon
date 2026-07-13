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
        title: 'SnapSearch',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
          ),
          useMaterial3: true,
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}
