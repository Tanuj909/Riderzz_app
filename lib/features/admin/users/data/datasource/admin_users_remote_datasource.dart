import 'package:riderzz_app/core/network/api_client.dart';
import 'package:riderzz_app/core/network/api_constants.dart';
import 'package:riderzz_app/core/models/user_model.dart';

class AdminUsersRemoteDataSource {
  final ApiClient _apiClient;

  AdminUsersRemoteDataSource(this._apiClient);

  Future<Map<String, dynamic>> getUsers({
    int page = 0,
    int size = 20,
    String? role,
    String? status,
  }) async {
    final Map<String, dynamic> queryParameters = {
      'page': page,
      'size': size,
    };

    if (role != null && role.isNotEmpty) {
      queryParameters['role'] = role;
    }
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }

    final response = await _apiClient.get(
      ApiConstants.adminUsers,
      queryParameters: queryParameters,
    );

    final data = response.data['data'];
    if (data == null) {
      throw Exception('No data found');
    }

    final content = data['content'] as List<dynamic>? ?? [];
    final users = content.map((json) => UserModel.fromJson(json)).toList();

    return {
      'users': users,
      'totalElements': data['totalElements'] ?? 0,
      'totalPages': data['totalPages'] ?? 1,
      'currentPage': data['number'] ?? 0,
      'isLast': data['last'] ?? true,
    };
  }
}
