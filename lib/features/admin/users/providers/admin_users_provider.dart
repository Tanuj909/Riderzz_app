import 'package:flutter/material.dart';
import 'package:riderzz_app/core/models/user_model.dart';
import 'package:riderzz_app/features/admin/users/data/repositories/admin_users_repository.dart';

class AdminUsersProvider extends ChangeNotifier {
  final AdminUsersRepository _repository;

  AdminUsersProvider(this._repository);

  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 0;
  int _totalPages = 1;
  bool _isLastPage = false;
  String? _currentRoleFilter;
  String? _currentStatusFilter;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLastPage => _isLastPage;
  String? get currentRoleFilter => _currentRoleFilter;
  String? get currentStatusFilter => _currentStatusFilter;

  Future<void> fetchUsers({
    bool refresh = false,
    String? role,
    String? status,
  }) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 0;
      _users.clear();
      _isLastPage = false;
    }

    if (_isLastPage && !refresh) return;

    _isLoading = true;
    _errorMessage = null;
    
    // Update filters if provided, otherwise keep current
    if (role != null) _currentRoleFilter = role == 'ALL' ? null : role;
    if (status != null) _currentStatusFilter = status == 'ALL' ? null : status;

    notifyListeners();

    try {
      final response = await _repository.getUsers(
        page: _currentPage,
        size: 20,
        role: _currentRoleFilter,
        status: _currentStatusFilter,
      );

      final newUsers = response['users'] as List<UserModel>;
      
      if (refresh) {
        _users = newUsers;
      } else {
        _users.addAll(newUsers);
      }

      _currentPage++;
      _totalPages = response['totalPages'] as int;
      _isLastPage = response['isLast'] as bool;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  void setRoleFilter(String? role) {
    _currentRoleFilter = role == 'ALL' ? null : role;
    fetchUsers(refresh: true);
  }

  void setStatusFilter(String? status) {
    _currentStatusFilter = status == 'ALL' ? null : status;
    fetchUsers(refresh: true);
  }

  void clearFilters() {
    _currentRoleFilter = null;
    _currentStatusFilter = null;
    fetchUsers(refresh: true);
  }
}
