/// Normalizes city names so "красноярск", "Красноярск", "КРАСНОЯРСК"
/// and "Krasnoyarsk" resolve to the same city.
library;

const _latin = <String, String>{
  'а': 'a',
  'б': 'b',
  'в': 'v',
  'г': 'g',
  'д': 'd',
  'е': 'e',
  'ё': 'e',
  'ж': 'zh',
  'з': 'z',
  'и': 'i',
  'й': 'j',
  'к': 'k',
  'л': 'l',
  'м': 'm',
  'н': 'n',
  'о': 'o',
  'п': 'p',
  'р': 'r',
  'с': 's',
  'т': 't',
  'у': 'u',
  'ф': 'f',
  'х': 'h',
  'ц': 'c',
  'ч': 'ch',
  'ш': 'sh',
  'щ': 'sch',
  'ъ': '',
  'ы': 'y',
  'ь': '',
  'э': 'e',
  'ю': 'yu',
  'я': 'ya',
};

/// Extra nicknames that do not transliterate to the official name.
const _aliases = <String, String>{
  'msk': 'moskva',
  'moscow': 'moskva',
  'мск': 'moskva',
  'spb': 'sanktpeterburg',
  'peterburg': 'sanktpeterburg',
  'petersburg': 'sanktpeterburg',
  'saintpetersburg': 'sanktpeterburg',
  'stpetersburg': 'sanktpeterburg',
  'piter': 'sanktpeterburg',
  'питер': 'sanktpeterburg',
  'петербург': 'sanktpeterburg',
  'leningrad': 'sanktpeterburg',
  'ленинград': 'sanktpeterburg',
  'nizhnijnovgorod': 'nizhnijnovgorod',
  'nizhniynovgorod': 'nizhnijnovgorod',
  'nizhny': 'nizhnijnovgorod',
  'nn': 'nizhnijnovgorod',
  'нн': 'nizhnijnovgorod',
  'ekaterinburg': 'ekaterinburg',
  'yekaterinburg': 'ekaterinburg',
  'ебург': 'ekaterinburg',
  'екб': 'ekaterinburg',
  'nsk': 'novosibirsk',
  'нск': 'novosibirsk',
  'rostov': 'rostovnadonu',
  'rostovondon': 'rostovnadonu',
  'ростов': 'rostovnadonu',
  'krasnoiarsk': 'krasnoyarsk',
  'krasnoyarsk': 'krasnoyarsk',
  'spbcity': 'sanktpeterburg',
};

