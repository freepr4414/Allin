import 'package:dio/dio.dart';
import 'dart:io';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message';
}

class ApiService {
  static late Dio _dio;
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  // 플랫폼별 기본 URL 설정
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080'; // Android 에뮬레이터용
    } else if (Platform.isIOS) {
      return 'http://localhost:8080';
    } else {
      return 'http://localhost:8080'; // 데스크톱용
    }
  }

  static void setupInterceptors() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // 요청 인터셉터
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('API 요청: ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          print(
            'API 응답: ${response.statusCode} ${response.requestOptions.uri}',
          );
          handler.next(response);
        },
        onError: (DioException error, handler) {
          String message = _getErrorMessage(error);
          print('API 오류: $message');
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: ApiException(message, error.response?.statusCode),
              response: error.response,
              type: error.type,
            ),
          );
        },
      ),
    );
  }

  static String _getErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return '연결 시간 초과';
      case DioExceptionType.sendTimeout:
        return '요청 전송 시간 초과';
      case DioExceptionType.receiveTimeout:
        return '응답 수신 시간 초과';
      case DioExceptionType.badResponse:
        return '서버 오류 (${error.response?.statusCode})';
      case DioExceptionType.cancel:
        return '요청이 취소됨';
      case DioExceptionType.connectionError:
        return '네트워크 연결 오류';
      case DioExceptionType.unknown:
      default:
        return '알 수 없는 오류가 발생했습니다';
    }
  }

  static Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(_getErrorMessage(e), e.response?.statusCode);
    }
  }

  static Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(_getErrorMessage(e), e.response?.statusCode);
    }
  }
}
