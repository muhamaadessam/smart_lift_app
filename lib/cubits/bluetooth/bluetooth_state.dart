import 'package:flutter_bluetooth_classic_serial/flutter_bluetooth_classic.dart';

class AppBluetoothState {
  final bool isConnected;
  final String connectionStatus;
  final String errorMessage;
  final String receivedData;
  final List<String> dataList;
  final List<BluetoothDevice> devices;
  final String currentFloor;
  final bool showChildAlert;
  final bool showOverloadAlert;
  final bool showConnectionAlert;

  const AppBluetoothState({
    this.isConnected = false,
    this.connectionStatus = 'Connect Bluetooth',
    this.errorMessage = 'No Error Found',
    this.receivedData = '',
    this.dataList = const [],
    this.devices = const [],
    this.currentFloor = '1',
    this.showChildAlert = false,
    this.showOverloadAlert = false,
    this.showConnectionAlert = false,
  });

  AppBluetoothState copyWith({
    bool? isConnected,
    String? connectionStatus,
    String? errorMessage,
    String? receivedData,
    List<String>? dataList,
    List<BluetoothDevice>? devices,
    String? currentFloor,
    bool? showChildAlert,
    bool? showOverloadAlert,
    bool? showConnectionAlert,
  }) {
    return AppBluetoothState(
      isConnected: isConnected ?? this.isConnected,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      receivedData: receivedData ?? this.receivedData,
      dataList: dataList ?? this.dataList,
      devices: devices ?? this.devices,
      currentFloor: currentFloor ?? this.currentFloor,
      showChildAlert: showChildAlert ?? this.showChildAlert,
      showOverloadAlert: showOverloadAlert ?? this.showOverloadAlert,
      showConnectionAlert: showConnectionAlert ?? this.showConnectionAlert,
    );
  }
}
