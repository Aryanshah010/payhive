import 'package:equatable/equatable.dart';

class BankEntity extends Equatable {
  final String id;
  final String name;
  final String code;
  final double minTransfer;
  final double maxTransfer;
  final double fee;

  const BankEntity({
    required this.id,
    required this.name,
    required this.code,
    required this.minTransfer,
    required this.maxTransfer,
    required this.fee,
  });

  @override
  List<Object?> get props => [id, name, code, minTransfer, maxTransfer, fee];
}
