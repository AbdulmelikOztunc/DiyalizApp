class ApiEndpoints {
  ApiEndpoints._();

  static const login = 'auth/login.php';
  static const register = 'auth/register.php';
  static const profile = 'auth/profile.php';
  static const myModules = 'modules/list.php';
  static const moduleContent = 'modules/content.php';
  static const moduleProgress = 'modules/progress.php';
  static String moduleContentLegacy(String moduleId) =>
      'modules/$moduleId/content';
  static String moduleProgressLegacy(String moduleId) =>
      'modules/$moduleId/progress';
  static const questions = 'questions/create.php';
  static const questionsList = 'questions/list.php';
  static const settings = 'settings/index.php';
}
