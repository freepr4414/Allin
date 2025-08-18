<<<<<<< HEAD
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
=======
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

/// Dio 기반 API 클라이언트
/// 백엔드 서버와의 HTTP 통신을 담당합니다.
class ApiService {
  /// 플랫폼에 따라 자동으로 베이스 URL 결정
  static String get baseUrl {
    if (kIsWeb) {
      // 웹에서는 현재 호스트 사용
      return 'http://localhost:8080';
    } else if (Platform.isAndroid || Platform.isIOS) {
      // ADB 포트 포워딩을 사용하므로 localhost 사용
      return 'http://localhost:8080';
    } else {
      // 데스크톱에서는 localhost 사용
      return 'http://localhost:8080';
    }
  }

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 5),  // 연결 타임아웃: 5초 (적절함)
    receiveTimeout: const Duration(seconds: 10), // 응답 타임아웃: 10초 (적절함)
    sendTimeout: const Duration(seconds: 10),    // 전송 타임아웃: 10초 (적절함)
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  /// 인터셉터 설정
  static void setupInterceptors() {
    // 에러 처리 인터셉터
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) {
          handler.next(error);
>>>>>>> eb01e759e3958a53e0ac9aff24e1afc96568c521
        },
      ),
    );
  }

<<<<<<< HEAD
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
=======
  /// GET 요청
  static Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// POST 요청
  static Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// DioException을 사용자 친화적 메시지로 변환
  static ApiException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('서버 연결 시간이 초과되었습니다.');
      
      case DioExceptionType.connectionError:
        return ApiException('서버에 연결할 수 없습니다. 네트워크 상태를 확인해주세요.');
      
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        switch (statusCode) {
          case 400:
            return ApiException('잘못된 요청입니다.');
          case 401:
            return ApiException('인증이 필요합니다.');
          case 404:
            return ApiException('요청한 리소스를 찾을 수 없습니다.');
          case 500:
            return ApiException('서버 내부 오류가 발생했습니다.');
          default:
            return ApiException('서버 오류가 발생했습니다. ($statusCode)');
        }
      
      case DioExceptionType.cancel:
        return ApiException('요청이 취소되었습니다.');
      
      default:
        return ApiException('알 수 없는 오류가 발생했습니다.');
    }
  }
}

/// API 예외 클래스
class ApiException implements Exception {
  final String message;
  
  const ApiException(this.message);
  
  @override
  String toString() => message;
}
>>>>>>> eb01e759e3958a53e0ac9aff24e1afc96568c521
