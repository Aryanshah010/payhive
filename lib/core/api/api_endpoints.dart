import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static const bool isPhysicalDevice = false;
  static const String _ipAddress = '192.168.1.102';
  static const int _port = 5050;

  // Base URLs
  static String get _host {
    if (isPhysicalDevice) return _ipAddress;
    if (kIsWeb || Platform.isIOS) return 'localhost';
    if (Platform.isAndroid) return '10.0.2.2';
    return 'localhost';
  }

  static String get serverUrl => 'http://$_host:$_port';
  static String get baseUrl => '$serverUrl/api';
  static String get mediaServerUrl => serverUrl;

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authRequestPasswordReset = '/auth/request-password-reset';
  static String authResetPassword(String token) =>
      '/auth/reset-password/$token';
  static const String profilePicture = '/auth/profilePicture';
  static const String profile = '/auth/me';
  static const String profilePin = '/profile/pin';
  static const String profileVerifyPin = '/profile/verify-pin';

  // Devices
  static const String devices = '/devices';
  static const String devicesPending = '/devices/pending';
  static String deviceAllow(String deviceId) => '/devices/$deviceId/allow';
  static String deviceBlock(String deviceId) => '/devices/$deviceId/block';

  // Transactions
  static const String transactionsPreview = '/transactions/preview';
  static const String transactionsConfirm = '/transactions/confirm';
  static const String transactionsBeneficiary = '/transactions/beneficiary';
  static const String transactionsHistory = '/transactions';
  static String transactionDetail(String txId) => '/transactions/$txId';

  // Flights + Hotels + Bookings + Utility Services
  static const String flights = '/flights';
  static String flightDetail(String flightId) => '/flights/$flightId';
  static const String hotels = '/hotels';
  static String hotelDetail(String hotelId) => '/hotels/$hotelId';
  static const String internetServices = '/internet-services';
  static String internetServiceDetail(String serviceId) =>
      '/internet-services/$serviceId';
  static String internetServicePay(String serviceId) =>
      '/internet-services/$serviceId/pay';
  static const String bookings = '/bookings';
  static String bookingPay(String bookingId) => '/bookings/$bookingId/pay';

  static String profileImage(String filename) =>
      '$mediaServerUrl/profilePicture/$filename';
}
