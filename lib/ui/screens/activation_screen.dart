import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/security/hardware_id_service.dart';
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
  String? _hardwareId;

  @override
  void initState() {
    super.initState();
    if (widget.initialError != null &&
        widget.initialError!.status != LicenseStatus.unregistered) {
      _errorMessage = widget.initialError!.message;
    }
    _loadHardwareId();
  }

  Future<void> _loadHardwareId() async {
    final id = await HardwareIdService.generateHardwareId();
    if (mounted) setState(() => _hardwareId = id);
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
                    if (_hardwareId != null) ...[  
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'ID de esta computadora',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _hardwareId!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ID copiado al portapapeles'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _hardwareId!,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.copy, size: 14, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Comparte este ID con el administrador\nsi la licencia es para esta PC específica.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
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
