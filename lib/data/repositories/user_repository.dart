import '../services/google_sheets_service.dart';
import '../services/shared_preferences_service.dart';
import '../../domain/entities/user.dart';
import '../../core/utils/helpers.dart';

class UserRepository {
  final GoogleSheetsService _sheets = GoogleSheetsService();
  final SharedPreferencesService _prefs = SharedPreferencesService();

  Future<bool> login(String username, String password) async {
    try {
      await _sheets.init();

      final data = await _sheets.getSheetDataWithHeaders('Users');
      if (data.isEmpty) return false;

      final usernames = data['Username'] ?? [];
      final passwords = data['Password'] ?? [];

      for (int i = 0; i < usernames.length; i++) {
        if (usernames[i] == username && passwords[i] == password) {
          await _prefs.saveLoginSession(username);
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error during login: $e');
      return false;
    }
  }

  Future<bool> register(String username, String password) async {
    try {
      await _sheets.init();

      final data = await _sheets.getSheetDataWithHeaders('Users');
      final usernames = data['Username'] ?? [];

      // Check if user exists
      if (usernames.contains(username)) {
        return false;
      }

      // Create new user
      final id = Helpers.generateId();
      await _sheets.appendToSheet(
        sheetName: 'Users',
        rowData: [id, username, password, DateTime.now().toIso8601String()],
      );

      return true;
    } catch (e) {
      print('Error during registration: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _prefs.clearLoginSession();
  }
}