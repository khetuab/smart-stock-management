/// ─────────────────────────────────────────────────────────────────────────
///  AZKAR & SALAWAT DATA — authenticated adhkar with Arabic text,
///  transliteration, English and Amharic translations.
///
///  Sources: the widely-published Hisn al-Muslim (Fortress of the Muslim)
///  collection and the authentic prophetic adhkar collections. Counts follow
///  the reported sunnah (e.g. 33/33/33 after prayer, 100x SubhanAllahi wa
///  bihamdihi). Text is kept to well-established, verbatim adhkar only.
/// ─────────────────────────────────────────────────────────────────────────

class Zikr {
  final String arabic;
  final String transliteration;
  final String en; // English meaning
  final String am; // Amharic meaning
  final int count;
  final String virtueEn; // reported benefit / source note

  const Zikr({
    required this.arabic,
    required this.transliteration,
    required this.en,
    required this.am,
    this.count = 1,
    this.virtueEn = '',
  });
}

class AzkarCategory {
  final String id; // localization key suffix
  final List<Zikr> items;
  const AzkarCategory({required this.id, required this.items});
}

// ───────────────────────────── AFTER PRAYER ─────────────────────────────

const AzkarCategory kAzkarAfterPrayer = AzkarCategory(id: 'afterPrayer', items: [
  Zikr(
    arabic: 'أَسْتَغْفِرُ اللهَ',
    transliteration: 'Astaghfirullah',
    en: 'I seek forgiveness from Allah.',
    am: 'ከአላህ ይቅርታ እጠይቃለሁ።',
    count: 3,
    virtueEn: 'The Prophet (peace be upon him) sought forgiveness three times after finishing prayer.',
  ),
  Zikr(
    arabic: 'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
    transliteration: 'Allahumma antas-salam wa minkas-salam, tabarakta ya dhal-jalali wal-ikram',
    en: 'O Allah, You are Peace and from You comes peace. Blessed are You, O Owner of Majesty and Honor.',
    am: 'አላህሆይ፣ አንተ ሰላም ነህ፤ ከአንተም ሰላም ነው። በረከተኛለህ፣ ያ ክብርና ታላቅነት ባለቤት።',
    count: 1,
  ),
  Zikr(
    arabic: 'سُبْحَانَ اللَّهِ',
    transliteration: 'SubhanAllah',
    en: 'Glory be to Allah.',
    am: 'አላህ ከሁሉ ነገር ንጹህ ነው።',
    count: 33,
    virtueEn: 'After every prayer: 33 SubhanAllah, 33 Alhamdulillah, 33 Allahu Akbar.',
  ),
  Zikr(
    arabic: 'الْحَمْدُ لِلَّهِ',
    transliteration: 'Alhamdulillah',
    en: 'All praise belongs to Allah.',
    am: 'ሁሉም ምስጋና ለአላህ ይገባል።',
    count: 33,
  ),
  Zikr(
    arabic: 'اللَّهُ أَكْبَرُ',
    transliteration: 'Allahu Akbar',
    en: 'Allah is the Greatest.',
    am: 'አላህ ትልቁ ነው።',
    count: 33,
  ),
  Zikr(
    arabic: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
    transliteration: 'La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa huwa ala kulli shay-in qadir',
    en: 'There is no god but Allah alone, without partner. His is the dominion and His is the praise, and He is over all things competent.',
    am: 'ከአላህ በስተቀር አምላክ የለም፤ ብቻውን ነው፤ ምህረት የለበትም። ንግሥት የለት፣ ምስጋናም የለት፤ በሁሉም ነገር ላይ ችሎታ ያለው ነው።',
    count: 1,
    virtueEn: 'Whoever says this after each prayer, his sins are forgiven even if like the foam of the sea.',
  ),
  Zikr(
    arabic: 'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ',
    transliteration: 'Allahumma a-inni ala dhikrika wa shukrika wa husni ibadatik',
    en: 'O Allah, help me to remember You, to thank You, and to worship You in the best manner.',
    am: 'አላህሆይ፣ ስለአንተ ማሰብን፣ ማመስገንንና መልካም የአብያተ እደገበርን እንዳድርግ አግዘኝ።',
    count: 1,
  ),
]);

