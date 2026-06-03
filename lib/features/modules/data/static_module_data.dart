import 'package:diyalizmobile/features/modules/domain/entities/module_item.dart';

const kStaticModules = <ModuleItem>[
  ModuleItem(
    id: '1',
    title: 'Böbrek ve Hemodiyaliz',
    description: 'Böbreklerin görevleri, kronik böbrek hastalığı ve hemodiyaliz tedavisi hakkında temel bilgiler.',
    weekNumber: 1,
    isUnlocked: true,
  ),
  ModuleItem(
    id: '2',
    title: 'Beslenme ve Sıvı Yönetimi',
    description: 'Hemodiyaliz hastalarında doğru beslenme, sıvı kısıtlaması ve diyet önerileri.',
    weekNumber: 2,
    isUnlocked: false,
  ),
  ModuleItem(
    id: '3',
    title: 'İlaç Yönetimi',
    description: 'Kullanılan ilaçlar, doğru ilaç kullanımı ve dikkat edilmesi gerekenler.',
    weekNumber: 3,
    isUnlocked: false,
  ),
  ModuleItem(
    id: '4',
    title: 'Damar Erişimi ve Bakımı',
    description: 'Fistül, greft ve kateter bakımı, enfeksiyon önleme yöntemleri.',
    weekNumber: 4,
    isUnlocked: false,
  ),
  ModuleItem(
    id: '5',
    title: 'Komplikasyonlar ve Korunma',
    description: 'Diyaliz sırasında ve sonrasında oluşabilecek sorunlar ve korunma yolları.',
    weekNumber: 5,
    isUnlocked: false,
  ),
  ModuleItem(
    id: '6',
    title: 'Psikososyal Destek ve Yaşam Kalitesi',
    description: 'Duygusal destek, stres yönetimi ve yaşam kalitesini artırma stratejileri.',
    weekNumber: 6,
    isUnlocked: false,
  ),
];

/// Modül 1 PDF sayfa başlığı (üst başlık metniyle uyumlu).
const kModule1PrimaryPageTitle = 'Böbreklerimizi Tanıyalım';

/// Ekranda gösterilmez; yalnızca sesli okuma (modül 1).
const kModule1HiddenNarrationForTts = '''
Böbreklerimiz, belimizin arka kısmında yer alan ve kuru fasulye şeklinde olan iki adet organdır.

Yetişkin bir böbreğin büyüklüğü yaklaşık olarak bir yumruk kadardır. Her bir böbrek yüz yirmi beş ile yüz elli gram ağırlığındadır.

Böbreklerimiz ne işe yarar?

Böbreklerimiz aynı anda birçok görevi yerine getirir. Örneğin, evimizi temizlerken gerekli eşyaları düzenler, gereksiz olanları ayırıp çöpe atarız. Böbreklerde benzer şekilde, besinlerle alınan ve vücudumuz için yararsız, hatta zararlı olabilecek, kanda biriken maddeleri vücuttan uzaklaştırır.

Doktorunuzdan sıkça duyduğunuz üre, kreatinin ve ürik asit: işte bu maddeler kanda biriken zararlı maddelerdendir. Bu maddelerin süzülerek idrarla vücuttan uzaklaştırılmasını sağlayan organlar ise böbreklerdir.

Böbreklerimiz görevini yeterince yapamaz hale geldiğinde, vücutta biriken fazla tuz ve suyu gerektiği gibi uzaklaştıramayız. Suyun vücutta fazla birikmesi bacaklarda ve göz kapaklarında şişlik oluşmasına, kısa sürede aşırı kilo artışına ve tansiyonun, yani kan basıncının yükselmesine yol açar.

Bu durum ilerlediğinde akciğerlerde sıvı birikimi gelişebilir ve buna bağlı olarak nefes darlığı ortaya çıkabilir.

Böbrekler görevini yerine getiremez hale geldiğinde, kemik iliği gerekli uyarıları alamaz ve yeterli miktarda kan üretemez. Bu durumda kansızlık ortaya çıkar.

Bildiğiniz gibi kemiklerimiz vücudumuzu ayakta tutan ve hareketimizi sağlayan temel direklerdir. Böbrekler bu görevini yerine getiremezse vücudumuzda kalsiyum eksikliği ve fosfor fazlalığı başlar. Sonuçta kemikler zayıflar ve kolaylıkla kırılır.

Böbreklerimiz bu görevlerini yapamaz hale gelirse zararlı atık maddeler vücutta birikir ve zehirlenmeler olabilir.
''';

ModuleItem _staticModule(String id) =>
    kStaticModules.firstWhere((m) => m.id == id);

String _localPdfPageTitle(String moduleId) {
  if (moduleId == '1') return kModule1PrimaryPageTitle;
  return _staticModule(moduleId).title;
}

ModuleContent _localPdfModuleContent(String moduleId) {
  final module = _staticModule(moduleId);
  return ModuleContent(
    moduleId: moduleId,
    title: module.title,
    videoUrl: moduleId == '1'
        ? 'https://www.youtube.com/watch?v=mI7u1wazvDU'
        : null,
    contentPages: [
      ContentPage(
        title: _localPdfPageTitle(moduleId),
        contentId: 'module${moduleId}_pdf',
        mediaUrl: 'assets/education/module$moduleId.pdf',
        mediaType: 'pdf',
        mediaPosition: 'above',
        narrationText: null,
        sections: const [],
      ),
    ],
  );
}

/// Tüm modüller: `assets/education/module{N}.pdf` + API’den başlık/video.
final kLocalAssetPdfModules = <String, ModuleContent>{
  for (final m in kStaticModules) m.id: _localPdfModuleContent(m.id),
};

/// API hatasında modül 1 yedek içerik (geriye dönük).
ModuleContent get kModule1Content => kLocalAssetPdfModules['1']!;
