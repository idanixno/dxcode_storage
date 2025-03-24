import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart'; // برای استفاده از compute

class DXCodeStorage {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // تابع برای تولید Salt تصادفی منحصر به فرد
  String _generateRandomSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64.encode(saltBytes);
  }

  // تابع برای استفاده از PBKDF2 برای تولید کلید از رمز عبور و Salt
  Future<encrypt.Key> _generateKeyFromPassword(
    String password,
    String salt,
  ) async {
    final saltBytes = base64.decode(salt);
    final keyDerivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    keyDerivator.init(Pbkdf2Parameters(saltBytes, 100000, 32));

    final keyBytes = keyDerivator.process(utf8.encode(password));
    return encrypt.Key(Uint8List.fromList(keyBytes));
  }

  // تابع PBKDF2 برای تبدیل به کلید
  static String _pbkdf2(List<dynamic> params) {
    String password = params[0];
    List<int> salt = params[1];
    int iterations = params[2];

    var bytes = utf8.encode(password);
    var hmac = Hmac(sha256, Uint8List.fromList(bytes));
    var result = hmac.convert(salt);

    // استفاده از تعداد زیادی تکرار در PBKDF2
    for (int i = 0; i < iterations - 1; i++) {
      result = hmac.convert(result.bytes);
    }

    return result.toString();
  }

  // رمزگذاری داده‌ها با AES GCM
  Future<String> _encryptData(String plainText, encrypt.Key key) async {
    final iv = encrypt.IV.fromSecureRandom(16); // IV تصادفی برای هر رمزگذاری
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.gcm),
    );

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    final result = '${iv.base64}:${encrypted.base64}';
    return result;
  }

  Future<void> write(String key, String value, String password) async {
    try {
      final salt = _generateRandomSalt(); // Salt تصادفی برای هر کاربر
      final encryptionKey = await _generateKeyFromPassword(password, salt);

      final encryptedValue = await _encryptData(value, encryptionKey);

      // ساخت داده به فرمت 'salt:iv:encryptedData'
      final parts = encryptedValue.split(':');
      if (parts.length == 2) {
        final iv = parts[0];
        final encryptedData = parts[1];

        // ذخیره داده‌ها به صورت 'salt:iv:encryptedData'
        final storedData = '$salt:$iv:$encryptedData';
        await _secureStorage.write(key: key, value: storedData);
      } else {}
    } catch (e) {
      print('Error writing data: $e');
    }
  }

  Future<String?> read(String key, String password) async {
    try {
      final encryptedValue = await _secureStorage.read(key: key);
      if (encryptedValue != null) {
        // چک کردن و جدا کردن داده‌ها به فرمت 'salt:iv:encryptedData'
        final parts = encryptedValue.split(':');
        if (parts.length == 3) {
          final salt = parts[0]; // Salt
          final iv = parts[1]; // IV
          final encryptedData = parts[2]; // داده رمزگذاری شده

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

  // تغییرات در `_decryptData` برای پردازش IV به طور جداگانه
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
      final decrypted = encrypter.decrypt64(encryptedText, iv: iv);
      return decrypted;
    } catch (e) {
      throw Exception('InvalidCipherTextException: $e');
    }
  }
}