// ─────────────────────────────── MORNING ────────────────────────────────

const AzkarCategory kAzkarMorning = AzkarCategory(id: 'morning', items: [
  Zikr(
    arabic: 'اللَّهُ لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ (آيَةُ الْكُرْسِيُّ)',
    transliteration: "Allahu la ilaha illa Huwa, Al-Hayyul-Qayyum (Ayat al-Kursi)",
    en: 'Allah — there is no deity except Him, the Ever-Living, the Sustainer of existence. (Ayat al-Kursi, recite in full.)',
    am: 'አላህ — ከእርሱ በስተቀር አምላክ የለም፤ ሕያው፣ ሁሉን ጠባቂ ነው። (የእግር ወንበር አንቀጽ — ሙሉ በሙሉ ያንብቡ።)',
    count: 1,
    virtueEn: 'Whoever recites Ayat al-Kursi in the morning is protected until the evening.',
  ),
  Zikr(
    arabic: 'قُلْ هُوَ اللَّهُ أَحَدٌ — قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ — قُلْ أَعُوذُ بِرَبِّ النَّاسِ',
    transliteration: 'Qul Huwa Allahu Ahad; Qul a-udhu bi rabbil-falaq; Qul a-udhu bi rabbin-nas',
    en: 'Surah Al-Ikhlas, Al-Falaq and An-Nas — recite each in full.',
    am: 'ሱረተ እኽላስ፣ ሱረተ ፈለቅና ሱረተ ናስ — ሶስት ጊዜ ያንብቡ።',
    count: 3,
    virtueEn: 'They will suffice you against everything.',
  ),
  Zikr(
    arabic: 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
    transliteration: 'Asbahna wa asbahal-mulku lillah, walhamdu lillah, la ilaha illallahu wahdahu la sharika lah',
    en: 'We have entered the morning and with it the dominion belongs to Allah. All praise is for Allah. There is no god but Allah alone.',
    am: 'ጠዋት አደርን፤ ንግሥትም ለአላህ ሆነ። ምስጋና ለአላህ ይገባል፤ ከአላህ በስተቀር አምላክ የለም።',
    count: 1,
  ),
  Zikr(
    arabic: 'اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ',
    transliteration: 'Allahumma bika asbahna, wa bika amsayna, wa bika nahya, wa bika namutu, wa ilaykan-nushur',
    en: 'O Allah, by You we enter the morning and the evening, by You we live and die, and to You is the resurrection.',
    am: 'አላህሆይ፣ በአንተ ጠዋት አደርን፣ በአንተ ምሽት ገባን፤ በአንተ እንህለ፣ በአንተም እንሞታለን፤ መንስኤም ወደ አንተ ነው።',
    count: 1,
  ),
  Zikr(
    arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    transliteration: 'SubhanAllahi wa bihamdih',
    en: 'Glory be to Allah and praise be to Him.',
    am: 'አላህ ንጹህ ነው፤ ምስጋናም የለት።',
    count: 100,
    virtueEn: 'Whoever says it 100 times a day, his sins are forgiven even if like the foam of the sea.',
  ),
  Zikr(
    arabic: 'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا',
    transliteration: 'Raditu billahi rabba, wa bil-islami dina, wa bi Muhammadin sallallahu alayhi wa sallam nabiyya',
    en: 'I am pleased with Allah as my Lord, with Islam as my religion, and with Muhammad (peace be upon him) as my Prophet.',
    am: 'በአላህ እንደ ጌታዬ፣ በእስልምና እንደ ሃይማኖቴ፣ በሙሐመድ (ሰላም በርሱ ላይ) እንደ ነቢዬ አርካለሁ።',
    count: 3,
    virtueEn: 'Whoever says this three times, Allah will surely please him on the Day of Resurrection.',
  ),
  Zikr(
    arabic: 'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
    transliteration: 'Bismillahil-ladhi la yadurru ma-ismihi shay-un fil-ardi wa la fis-sama, wa huwas-samiul-alim',
    en: 'In the name of Allah, with whose name nothing on earth or in heaven can cause harm; and He is the All-Hearing, the All-Knowing.',
    am: 'በአላህ ስም፤ በስሙ በምድርም በሰማይም ያለ ነገር አይጎዳም፤ እርሱ ሰሚ ዐዋቂ ነው።',
    count: 3,
    virtueEn: 'Nothing will harm the one who says it three times morning and evening.',
  ),
  Zikr(
    arabic: 'حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ، عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
    transliteration: 'Hasbiyallahu la ilaha illa Huwa, alayhi tawakkaltu wa Huwa rabbul-arshil-adhim',
    en: 'Allah is sufficient for me; there is no god but Him. In Him I trust, and He is the Lord of the Mighty Throne.',
    am: 'አላህ በቂ ነኝ፤ ከእርሱ በስተቀር አምላክ የለም። በእርሱ ተኰንያለሁ፤ የታላቁ ዙፋን ጌታ ነው።',
    count: 7,
  ),
]);