const _labels = <String, String>{
  'moskva': 'Москва',
  'sanktpeterburg': 'Санкт-Петербург',
  'novosibirsk': 'Новосибирск',
  'ekaterinburg': 'Екатеринбург',
  'kazan': 'Казань',
  'nizhnijnovgorod': 'Нижний Новгород',
  'chelyabinsk': 'Челябинск',
  'samara': 'Самара',
  'omsk': 'Омск',
  'rostovnadonu': 'Ростов-на-Дону',
  'ufa': 'Уфа',
  'krasnoyarsk': 'Красноярск',
  'voronezh': 'Воронеж',
  'perm': 'Пермь',
  'volgograd': 'Волгоград',
  'krasnodar': 'Краснодар',
  'saratov': 'Саратов',
  'tyumen': 'Тюмень',
  'tolyatti': 'Тольятти',
  'izhevsk': 'Ижевск',
  'barnaul': 'Барнаул',
  'ulyanovsk': 'Ульяновск',
  'irkutsk': 'Иркутск',
  'habarovsk': 'Хабаровск',
  'yaroslavl': 'Ярославль',
  'vladivostok': 'Владивосток',
  'mahachkala': 'Махачкала',
  'tomsk': 'Томск',
  'orenburg': 'Оренбург',
  'kemerovo': 'Кемерово',
  'novokuzneck': 'Новокузнецк',
  'ryazan': 'Рязань',
  'astrahan': 'Астрахань',
  'penza': 'Пенза',
  'lipetsk': 'Липецк',
  'kirov': 'Киров',
  'cheboksary': 'Чебоксары',
  'kaliningrad': 'Калининград',
  'tula': 'Тула',
  'kursk': 'Курск',
  'sochi': 'Сочи',
  'stavropol': 'Ставрополь',
  'magnitogorsk': 'Магнитогорск',
  'tver': 'Тверь',
  'ivanovo': 'Иваново',
  'brjansk': 'Брянск',
  'belgorod': 'Белгород',
  'surgut': 'Сургут',
  'vladimir': 'Владимир',
  'chita': 'Чита',
  'kaluga': 'Калуга',
  'smolensk': 'Смоленск',
  'volzhskij': 'Волжский',
  'cherepovec': 'Череповец',
  'vologda': 'Вологда',
  'saransk': 'Саранск',
  'orel': 'Орёл',
  'vladikavkaz': 'Владикавказ',
  'yakutsk': 'Якутск',
  'podolsk': 'Подольск',
  'murmansk': 'Мурманск',
  'tambov': 'Тамбов',
  'groznyj': 'Грозный',
  'sterlitamak': 'Стерлитамак',
  'kostroma': 'Кострома',
  'petrozavodsk': 'Петрозаводск',
  'nizhnevartovsk': 'Нижневартовск',
  'yoshkarola': 'Йошкар-Ола',
  'novorossijsk': 'Новороссийск',
  'komsomolsknanamure': 'Комсомольск-на-Амуре',
  'taganrog': 'Таганрог',
  'syktyvkar': 'Сыктывкар',
  'nizhnekamsk': 'Нижнекамск',
  'shakhty': 'Шахты',
  'dzerzhinsk': 'Дзержинск',
  'bratsk': 'Братск',
  'orsk': 'Орск',
  'angarsk': 'Ангарск',
  'engels': 'Энгельс',
  'blagoveschensk': 'Благовещенск',
  'staryjoskol': 'Старый Оскол',
  'velikijnovgorod': 'Великий Новгород',
  'pskov': 'Псков',
  'bijsk': 'Бийск',
  'prokopevsk': 'Прокопьевск',
  'yuzhnosahalinsk': 'Южно-Сахалинск',
  'balashiha': 'Балашиха',
  'himki': 'Химки',
  'mytischi': 'Мытищи',
  'korolev': 'Королёв',
  'lyubercy': 'Люберцы',
  'krasnogorsk': 'Красногорск',
  'odincovo': 'Одинцово',
  'domodedovo': 'Домодедово',
  'schelkovo': 'Щёлково',
  'pushkino': 'Пушкино',
  'zhukovskij': 'Жуковский',
  'reutov': 'Реутов',
  'zelenograd': 'Зеленоград',
  'sevastopol': 'Севастополь',
  'simferopol': 'Симферополь',
  'almaty': 'Алматы',
  'astana': 'Астана',
  'minsk': 'Минск',
  'tashkent': 'Ташкент',
  'baku': 'Баку',
  'yerevan': 'Ереван',
  'tbilisi': 'Тбилиси',
  'bishkek': 'Бишкек',
};

final _junk = RegExp(
  r'^(г|гор|город|city|town)[.\s\-]*',
  caseSensitive: false,
);
final _nonWord = RegExp(r'[^0-9a-zа-яё]+', caseSensitive: false);

String _fold(String raw) {
  var s = raw.trim().toLowerCase().replaceAll('ё', 'е');
  s = s.replaceFirst(_junk, '');
  s = s.replaceAll(_nonWord, '');
  final alias = _aliases[s];
  if (alias != null) return alias;
  final buf = StringBuffer();
  for (final ch in s.split('')) {
    buf.write(_latin[ch] ?? ch);
  }
  final latin = buf.toString();
  return _aliases[latin] ?? latin;
}

String cityKey(String raw) {
  final key = _fold(raw);
  return key.length > 28 ? key.substring(0, 28) : key;
}

String cityLabel(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  final key = cityKey(trimmed);
  if (key.isEmpty) return trimmed;
  final known = _labels[key];
  if (known != null) return known;
  return _titleCity(trimmed);
}

String _titleCity(String raw) {
  final cleaned = raw.trim().replaceFirst(_junk, '');
  final parts = cleaned
      .split(RegExp(r'[\s\-]+'))
      .where((p) => p.isNotEmpty)
      .map((part) {
    final lower = part.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }).toList();
  if (parts.isEmpty) return raw.trim();
  if (cleaned.contains('-')) return parts.join('-');
  return parts.join(' ');
}

bool sameCity(String a, String b) {
  final left = cityKey(a);
  final right = cityKey(b);
  if (left.isEmpty || right.isEmpty) return false;
  return left == right;
}
