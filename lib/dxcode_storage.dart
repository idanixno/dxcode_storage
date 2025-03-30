import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart';

// کش در حافظه برای ذخیره کلیدهای تولید شده (کلید: "$password-$salt")
final Map<String, encrypt.Key> _keyCache = {};

/// تابع top-level برای اجرای PBKDF2 در isolate
Future<Uint8List> _deriveKey(Map<String, dynamic> params) async {
  final String password = params['password'];
  final String salt = params['salt'];
  final saltBytes = base64.decode(salt);
  const int iterations = 10000; // حفظ تعداد تکرار برای امنیت بالا
  final keyDerivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
  keyDerivator.init(Pbkdf2Parameters(saltBytes, iterations, 32));
  return keyDerivator.process(utf8.encode(password));
}

class DXCodeStorage {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // تولید Salt تصادفی 16 بایتی
  String _generateRandomSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64.encode(saltBytes);
  }

  // تولید کلید با استفاده از compute و کش کردن کلیدها
  Future<encrypt.Key> _generateKeyFromPassword(
    String password,
    String salt,
  ) async {
    final cacheKey = '$password-$salt';
    if (_keyCache.containsKey(cacheKey)) {
      return _keyCache[cacheKey]!;
    }
    final keyBytes = await compute(_deriveKey, {
      'password': password,
      'salt': salt,
    });
    final key = encrypt.Key(Uint8List.fromList(keyBytes));
    _keyCache[cacheKey] = key;
    return key;
  }

  // رمزگذاری داده‌ها با AES GCM با IV تصادفی
  Future<String> _encryptData(String plainText, encrypt.Key key) async {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.gcm),
    );
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  // نوشتن داده‌ها به صورت رمزنگاری‌شده با یک لایه امنیتی بالا
  Future<String?> write(String key, String value, String password) async {
    try {
      final salt = _generateRandomSalt(); // تولید salt جدید برای هر رمزگذاری
      final encryptionKey = await _generateKeyFromPassword(password, salt);
      final encryptedValue = await _encryptData(value, encryptionKey);
      final parts = encryptedValue.split(':');
      if (parts.length == 2) {
        final iv = parts[0];
        final encryptedData = parts[1];
        // داده به فرمت 'salt:iv:encryptedData'
        final storedData = '$salt:$iv:$encryptedData';
        await _secureStorage.write(key: key, value: storedData);
        return storedData;
      }
      return null;
    } catch (e) {
      print('Error writing data: $e');
      return null;
    }
  }

  // خواندن و رمزگشایی داده‌ها
  Future<String?> read(String key, String password) async {
    try {
      final encryptedValue = await _secureStorage.read(key: key);
      if (encryptedValue != null) {
        final parts = encryptedValue.split(':');
        if (parts.length == 3) {
          final salt = parts[0];
          final iv = parts[1];
          final encryptedData = parts[2];
          final encryptionKey = await _generateKeyFromPassword(password, salt);
          return await _decryptData(encryptedData, encryptionKey, iv);
        } else {
          throw Exception("Encrypted data format is incorrect");
        }
      }
      return null;
    } catch (e) {
      print('Error reading data: $e');
      return null;
    }
  }

  // رمزگشایی داده‌ها با AES GCM
  Future<String> _decryptData(
    String encryptedText,
    encrypt.Key key,
    String ivBase64,
  ) async {
    final iv = encrypt.IV.fromBase64(ivBase64);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.gcm),
    );
    try {
      return encrypter.decrypt64(encryptedText, iv: iv);
    } catch (e) {
      throw Exception('InvalidCipherTextException: $e');
    }
  }
}