// ─────────────────────────────── EVENING ────────────────────────────────

const AzkarCategory kAzkarEvening = AzkarCategory(id: 'evening', items: [
  Zikr(
    arabic: 'اللَّهُ لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ (آيَةُ الْكُرْسِيُّ)',
    transliteration: "Allahu la ilaha illa Huwa, Al-Hayyul-Qayyum (Ayat al-Kursi)",
    en: 'Allah — there is no deity except Him, the Ever-Living, the Sustainer of existence. (Ayat al-Kursi, recite in full.)',
    am: 'አላህ — ከእርሱ በስተቀር አምላክ የለም፤ ሕያው፣ ሁሉን ጠባቂ ነው። (የእግር ወንበር አንቀጽ — ሙሉ በሙሉ ያንብቡ።)',
    count: 1,
  ),
  Zikr(
    arabic: 'قُلْ هُوَ اللَّهُ أَحَدٌ — قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ — قُلْ أَعُوذُ بِرَبِّ النَّاسِ',
    transliteration: 'Qul Huwa Allahu Ahad; Qul a-udhu bi rabbil-falaq; Qul a-udhu bi rabbin-nas',
    en: 'Surah Al-Ikhlas, Al-Falaq and An-Nas — recite each in full.',
    am: 'ሱረተ እኽላስ፣ ሱረተ ፈለቅና ሱረተ ናስ — ሶስት ጊዜ ያንብቡ።',
    count: 3,
  ),
  Zikr(
    arabic: 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
    transliteration: 'Amsayna wa amsal-mulku lillah, walhamdu lillah, la ilaha illallahu wahdahu la sharika lah',
    en: 'We have entered the evening and with it the dominion belongs to Allah. All praise is for Allah. There is no god but Allah alone.',
    am: 'ምሽት ገባን፤ ንግሥትም ለአላህ ሆነ። ምስጋና ለአላህ ይገባል፤ ከአላህ በስተቀር አምላክ የለም።',
    count: 1,
  ),
  Zikr(
    arabic: 'اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ',
    transliteration: 'Allahumma bika amsayna, wa bika asbahna, wa bika nahya, wa bika namutu, wa ilaykal-masir',
    en: 'O Allah, by You we enter the evening and the morning, by You we live and die, and to You is the final return.',
    am: 'አላህሆይ፣ በአንተ ምሽት ገባን፣ በአንተ ጠዋት አደርን፤ በአንተ እንህለ፣ በአንተም እንሞታለን፤ መመለስም ወደ አንተ ነው።',
    count: 1,
  ),
  Zikr(
    arabic: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
    transliteration: 'A-udhu bikalimatillahit-tammati min sharri ma khalaq',
    en: 'I seek refuge in the perfect words of Allah from the evil of what He has created.',
    am: 'ከፈጠረው ሁሉ ክፉ ነገር በአላህ ሙሉ ቃላት እጠባበቃለሁ።',
    count: 3,
    virtueEn: 'Whoever says this three times in the evening will not be harmed by that night.',
  ),
  Zikr(
    arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    transliteration: 'SubhanAllahi wa bihamdih',
    en: 'Glory be to Allah and praise be to Him.',
    am: 'አላህ ንጹህ ነው፤ ምስጋናም የለት።',
    count: 100,
  ),
  Zikr(
    arabic: 'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
    transliteration: 'Bismillahil-ladhi la yadurru ma-ismihi shay-un fil-ardi wa la fis-sama, wa huwas-samiul-alim',
    en: 'In the name of Allah, with whose name nothing on earth or in heaven can cause harm; and He is the All-Hearing, the All-Knowing.',
    am: 'በአላህ ስም፤ በስሙ በምድርም በሰማይም ያለ ነገር አይጎዳም፤ እርሱ ሰሚ ዐዋቂ ነው።',
    count: 3,
  ),
]);

