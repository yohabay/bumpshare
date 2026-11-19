import 'dart:async';
import 'package:flutter/services.dart';
class BumpShareNfcService {
  BumpShareNfcService._();
  static final BumpShareNfcService instance = BumpShareNfcService._();
  static const MethodChannel _channel = MethodChannel('bumpshare_nfc');
  final StreamController<void> _sharingComplete =
      StreamController<void>.broadcast();
  Stream<void> get onSharingComplete => _sharingComplete.stream;
  void registerNativeHandlers() {
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'onSharingComplete' && !_sharingComplete.isClosed) {
        _sharingComplete.add(null);
      }
    });
  }
  Future<bool> startSharing(String url) => _call('startSharing', url);
  Future<bool> stopSharing() => _call('stopSharing');
  Future<bool> isNfcAvailable() => _call('isNfcAvailable');
  Future<bool> isNfcEnabled() => _call('isNfcEnabled');
  Future<bool> isHceSupported() => _call('isHceSupported');
  Future<bool> openNfcSettings() => _call('openNfcSettings');
  Future<bool> _call(String method, [Object? argument]) async {
    try {
      return await _channel
              .invokeMethod<bool>(method, argument)
              .timeout(const Duration(seconds: 2)) ??
          false;
    } on TimeoutException {
      return false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
  void dispose() {
    if (!_sharingComplete.isClosed) _sharingComplete.close();
  }
}
