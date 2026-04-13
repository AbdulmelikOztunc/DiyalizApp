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

const kModule1Content = ModuleContent(
  moduleId: '1',
  title: 'Böbrek ve Hemodiyaliz',
  contentPages: [
    ContentPage(
      title: 'Böbreklerin Görevleri',
      sections: [
        ContentSection(
          body:
              'Böbrekler, karın boşluğunun arka kısmında, omurganın her iki yanında bulunan fasulye şeklinde iki organdır. '
              'Her bir böbrek yaklaşık 10-12 cm uzunluğunda ve 150 gram ağırlığındadır. '
              'Küçük olmalarına rağmen vücudumuzun en hayati organlarından biridir.',
        ),
        ContentSection(
          heading: 'Böbreklerin Temel Görevleri',
          body: 'Böbrekler günde yaklaşık 180 litre kanı süzerek vücudumuzun iç dengesini korur.',
          keyPoints: [
            'Kanı süzerek zararlı atık maddeleri ve fazla sıvıyı idrar yoluyla vücuttan uzaklaştırır',
            'Vücuttaki sıvı, elektrolit (sodyum, potasyum, kalsiyum) ve asit-baz dengesini düzenler',
            'Kan yapımı için gerekli olan eritropoetin hormonunu üretir',
            'Kan basıncının düzenlenmesine yardımcı olur (renin hormonu)',
            'D vitaminini aktif hale getirerek kemik sağlığına katkıda bulunur',
          ],
        ),
      ],
    ),
    ContentPage(
      title: 'Kronik Böbrek Hastalığı',
      sections: [
        ContentSection(
          body:
              'Kronik böbrek hastalığı (KBH), böbreklerin işlevlerini geri dönüşümsüz olarak kaybetmesi durumudur. '
              'Bu süreç genellikle yıllar içinde yavaş yavaş ilerler. Böbrekler normalin %10-15\'inin altına '
              'düştüğünde, yaşamı sürdürmek için diyaliz tedavisi veya böbrek nakli gerekli hale gelir.',
        ),
        ContentSection(
          heading: 'Belirtiler',
          body: 'Kronik böbrek hastalığının erken evrelerinde belirgin belirti olmayabilir. İleri evrelerde şu belirtiler ortaya çıkabilir:',
          keyPoints: [
            'Yorgunluk ve halsizlik',
            'İştahsızlık, bulantı ve kusma',
            'Ellerde ve ayaklarda şişlik (ödem)',
            'Nefes darlığı',
            'İdrar miktarında azalma',
            'Uyku problemleri',
            'Kaşıntı ve cilt kuruluğu',
          ],
        ),
        ContentSection(
          heading: 'En Sık Nedenler',
          body: 'Kronik böbrek hastalığının en sık nedenleri:',
          keyPoints: [
            'Diyabet (şeker hastalığı) — en sık neden',
            'Hipertansiyon (yüksek tansiyon)',
            'Glomerülonefrit (böbrek iltihabı)',
            'Polikistik böbrek hastalığı',
          ],
        ),
      ],
    ),
    ContentPage(
      title: 'Hemodiyaliz Nedir?',
      sections: [
        ContentSection(
          body:
              'Hemodiyaliz, böbreklerin yeterince çalışamadığı durumlarda kanın vücut dışında özel bir makine '
              'aracılığıyla temizlenmesi işlemidir. Bu tedavi, böbreklerin yapamadığı görevleri kısmen üstlenir: '
              'kanı zararlı maddelerden arındırır, fazla sıvıyı uzaklaştırır ve elektrolit dengesini sağlar.',
        ),
        ContentSection(
          heading: 'Hemodiyaliz Nasıl Çalışır?',
          body:
              'Hemodiyaliz sırasında kanınız, damar erişiminiz (fistül, greft veya kateter) aracılığıyla '
              'vücudunuzdan alınır ve diyaliz makinesindeki özel bir filtreden (diyalizör) geçirilir. '
              'Bu filtre, yapay bir böbrek gibi çalışarak kandaki üre, kreatinin gibi atık maddeleri ve '
              'fazla sıvıyı temizler. Temizlenen kan tekrar vücudunuza geri verilir.',
          keyPoints: [
            'İşlem genellikle haftada 3 gün, her seans 4 saat sürer',
            'Tedavi diyaliz merkezinde sağlık ekibi gözetiminde yapılır',
            'Diyalizör (filtre) içinde binlerce ince tüp bulunur ve kanı süzer',
            'Diyalizat adı verilen özel bir sıvı, atık maddelerin kandan çekilmesini sağlar',
          ],
        ),
      ],
    ),
    ContentPage(
      title: 'Hemodiyaliz Süreci',
      sections: [
        ContentSection(
          heading: 'Diyaliz Öncesi',
          body: 'Her diyaliz seansından önce bazı hazırlıklar yapılır:',
          keyPoints: [
            'Kilo ölçümü yapılarak son seanstan bu yana alınan sıvı miktarı belirlenir',
            'Tansiyon, nabız ve ateş ölçülür',
            'Damar erişiminiz kontrol edilir ve iğneler yerleştirilir',
            'Makine ayarları sizin ihtiyaçlarınıza göre düzenlenir',
          ],
        ),
        ContentSection(
          heading: 'Diyaliz Sırasında',
          body:
              'Seans boyunca diyaliz hemşiresi sizi yakından takip eder. Bu sürede:',
          keyPoints: [
            'Tansiyonunuz düzenli aralıklarla ölçülür',
            'Kendinizi rahat hissetmeniz için pozisyon ayarlanır',
            'Kitap okuyabilir, televizyon izleyebilir veya dinlenebilirsiniz',
            'Herhangi bir rahatsızlık hissederseniz hemen hemşirenize bildirin',
          ],
        ),
        ContentSection(
          heading: 'Diyaliz Sonrası',
          body: 'Seans tamamlandıktan sonra:',
          keyPoints: [
            'İğneler çıkarılır ve damar erişim yerinize bası uygulanır',
            'Kilo ölçümü yapılarak çekilen sıvı miktarı kontrol edilir',
            'Tansiyon ve nabız ölçülür',
            'Hafif baş dönmesi olabilir, yavaşça ayağa kalkmanız önerilir',
          ],
        ),
      ],
    ),
    ContentPage(
      title: 'Öz Bakım ve Dikkat Edilmesi Gerekenler',
      sections: [
        ContentSection(
          body:
              'Hemodiyaliz tedavisi süresince kendi sağlığınıza dikkat etmeniz tedavinin başarısı için çok önemlidir. '
              'Öz bakım becerilerinizi geliştirmek, yaşam kalitenizi artırmanın en etkili yoludur.',
        ),
        ContentSection(
          heading: 'Günlük Öz Bakım Önerileri',
          body: 'Her gün dikkat etmeniz gereken temel noktalar:',
          keyPoints: [
            'Her gün kilonuzu ölçün ve kaydedin — iki diyaliz arası kilo artışı 2 kg\'ı geçmemeli',
            'Günlük sıvı alımınızı takip edin (doktorunuzun önerdiği miktar kadar)',
            'Tansiyonunuzu düzenli olarak ölçün',
            'İlaçlarınızı doktorunuzun önerdiği şekilde ve zamanında kullanın',
            'Damar erişiminizi (fistül/greft) günlük kontrol edin — titreşim (thrill) hissetmelisiniz',
            'Dengeli ve diyetinize uygun beslenin',
          ],
        ),
        ContentSection(
          heading: 'Acil Durumlarda Ne Yapmalı?',
          body: 'Şu durumlarda hemen sağlık ekibinizle iletişime geçin:',
          keyPoints: [
            'Fistül/greft bölgesinde şişlik, kızarıklık veya ağrı',
            'Fistülde titreşim (thrill) hissedememe',
            'Ateş yükselmesi (38°C üzeri)',
            'Nefes darlığı veya göğüs ağrısı',
            'Aşırı ödem (şişlik) veya ani kilo artışı',
            'Kontrol edilemeyen kanama',
          ],
        ),
      ],
    ),
  ],
);
