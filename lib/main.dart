import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubits/bluetooth/bluetooth_cubit.dart';
import 'screens/home_screen.dart';
import 'services/bluetooth_service.dart';

void main() {
  runApp(const LiftApp());
}

class LiftApp extends StatelessWidget {
  const LiftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BluetoothCubit>(
      create: (_) => BluetoothCubit(BluetoothService()),
      child: MaterialApp(
        title: 'Lift Project 2026',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0070C0),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: HomeScreen(),
      ),
    );
  }
}
