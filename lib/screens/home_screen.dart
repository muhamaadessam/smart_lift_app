import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lift_app/core/design/app_colors.dart';
import 'package:lift_app/core/design/app_text_styles.dart';

import '../cubits/bluetooth/bluetooth_cubit.dart';
import '../cubits/bluetooth/bluetooth_state.dart';

// ── Entry point ──────────────────────────────────────────────────────────────
// HomeScreen is StatelessWidget. The TextEditingController for the number
// input is isolated in _NumberInputField (a tiny StatefulWidget) so the
// rest of the screen never needs setState.
class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  // ── Device picker dialog ─────────────────────────────────────────────────

  Future<void> _showBluetoothDevices(BuildContext context) async {
    final cubit = context.read<BluetoothCubit>();

    await cubit.getDevices();
    if (!context.mounted) return;

    final devices = context.read<BluetoothCubit>().state.devices;

    if (devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No paired Bluetooth devices found')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Select Bluetooth Device',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                // Devices list
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: devices.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final device = devices[index];

                      return InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          cubit.connect(device);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.bluetooth, color: AppColors.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      device.name.isEmpty
                                          ? "Unknown Device"
                                          : device.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      device.address,
                                      style: TextStyle(
                                        color: Colors.grey.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // Close button
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Lift Control Panel',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: BlocConsumer<BluetoothCubit, AppBluetoothState>(
          listenWhen: (prev, curr) =>
              (curr.showChildAlert && !prev.showChildAlert) ||
              (curr.showOverloadAlert && !prev.showOverloadAlert) ||
              (curr.showConnectionAlert && !prev.showConnectionAlert),
          listener: (context, state) {
            bool showAlert = false;
            String alertMessage = "";
            if (state.showChildAlert) {
              showAlert = true;
              alertMessage = "تم اكتشاف طفل!";
            } else if (state.showOverloadAlert) {
              showAlert = true;
              alertMessage = "تم تجاوز الحمل!";
            } else if (state.showConnectionAlert) {
              showAlert = true;
              alertMessage = state.errorMessage;
            }

            if (showAlert) {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('⚠️ تحذير'),
                  content: Text(alertMessage),
                  actions: [
                    TextButton(
                      onPressed: () {
                        context.read<BluetoothCubit>().clearAlert();
                        Navigator.pop(context);
                      },
                      child: const Text('حسناً'),
                    ),
                  ],
                ),
              );
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _bluetoothCard(context, state),

                  const SizedBox(height: 16),

                  _controlCard(context, state),

                  const SizedBox(height: 16),

                  _statusCard(state),

                  if (state.receivedData.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _dataCard(state),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  // ── Sections ──────────────────────────────────────────────────────────────

  Widget _bluetoothCard(BuildContext context, AppBluetoothState state) {
    final cubit = context.read<BluetoothCubit>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.bluetooth, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                state.connectionStatus,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ElevatedButton(
            onPressed: () => _showBluetoothDevices(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Select Device", style: AppTextStyles.button),
          ),

          const SizedBox(height: 8),

          TextButton(
            onPressed: state.isConnected ? cubit.disconnect : null,
            child: const Text(
              "Disconnect",
              style: TextStyle(color: Colors.redAccent, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlCard(BuildContext context, AppBluetoothState state) {
    final cubit = context.read<BluetoothCubit>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          TextFormField(
            controller: cubit.textController,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            onChanged: cubit.changeFloor,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a floor';
              }
              if (int.parse(value) < 0) {
                return 'Please enter a positive floor';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: "Enter floor",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _btn("Move", () {
                  if (_formKey.currentState!.validate()) {
                    cubit.sendCommand('F${state.currentFloor}');
                  }
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _btn("Open", () {
                  if (_formKey.currentState!.validate()) {
                    cubit.sendCommand('O${state.currentFloor}');
                  }
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _btn("Close", () {
                  if (_formKey.currentState!.validate()) {
                    cubit.sendCommand('C${state.currentFloor}');
                  }
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusCard(AppBluetoothState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Text(
        state.errorMessage,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
    );
  }

  Widget _dataCard(AppBluetoothState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Received Data", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            state.receivedData,
            style: const TextStyle(
              color: Color(0xFF00FF88),
              fontFamily: "monospace",
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(String text, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(text, style: AppTextStyles.button),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
    );
  }
}
