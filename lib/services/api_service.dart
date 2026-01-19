import 'package:dio/dio.dart';
import '../utils/constants.dart';
import '../config/app_config.dart';
import 'storage_service.dart';

class ApiService {
  final Dio _dio = Dio();

  ApiService() {
    _dio.options.baseUrl = AppConstants.baseUrl;
    _dio.options.connectTimeout = Duration(seconds: AppConfig.connectionTimeout);
    _dio.options.receiveTimeout = Duration(seconds: AppConfig.receiveTimeout);

    // Request Interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add ngrok bypass header for free tier (removes interstitial warning page)
        options.headers['ngrok-skip-browser-warning'] = 'true';
        
        final token = await StorageService.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // Check if already retried
          if (e.requestOptions.extra['retried'] == true) {
            return handler.next(e);
          }

          // Attempt Refresh
          try {
            final refreshToken = await StorageService.getRefreshToken();
            if (refreshToken == null) {
               return handler.next(e);
            }

            // Create a new Dio instance for refresh to avoid interceptor loop/conflicts
            final refreshDio = Dio();
            refreshDio.options.baseUrl = AppConstants.baseUrl;
            refreshDio.options.headers['ngrok-skip-browser-warning'] = 'true';
            
            final response = await refreshDio.post('/auth/refresh', data: {
              'refreshToken': refreshToken
            });

            if (response.statusCode == 200) {
              final newAccessToken = response.data['accessToken'];
              // If refresh token rotates, update it too. Assuming only access token for now based on backend code.
              // Backend: res.json({ accessToken: tokens.accessToken });
              await StorageService.storeTokens(newAccessToken, refreshToken);

              // Update header and retry
              e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              e.requestOptions.extra['retried'] = true;

              final retryResponse = await _dio.fetch(e.requestOptions);
              return handler.resolve(retryResponse);
            }
          } catch (refreshError) {
             // Refresh failed, logout user (clear tokens)
             await StorageService.clearTokens();
             return handler.next(e);
          }
        }
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;
}
