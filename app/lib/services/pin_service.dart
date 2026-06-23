import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../database/database_helper.dart';
import '../utils/constants.dart';

class PinService {
  static final PinService _instance = PinService._internal();
  factory PinService() => _instance;
  PinService._internal();

  final _db = DatabaseHelper();

  String _hash(String pin) {
    final bytes = utf8.encode(pin + 'so_khach_salt_2025');
    return sha256.convert(bytes).toString();
  }

  Future<bool> hasPin() async {
    final stored = await _db.getSetting(AppConstants.keyPinHash);
    return stored != null && stored.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    await _db.setSetting(AppConstants.keyPinHash, _hash(pin));
  }

  Future<void> removePin() async {
    await _db.setSetting(AppConstants.keyPinHash, '');
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _db.getSetting(AppConstants.keyPinHash);
    if (stored == null || stored.isEmpty) return true;
    return stored == _hash(pin);
  }
}
