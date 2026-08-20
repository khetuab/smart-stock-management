import '../../../data/repositories/user_repository.dart';

class LoginUseCase {
  final UserRepository repository;

  LoginUseCase(this.repository);

  Future<bool> execute(String username, String password) async {
    return await repository.login(username, password);
  }
}