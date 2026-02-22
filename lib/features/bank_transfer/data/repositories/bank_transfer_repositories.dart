import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/entities/transaction_entity.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/services/connectivity/network_info.dart';
import 'package:payhive/features/bank_transfer/data/datasources/bank_transfer_datasource.dart';
import 'package:payhive/features/bank_transfer/data/datasources/remote/bank_transfer_remote_datasource.dart';
import 'package:payhive/features/bank_transfer/domain/entity/bank_entity.dart';
import 'package:payhive/features/bank_transfer/domain/repositories/bank_transfer_repositories.dart';

final bankTransferRepositoryProvider = Provider<IBankTransferRepository>((ref) {
  final networkInfo = ref.read(networkInfoProvider);
  final remoteDatasource = ref.read(bankTransferRemoteDatasourceProvider);
  return BankTransferRepository(
    networkInfo: networkInfo,
    remoteDatasource: remoteDatasource,
  );
});

class BankTransferRepository implements IBankTransferRepository {
  final NetworkInfo _networkInfo;
  final IBankTransferRemoteDatasource _remoteDatasource;

  BankTransferRepository({
    required NetworkInfo networkInfo,
    required IBankTransferRemoteDatasource remoteDatasource,
  }) : _networkInfo = networkInfo,
       _remoteDatasource = remoteDatasource;

  @override
  Future<Either<Failure, List<BankEntity>>> getBanks() async {
    if (await _networkInfo.isConnected) {
      try {
        final models = await _remoteDatasource.getBanks();
        return Right(models.map((model) => model.toEntity()).toList());
      } on DioException catch (e) {
        return Left(_mapDioFailure(e));
      } catch (e) {
        return Left(ApiFalilure(message: e.toString()));
      }
    }
    return const Left(ApiFalilure(message: 'No Internet connection'));
  }

  @override
  Future<Either<Failure, PreviewEntity>> previewBankTransfer({
    required String bankName,
    required String accountNumber,
    required double amount,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final model = await _remoteDatasource.previewBankTransfer(
          bankName: bankName,
          accountNumber: accountNumber,
          amount: amount,
        );
        return Right(model.toEntity());
      } on DioException catch (e) {
        return Left(_mapDioFailure(e));
      } catch (e) {
        return Left(ApiFalilure(message: e.toString()));
      }
    }
    return const Left(ApiFalilure(message: 'No Internet connection'));
  }

  @override
  Future<Either<Failure, ReceiptEntity>> confirmBankTransfer({
    required String bankName,
    required String accountNumber,
    required double amount,
    required String pin,
    String? idempotencyKey,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final model = await _remoteDatasource.confirmBankTransfer(
          bankName: bankName,
          accountNumber: accountNumber,
          amount: amount,
          pin: pin,
          idempotencyKey: idempotencyKey,
        );
        return Right(model.toEntity());
      } on DioException catch (e) {
        return Left(_mapDioFailure(e));
      } catch (e) {
        return Left(ApiFalilure(message: e.toString()));
      }
    }
    return const Left(ApiFalilure(message: 'No Internet connection'));
  }

  Failure _mapDioFailure(DioException e) {
    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;
    final message = responseData is Map && responseData['message'] != null
        ? responseData['message'].toString()
        : (e.message ?? 'Request failed');

    if (statusCode == 423) {
      final remainingMs = _extractRemainingMs(e.response?.data);
      return PinLockoutFailure(
        message: message,
        remainingMs: remainingMs,
        statusCode: statusCode,
      );
    }

    return ApiFalilure(message: message, statusCode: statusCode);
  }

  int _extractRemainingMs(dynamic data) {
    if (data is Map) {
      final dataField = data['data'];
      if (dataField is Map && dataField['remainingMs'] is num) {
        return (dataField['remainingMs'] as num).toInt();
      }
      if (data['remainingMs'] is num) {
        return (data['remainingMs'] as num).toInt();
      }
    }
    return 0;
  }
}
