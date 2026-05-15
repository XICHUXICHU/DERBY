import 'package:flutter/material.dart';
import 'data/database/app_database.dart';
import 'data/repositories/repositories.dart';
import 'ui/screens/splash_screen.dart';

/// Instancia global de la base de datos.
/// Se inicializa una sola vez al arrancar la app.
late final AppDatabase database;
late final DerbyRepository derbyRepository;
late final PartidoRepository partidoRepository;
late final GalloRepository galloRepository;
late final CompadresRepository compadresRepository;
late final RondaRepository rondaRepository;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar base de datos y repositorios
  database = AppDatabase();
  derbyRepository = DerbyRepository(database);
  partidoRepository = PartidoRepository(database);
  galloRepository = GalloRepository(database);
  compadresRepository = CompadresRepository(database);
  rondaRepository = RondaRepository(database);

  runApp(const Derby2App());
}

class Derby2App extends StatelessWidget {
  const Derby2App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Derby Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF8B0000),
        useMaterial3: true,
        brightness: Brightness.dark,
        cardTheme: const CardThemeData(
          elevation: 2,
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
