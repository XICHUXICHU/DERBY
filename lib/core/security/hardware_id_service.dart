import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';

class HardwareIdService {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  /// Gets a highly resilient, unique hardware identifier for the current machine.
  /// Combines Motherboard UUID / System UUID with the OS name, to prevent 
  /// spoofing and ensure licenses are bound down to the physical motherboard.
  static Future<String> generateHardwareId() async {
    String platformUid = '';
    
    try {
      if (Platform.isWindows) {
        platformUid = await _getWindowsMotherboardUuid();
      } else if (Platform.isMacOS) {
        platformUid = await _getMacOsUuid();
      } else if (Platform.isLinux) {
        platformUid = await _getLinuxUuid();
      } else {
        // Fallback for mobile or web
        platformUid = await _getGenericDeviceId();
      }
    } catch (e) {
      // If fetching deep OS metrics fails, fallback to device info plugin
      try {
        platformUid = await _getGenericDeviceId();
      } catch (_) {
        // Last resort: use a platform-based constant so the app never crashes
        platformUid = 'fallback_${Platform.operatingSystem}';
      }
    }

    // Ensure we don't end up with an empty string
    if (platformUid.trim().isEmpty) {
      try {
        platformUid = await _getGenericDeviceId();
      } catch (_) {
        platformUid = 'fallback_${Platform.operatingSystem}';
      }
    }

    // Append OS type to avoid collisions
    final rawId = '${Platform.operatingSystem}_$platformUid'.trim().toLowerCase();
    
    // Hash the ID so it's uniform and we don't send raw UUIDs over the network
    final bytes = utf8.encode(rawId);
    final digest = sha256.convert(bytes);
    
    return digest.toString();
  }

  /// Extracts Windows Motherboard UUID via PowerShell (wmic is deprecated in Windows 11)
  static Future<String> _getWindowsMotherboardUuid() async {
    // Use PowerShell to get the System UUID — works on Windows 10 and Windows 11
    final result = await Process.run('powershell', [
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      '(Get-WmiObject -Class Win32_ComputerSystemProduct).UUID',
    ]);
    if (result.exitCode == 0) {
      final output = result.stdout.toString().trim();
      if (output.isNotEmpty && output != 'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF') {
        return output;
      }
    }
    throw Exception('Failed to get Windows UUID via PowerShell');
  }

  /// Extracts macOS Hardware UUID via ioreg
  static Future<String> _getMacOsUuid() async {
    final result = await Process.run('ioreg', ['-rd1', '-c', 'IOPlatformExpertDevice']);
    if (result.exitCode == 0) {
      final lines = result.stdout.toString().split('\n');
      for (var line in lines) {
        if (line.contains('IOPlatformUUID')) {
          final parts = line.split('=');
          if (parts.length > 1) {
            return parts[1].replaceAll('"', '').trim();
          }
        }
      }
    }
    throw Exception('Failed to get macOS UUID');
  }

  /// Extracts Linux Machine ID
  static Future<String> _getLinuxUuid() async {
    final file = File('/etc/machine-id');
    if (await file.exists()) {
      return await file.readAsString();
    }
    throw Exception('Failed to get Linux UUID');
  }

  /// Fallback using device_info_plus
  static Future<String> _getGenericDeviceId() async {
    if (Platform.isWindows) {
      final info = await _deviceInfoPlugin.windowsInfo;
      return '${info.computerName}_${info.numberOfCores}_${info.systemMemoryInMegabytes}';
    } else if (Platform.isMacOS) {
      final info = await _deviceInfoPlugin.macOsInfo;
      return '${info.computerName}_${info.model}_${info.memorySize}';
    }
    return DateTime.now().millisecondsSinceEpoch.toString(); // Worst case scenario
  }
}
