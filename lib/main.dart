import 'package:flutter/material.dart';
import 'services/store_controller.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const FerragemStoreApp());
}

class FerragemStoreApp extends StatefulWidget {
  const FerragemStoreApp({super.key});

  @override
  State<FerragemStoreApp> createState() => _FerragemStoreAppState();
}

class _FerragemStoreAppState extends State<FerragemStoreApp> {
  final StoreController controller = StoreController();

  @override
  void initState() {
    super.initState();
    controller.load();
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFE8630A);
    return MaterialApp(
      title: 'Ferragem Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: orange,
          primary: orange,
          secondary: Colors.black87,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: orange,
          foregroundColor: Colors.white,
        ),
      ),
      home: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (controller.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return HomeScreen(controller: controller);
        },
      ),
    );
  }
}
