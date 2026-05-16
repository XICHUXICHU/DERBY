import 'package:flutter/material.dart';
import '../../core/security/license_manager.dart';
import 'activation_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLicense();
  }

  Future<void> _checkLicense() async {
    // Add artificial delay for visual feedback on fast machines
    await Future.delayed(const Duration(seconds: 1));

    LicenseValidationResult result;
    try {
      result = await LicenseManager.checkCurrentLicense();
    } catch (e) {
      // Si ocurre un error inesperado (ej. fallo de hardware ID en Windows),
      // enviamos al usuario a la pantalla de activación en lugar de quedarnos colgados.
      result = LicenseValidationResult(
        status: LicenseStatus.unregistered,
        message:
            'Error al verificar la licencia: ${e.toString().split('\n').first}',
      );
    }

    if (!mounted) return;

    if (result.status == LicenseStatus.valid) {
      _navigateToHome();
    } else if (result.status == LicenseStatus.offlineGracePeriod) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ??
                'Validación offline. ${result.daysLeftOffline} días restantes.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      _navigateToHome();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ActivationScreen(initialError: result),
        ),
      );
    }
  }

  void _navigateToHome() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.dashboard_customize_rounded,
              size: 80,
              color: Colors.redAccent,
            ),
            SizedBox(height: 24),
            Text(
              'DERBY PRO',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Comprobando licencia...',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(color: Colors.redAccent),
          ],
        ),
      ),
    );
  }
}
