import 'package:equatable/equatable.dart';

class QrScanState extends Equatable {
  final bool isProcessing;
  final String? lastPhone;
  final String? scannedData;

  const QrScanState({
    this.isProcessing = false,
    this.lastPhone,
    this.scannedData,
  });

  factory QrScanState.initial() {
    return const QrScanState();
  }

  QrScanState copyWith({
    bool? isProcessing,
    String? lastPhone,
    String? scannedData,
  }) {
    return QrScanState(
      isProcessing: isProcessing ?? this.isProcessing,
      lastPhone: lastPhone ?? this.lastPhone,
      scannedData: scannedData ?? this.scannedData,
    );
  }

  @override
  List<Object?> get props => [isProcessing, lastPhone, scannedData];
}
