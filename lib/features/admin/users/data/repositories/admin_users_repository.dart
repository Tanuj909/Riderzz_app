import 'package:riderzz_app/features/admin/users/data/datasource/admin_users_remote_datasource.dart';

class AdminUsersRepository {
  final AdminUsersRemoteDataSource _dataSource;

  AdminUsersRepository(this._dataSource);

  Future<Map<String, dynamic>> getUsers({
    int page = 0,
    int size = 20,
    String? role,
    String? status,
  }) {
    return _dataSource.getUsers(
      page: page,
      size: size,
      role: role,
      status: status,
    );
  }
}
