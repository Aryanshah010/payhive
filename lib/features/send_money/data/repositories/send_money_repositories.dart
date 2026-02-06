import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payhive/core/error/failures.dart';
import 'package:payhive/core/services/connectivity/network_info.dart';
import 'package:payhive/features/send_money/data/datasources/remote/send_money_remote_datasource.dart';
import 'package:payhive/features/send_money/data/datasources/send_money_datasource.dart';
import 'package:payhive/features/send_money/domain/entity/send_money_entity.dart';
import 'package:payhive/features/send_money/domain/repositories/send_money_repositories.dart';

final sendMoneyRepositoryProvider = Provider<ISendMoneyRepository>((ref) {
  final networkInfo = ref.read(networkInfoProvider);
  final remoteDatasource = ref.read(sendMoneyRemoteDatasourceProvider);
  return SendMoneyRepository(
    networkInfo: networkInfo,
    remoteDatasource: remoteDatasource,
  );
});

class SendMoneyRepository implements ISendMoneyRepository {
  final NetworkInfo _networkInfo;
  final ISendMoneyRemoteDatasource _remoteDatasource;

  SendMoneyRepository({
    required NetworkInfo networkInfo,
    required ISendMoneyRemoteDatasource remoteDatasource,
  }) : _networkInfo = networkInfo,
       _remoteDatasource = remoteDatasource;

  @override
  Future<Either<Failure, PreviewEntity>> previewTransfer({
    required String toPhoneNumber,
    required double amount,
    String? remark,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final model = await _remoteDatasource.previewTransfer(
          toPhoneNumber: toPhoneNumber,
          amount: amount,
          remark: remark,
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
  Future<Either<Failure, ReceiptEntity>> confirmTransfer({
    required String toPhoneNumber,
    required double amount,
    required String pin,
    String? remark,
    String? idempotencyKey,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final model = await _remoteDatasource.confirmTransfer(
          toPhoneNumber: toPhoneNumber,
          amount: amount,
          pin: pin,
          remark: remark,
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

  @override
  Future<Either<Failure, RecipientEntity>> lookupBeneficiary({
    required String phoneNumber,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final model = await _remoteDatasource.lookupBeneficiary(
          phoneNumber: phoneNumber,
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
