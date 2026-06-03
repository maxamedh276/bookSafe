import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  //static const String _defaultBaseUrl = 'http://localhost:5000/api';
  //  static const String _defaultBaseUrl = 'http://10.150.141.126:5000/api';
   static const String _defaultBaseUrl = 'http://18.118.145.124:5000/api';
  final Dio _dio;
  final _storage = const FlutterSecureStorage();

  ApiService() : _dio = Dio(
          BaseOptions(
            // Local backend only
            baseUrl: _defaultBaseUrl,
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
          ),
        ) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (e, handler) async {
        // Auto-retry once on connection error (Render cold start)
        final isConnectionError = e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout;

        final alreadyRetried = e.requestOptions.extra['retried'] == true;

        if (isConnectionError && !alreadyRetried) {
          e.requestOptions.extra['retried'] = true;
          await Future.delayed(const Duration(seconds: 3));
          try {
            final response = await _dio.fetch(e.requestOptions);
            return handler.resolve(response);
          } catch (retryError) {
            return handler.next(e);
          }
        }
        return handler.next(e);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }

  String getErrorMessage(Object error) => formatUserError(error);

  /// Human-readable message for any error (API, parsing, network).
  String formatUserError(Object error) {
    if (error is DioException) {
      return _formatDioError(error);
    }
    if (error is FormatException) {
      return 'Xogta laga helay way khaldan tahay. Fadlan isku day mar kale.';
    }
    if (error is TypeError) {
      return 'Xogta server-ka ma uusan u iman qaab sax ah. Hubi backend-ka.';
    }
    if (error is NoSuchMethodError) {
      return 'Cilad xog- akhris ah ayaa dhacday. Fadlan hot restart samee ama isku day mar kale.';
    }

    final raw = error.toString();
    final lower = raw.toLowerCase();
    if (lower.contains('nosuchmethoderror') || lower.contains('no such method')) {
      return 'Cilad xog- akhris ah ayaa dhacday. Fadlan isku day mar kale.';
    }
    if (lower.contains('formatexception') || lower.contains('invalid date')) {
      return 'Taariikhda xogta way khaldan tahay.';
    }
    if (lower.contains('socketexception') || lower.contains('connection')) {
      return 'Server-ka lama gaari karo. Hubi internet-kaaga ama backend-ka.';
    }
    if (raw.startsWith('Exception: ') && raw.length < 200) {
      return raw.replaceFirst('Exception: ', '');
    }
    if (raw.length > 160) {
      return 'Khalad ayaa dhacay. Fadlan isku day mar kale.';
    }
    return raw;
  }

  String _formatDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString();
      if (message != null && message.isNotEmpty) {
        return _humanizeMessage(message);
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Server-ku way dib u dhacaysaa. Fadlan isku day mar kale.';
      case DioExceptionType.connectionError:
        return 'Server-ka lama gaari karo. Hubi internet-kaaga ama backend-ka inuu socdo.';
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        if (status == 401) return 'Email-ka ama password-ka waa khalad.';
        if (status == 403) return 'Ma haysatid ogolaansho inaad gasho qaybtan.';
        if (status == 404) return 'Wax la raadinayay lama helin.';
        return 'Server-ku wuxuu soo celiyay jawaab aan la filayn.';
      case DioExceptionType.cancel:
        return 'Codsiga waa la joojiyay.';
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return 'Khalad shabakadeed ayaa dhacay. Fadlan isku day mar kale.';
    }
  }

  String _humanizeMessage(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('pending')) {
      return 'Akoonkaaga wali waa PENDING — ma geli kartid ilaa IT Admin uu ku approve gareeyo.';
    }
    if (lower.contains('suspended')) {
      return 'Akoonkaaga waa la hakiyey (SUSPENDED). Fadlan la xidhiidh IT Admin-ka.';
    }
    if (lower.contains('blocked')) {
      return 'Akoonkaaga waa la xannibay (BLOCKED). Fadlan la xidhiidh IT Admin-ka.';
    }
    if (lower.contains('email-ka ama password-ka')) {
      return message;
    }
    if (lower.contains('role-kaaga') || lower.contains('uma oggola')) {
      return 'Ma haysatid ogolaansho inaad gasho qaybtan.';
    }
    if (lower.contains('user already exists')) {
      return 'Email-kan horay ayaa loo isticmaalay.';
    }
    if (lower.contains('branch limit') || lower.contains('xadka laamaha')) {
      return message;
    }

    return message;
  }
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
