class ApiEndpoints {
  ApiEndpoints._();

  static const login = '/auth/login.php';
  static const register = '/auth/register.php';
  static const profile = '/auth/profile.php';
  static const myModules = '/me/modules';
  static String moduleContent(String moduleId) => '/modules/$moduleId/content';
  static String moduleProgress(String moduleId) => '/modules/$moduleId/progress';
  static const questions = '/questions';
}