// ─────────────────────────────── SLEEPING ───────────────────────────────

const AzkarCategory kAzkarSleeping = AzkarCategory(id: 'sleeping', items: [
  Zikr(
    arabic: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
    transliteration: 'Bismika Allahumma amutu wa ahya',
    en: 'In Your name, O Allah, I die and I live.',
    am: 'በስምህ አላህሆይ እሞታለሁ፣ እኖራለሁ።',
    count: 1,
  ),
  Zikr(
    arabic: 'اللَّهُ لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ (آيَةُ الْكُرْسِيُّ)',
    transliteration: "Allahu la ilaha illa Huwa, Al-Hayyul-Qayyum (Ayat al-Kursi)",
    en: 'Ayat al-Kursi — recite in full before sleep.',
    am: 'የእግር ወንበር አንቀጽ — ከመተኛት በፊት ሙሉ በሙሉ ያንብቡ።',
    count: 1,
    virtueEn: 'A guardian from Allah remains over the one who recites it at bedtime, and no devil approaches until morning.',
  ),
  Zikr(
    arabic: 'قُلْ هُوَ اللَّهُ أَحَدٌ — قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ — قُلْ أَعُوذُ بِرَبِّ النَّاسِ',
    transliteration: 'Qul Huwa Allahu Ahad; Qul a-udhu bi rabbil-falaq; Qul a-udhu bi rabbin-nas',
    en: 'Cup the hands together, recite the three surahs, blow into the cupped hands and wipe over the body — three times.',
    am: 'እጅን ስበስበው ሱራዎቹን ያንብቡ፣ ወደ እጅ ትንፋሽ አብቅተው በሰውነት ላይ ይታሸቡ — ሶስት ጊዜ።',
    count: 3,
  ),
  Zikr(
    arabic: 'سُبْحَانَ اللَّهِ — الْحَمْدُ لِلَّهِ — اللَّهُ أَكْبَرُ',
    transliteration: 'SubhanAllah — Alhamdulillah — Allahu Akbar',
    en: 'Glory be to Allah (33), praise be to Allah (33), Allah is the Greatest (34).',
    am: 'አላህ ንጹህ ነው (33)፣ ምስጋና ለአላህ ይገባል (33)፣ አላህ ትልቁ ነው (34)።',
    count: 34,
    virtueEn: 'Better than a servant for you — they weigh more on the scales than everything of this world.',
  ),
  Zikr(
    arabic: 'اللَّهُمَّ أَسْلَمْتُ نَفْسِي إِلَيْكَ، وَوَجَّهْتُ وَجْهِي إِلَيْكَ، وَفَوَّضْتُ أَمْرِي إِلَيْكَ، وَأَلْجَأْتُ ظَهْرِي إِلَيْكَ',
    transliteration: 'Allahumma aslamtu nafsi ilayk, wa wajjahtu wajhi ilayk, wa fawwadtu amri ilayk, wa aljatu zahri ilayk',
    en: 'O Allah, I submit myself to You, turn my face to You, entrust my affairs to You, and rely completely on You.',
    am: 'አላህሆይ፣ ራሴን ለአንተ አስረከብኩ፣ ፊቴን ወደ አንተ አዘንቀቅኩ፣ ጉዳዬን ለአንተ አስረከብኩ፣ ጀርቤንም ወደ አንተ አመለከትኩ።',
    count: 1,
  ),
]);

