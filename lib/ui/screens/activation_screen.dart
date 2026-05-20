import 'package:flutter/material.dart';
import '../../core/security/license_manager.dart';
import 'home_screen.dart';

class ActivationScreen extends StatefulWidget {
  final LicenseValidationResult? initialError;

  const ActivationScreen({super.key, this.initialError});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialError != null &&
        widget.initialError!.status != LicenseStatus.unregistered) {
      _errorMessage = widget.initialError!.message;
    }
  }

  Future<void> _activate() async {
    final raw = _codeController.text.trim();
    // Los códigos RSA contienen '.' y son case-sensitive (base64 con mayúsculas/minúsculas)
    // Los códigos Firestore son todo mayúsculas
    final isRsa = raw.contains('.') && raw.toUpperCase().startsWith('DERBY-');
    final code = isRsa ? raw : raw.toUpperCase().replaceAll(' ', '');

    if (code.isEmpty) return;

    // Validar formato: DERB-TYPE-XXXX-XXXX-XXXX-XXXX  O  DERBY-{base64}.{base64}
    final firestoreFormat = RegExp(
        r'^DERB-[A-Z0-9]+-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$');
    final rsaFormat = RegExp(r'^DERBY-[A-Za-z0-9+/=]+\.[A-Za-z0-9+/=]+$');
    if (!firestoreFormat.hasMatch(code) && !rsaFormat.hasMatch(code)) {
      setState(() {
        _errorMessage = 'Formato de código inválido.\n'
            'Copia el código exactamente como te lo compartieron.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await LicenseManager.activateLicense(code);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.status == LicenseStatus.valid) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      setState(() {
        _errorMessage = result.message ?? 'Código de licencia inválido.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.security_rounded,
                      size: 64,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'DERBY PRO',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const Text(
                      'Verificación de Licencia',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Clave del Producto',
                        hintText: 'Ej. DERB-1M-XXXX-XXXX-XXXX-XXXX',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.key),
                      ),
                      onSubmitted: (_) => _activate(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _activate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'ACTIVAR SOFTWARE',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Para adquirir una licencia o soporte técnico,\npor favor contacte al administrador.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
