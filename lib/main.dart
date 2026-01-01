import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/app/app.dart';
import 'package:payhive/core/services/hive/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  final hiveService = container.read(hiveServiceProvider);
  await hiveService.init();

  runApp(UncontrolledProviderScope(container: container, child: const App()));
}
