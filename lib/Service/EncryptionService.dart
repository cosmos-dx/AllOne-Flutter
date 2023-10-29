import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';

class EncryptionService {
  final String userUID;
  late Key key;
  final IV iv;
  late Encrypter encrypter;

  EncryptionService(this.userUID) : iv = IV.fromLength(16) {
    key = _deriveKey(userUID);
    encrypter = _initializeEncrypter();
  }

  Key _deriveKey(String userUID) {
    final keyBytes = utf8.encode(userUID);
    final keyDigest = sha256.convert(keyBytes);
    return Key(Uint8List.fromList(keyDigest.bytes));
  }

  Encrypter _initializeEncrypter() {
    return Encrypter(AES(key));
  }

  String encrypt(String plainText) {
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return encrypted.base64;
  }

  String decrypt(String encryptedText) {
    final encrypted = Encrypted.fromBase64(encryptedText);
    final decrypted = encrypter.decrypt(encrypted, iv: iv);
    return decrypted;
  }
}
