import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:payhive/core/constants/hive_table_constants.dart';
import 'package:payhive/features/auth/data/models/auth_hive_model.dart';

final hiveServiceProvider = Provider<HiveService>((ref) {
  final hiveService = HiveService();
  return hiveService;
});

class HiveService {
  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/${HiveTableConstant.dbName}';
    Hive.init(path);
    _registerAdapter();
    await _openBoxes();
  }

  Future<void> _openBoxes() async {
    await Hive.openBox<AuthHiveModel>(HiveTableConstant.authTable);
  }

  void _registerAdapter() {
    if (!Hive.isAdapterRegistered(HiveTableConstant.authTypeId)) {
      Hive.registerAdapter(AuthHiveModelAdapter());
    }
  }

  Future<void> close() async {
    await Hive.close();
  }

  // ==================== Auth Queries ====================
  Box<AuthHiveModel> get _authBox =>
      Hive.box<AuthHiveModel>(HiveTableConstant.authTable);

  Future<AuthHiveModel> registerUser(AuthHiveModel model) async {
    await _authBox.put(model.authId, model);
    return model;
  }

  Future<AuthHiveModel?> login(String phoneNumber, String password) async {
    final users = _authBox.values.where(
      (user) => user.phoneNumber == phoneNumber && user.password == password,
    );

    if (users.isNotEmpty) {
      return users.first;
    }
    return null;
  }

  Future<AuthHiveModel?> getUserByPhoneNumber(String phoneNumber) async {
    final users = _authBox.values.where(
      (user) => user.phoneNumber == phoneNumber,
    );
    if (users.isNotEmpty) {
      return users.first;
    }
    return null;
  }

  bool isPhoneNumberExists(String phoneNumber) {
    final users = _authBox.values.where(
      (user) => user.phoneNumber == phoneNumber,
    );
    return users.isNotEmpty;
  }
}
