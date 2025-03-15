import 'package:dxcode_storage/dxcode_storage.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DXCodeStorage dxCodeStorage = DXCodeStorage();

  // Save encrypted data
  await dxCodeStorage.write(
      'auth_token', 'user_secure_token', 'bysbig-cahnak-vrv@RVr');

  // Retrieve decrypted data
  await dxCodeStorage.read('auth_token', 'bysbig-cahnak-vrv@RVr');
}
