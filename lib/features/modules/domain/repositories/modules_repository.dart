import 'package:diyalizmobile/core/network/api_result.dart';
import 'package:diyalizmobile/features/modules/domain/entities/module_item.dart';

abstract class ModulesRepository {
  Future<ApiResult<List<ModuleItem>>> getMyModules();
  Future<ApiResult<ModuleContent>> getModuleContent(String moduleId);
  Future<ApiResult<void>> sendProgress({
    required String moduleId,
    required int pageIndex,
  });
}