const List<AzkarCategory> kAzkarCategories = [
  kAzkarMorning,
  kAzkarEvening,
  kAzkarAfterPrayer,
  kAzkarSleeping,
];

// ─────────────────────────────── SALAWAT ────────────────────────────────

const List<Zikr> kSalawat = [
  Zikr(
    arabic: 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ. اللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ',
    transliteration: 'Allahumma salli ala Muhammadin wa ala ali Muhammad, kama sallayta ala Ibrahima wa ala ali Ibrahim, innaka Hamidun Majid. Allahumma barik ala Muhammadin wa ala ali Muhammad, kama barakta ala Ibrahima wa ala ali Ibrahim, innaka Hamidun Majid',
    en: 'O Allah, send prayers upon Muhammad and the family of Muhammad as You sent prayers upon Ibrahim and the family of Ibrahim... and send blessings likewise. (The Ibrahimiyya — said in tashahhud and at any time.)',
    am: 'አላህሆይ፣ በሙሐመድና በሙሐመድ ቤተሰብ ላይ እንዳመሰገንክህ በኢብራሂምና በኢብራሂም ቤተሰብ ላይ እንደ ሆነው ስጋንን አብዝተህ በርከትን አድርግልን፤ አንተ የሚዘነጋህና የሚከብርህ ነህ።',
    count: 1,
    virtueEn: 'Whoever sends one salawat, Allah sends ten upon him.',
  ),
  Zikr(
    arabic: 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
    transliteration: 'Allahumma salli wa sallim ala nabiyyina Muhammad',
    en: 'O Allah, send prayers and peace upon our Prophet Muhammad.',
    am: 'አላህሆይ፣ በነቢያችን ሙሐመድ ላይ ሰላምና ምህረት በርስከልን።',
    count: 100,
    virtueEn: 'On Friday, send abundant salawat — your prayer is presented to the Prophet (peace be upon him).',
  ),
  Zikr(
    arabic: 'صَلَّى اللهُ عَلَيْهِ وَسَلَّمَ',
    transliteration: 'Sallallahu alayhi wa sallam',
    en: 'May the prayers and peace of Allah be upon him — said whenever the Prophet is mentioned.',
    am: 'ሰላምና ምህረት የአላህ በርሱ ላይ ይሁን — የነቢዩ ስም ሲጠቀስ ይባላል።',
    count: 33,
  ),
  Zikr(
    arabic: 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ نَبِيِّ الْأُمِّيِّ وَعَلَى آلِهِ وَصَحْبِهِ وَسَلِّمْ',
    transliteration: 'Allahumma salli ala Muhammadin nabiyyil-ummiyyi wa ala alihi wa sahbihi wa sallim',
    en: 'O Allah, send prayers upon Muhammad the Unlettered Prophet, and upon his family and companions, and grant them peace.',
    am: 'አላህሆይ፣ በዓረፊው ነቢይ ሙሐመድ፣ በቤተሰቡና በተከታዮቹ ላይ ምህረትን አድርግላቸው፤ ሰላምንም ስጣቸው።',
    count: 10,
  ),
];
