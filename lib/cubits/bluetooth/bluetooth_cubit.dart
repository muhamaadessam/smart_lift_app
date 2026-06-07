import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bluetooth_classic_serial/flutter_bluetooth_classic.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/bluetooth_service.dart';
import 'bluetooth_state.dart';

class BluetoothCubit extends Cubit<AppBluetoothState> {
  BluetoothCubit(this._service) : super(const AppBluetoothState()) {
    _init();
  }

  final BluetoothService _service;
  StreamSubscription? _dataSub;
  final TextEditingController textController = TextEditingController();

  // ── Initialisation ────────────────────────────────────────────────────────

  void _init() {
    _requestPermissions();

    _dataSub = _service.dataStream.listen((data) {
      debugPrint('==> data is : $data <==');
      if (data == "__DISCONNECTED__") {
        emit(
          state.copyWith(
            isConnected: false,
            connectionStatus: "Connect Bluetooth",
            errorMessage: "Device disconnected",
          ),
        );
        return;
      }
      if (data.trim() == "CHILD") {
        emit(
          state.copyWith(
            receivedData: data,
            showChildAlert: true, // 🆕
          ),
        );
        return;
      } else if (data.trim() == "OVERLOAD") {
        emit(
          state.copyWith(
            receivedData: data,
            showOverloadAlert: true, // 🆕
          ),
        );
        return;
      }
      final list = data.split(',');

      emit(state.copyWith(receivedData: data, dataList: list));
    });
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();
  }

  void clearAlert() {
    emit(state.copyWith(showChildAlert: false, showOverloadAlert: false));
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Fetches paired devices and stores them in state for the selection dialog.
  Future<void> getDevices() async {
    try {
      final devices = await _service.getPairedDevices();
      emit(state.copyWith(devices: devices));
    } catch (_) {
      emit(state.copyWith(errorMessage: 'Error fetching devices'));
    }
  }

  /// Connects to [device] and updates the connection status in state.
  Future<void> connect(BluetoothDevice device) async {
    emit(state.copyWith(connectionStatus: 'Connecting...'));

    final success = await _service.connect(device);

    // فقط emit لو فشل — لو نجح الـ stream هيتكلم لوحده لو اتقطع
    if (!success) {
      emit(
        state.copyWith(
          isConnected: false,
          connectionStatus: 'Connect Bluetooth',
          errorMessage: 'Connection failed',
        ),
      );
    } else {
      emit(
        state.copyWith(
          isConnected: true,
          connectionStatus: 'Connected',
          errorMessage: 'Connected to ${device.name}',
        ),
      );
    }
  }

  /// Disconnects from the current device and resets status.
  Future<void> disconnect() async {
    await _service.disconnect();
    // ✂️ امسح الـ emit من هنا — __DISCONNECTED__ هيعمله تلقائي
  }

  /// Sends a serial [cmd] string; emits an error if not connected.
  Future<void> sendCommand(String cmd) async {
    debugPrint('Sending command: $cmd');
    if (!state.isConnected) {
      emit(state.copyWith(errorMessage: 'Not connected to Bluetooth'));
      return;
    }
    await _service.sendText(cmd);
    textController.clear();
  }

  Future<void> changeFloor(String floor) async {
    emit(state.copyWith(currentFloor: floor));
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  Future<void> close() {
    _dataSub?.cancel();
    _service.dispose();
    textController.dispose();
    return super.close();
  }
}
