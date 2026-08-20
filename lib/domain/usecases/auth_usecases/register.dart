import '../../../data/repositories/user_repository.dart';

class RegisterUseCase {
  final UserRepository repository;

  RegisterUseCase(this.repository);

  Future<bool> execute(String username, String password) async {
    return await repository.register(username, password);
  }
}