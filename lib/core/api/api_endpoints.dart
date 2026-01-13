class ApiEndpoints {
  ApiEndpoints._();

  // Base URL 
  // static const String baseUrl = 'http://10.0.2.2:3000/api/v1'; //andriod emulator
  static const String baseUrl = 'http://localhost:5050/api';  //ios simulator

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String auth='/auth';
  static const String authLogin='/auth/login';
  static const String authRegister = '/auth/register';

}