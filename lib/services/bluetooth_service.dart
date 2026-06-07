import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_classic_serial/flutter_bluetooth_classic.dart';

class BluetoothService {
  final FlutterBluetoothClassic _bluetooth = FlutterBluetoothClassic();
  StreamSubscription? _dataSubscription;
  final StreamController<String> _dataController = StreamController.broadcast();
  bool _isConnected = false;
  bool _isConnecting = false; // 🆕 guard flag

  Stream<String> get dataStream => _dataController.stream;
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;

  Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      return await _bluetooth.getPairedDevices();
    } catch (e) {
      return [];
    }
  }

  Future<bool> connect(BluetoothDevice device) async {
    if (_isConnecting) return false;
    _isConnecting = true;

    try {
      await _cleanupSubscription();
      await _bluetooth.disconnect();
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint("CONNECTING TO: ${device.name}");
      final success = await _bluetooth.connect(device.address);

      if (!success) {
        debugPrint("❌ CONNECT FAILED (native)");
        return false;
      }

      // ⏳ انتظر الـ socket يكون ready
      bool verified = false;
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        try {
          await _bluetooth.sendString("PING\n");
          verified = true;
          debugPrint("✅ SOCKET VERIFIED (attempt ${i + 1})");
          break;
        } catch (_) {
          debugPrint("⏳ Waiting for socket... (${i + 1}/10)");
        }
      }

      if (!verified) {
        debugPrint("❌ SOCKET NEVER READY");
        _isConnected = false;
        return false;
      }

      _isConnected = true;

      _dataSubscription = _bluetooth.onDataReceived.listen(
        (BluetoothData data) {
          final text = data.asString().trim();
          debugPrint("📥 DATA: $text");
          _dataController.add(text);
        },
        onError: (e) {
          debugPrint("❌ STREAM ERROR: $e");
          _handleDisconnect();
        },
        onDone: () {
          debugPrint("🔴 SOCKET CLOSED");
          _handleDisconnect();
        },
        cancelOnError: true,
      );

      return true;
    } catch (e) {
      debugPrint("❌ CONNECT ERROR: $e");
      _isConnected = false;
      return false;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> sendText(String text) async {
    if (!_isConnected) {
      debugPrint("❌ NOT CONNECTED");
      return;
    }

    try {
      await _bluetooth.sendString(text);
    } catch (e) {
      debugPrint("❌ SEND FAILED: $e");
      _handleDisconnect();
    }
  }

  Future<void> disconnect() async {
    await _cleanupSubscription();

    try {
      await _bluetooth.disconnect();
    } catch (_) {
      // ignore
    } finally {
      debugPrint("CLEANED UP");
      _handleDisconnect(); // only broadcast when user explicitly disconnects
    }
  }

  /// Cancels the stream subscription silently — no __DISCONNECTED__ event.
  /// Used internally before reconnecting so the UI doesn't react mid-flow.
  Future<void> _cleanupSubscription() async {
    await _dataSubscription?.cancel();
    _dataSubscription = null;
  }

  Future<void> debugPairedDevices() async {
    final devices = await _bluetooth.getPairedDevices();
    debugPrint("📱 PAIRED DEVICES:");
    for (var d in devices) {
      debugPrint("➡️ ${d.name} - ${d.address}");
    }
  }

  void dispose() {
    _dataSubscription?.cancel();
    _dataController.close();
  }

  void _handleDisconnect() {
    if (!_isConnecting) {
      // 🛡️ Don't broadcast mid-reconnect
      debugPrint("🔴 HANDLING DISCONNECT");
      _isConnected = false;
      _dataController.add("__DISCONNECTED__");
    } else {
      _isConnected = false;
    }
  }
}
