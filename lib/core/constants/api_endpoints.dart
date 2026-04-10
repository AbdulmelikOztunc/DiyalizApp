class ApiEndpoints {
  ApiEndpoints._();

  static const login = '/v1/auth/login';
  static const register = '/v1/auth/register';
  static const myModules = '/v1/me/modules';
  static String moduleContent(String moduleId) => '/v1/modules/$moduleId/content';
  static String moduleProgress(String moduleId) => '/v1/modules/$moduleId/progress';
  static const questions = '/v1/questions';
}
