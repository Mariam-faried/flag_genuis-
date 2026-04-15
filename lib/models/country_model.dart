class CountryModel {
  CountryModel({
    required this.nameCommon,
    required this.flagPng,
    required this.capital,
    required this.population,
    required this.region,
    required this.subregion,
    required this.languages,
  });

  final String nameCommon;
  final String flagPng;
  final List<String> capital;
  final int population;
  final String region;
  final String subregion;
  final List<String> languages;

  String get primaryCapital => capital.isEmpty ? 'Unknown' : capital.first;
  String get regionLabel => region.isEmpty ? 'Unknown' : region;
  bool get hasFlag => flagPng.isNotEmpty;
  bool get hasCapital => capital.isNotEmpty;

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] as Map<String, dynamic>?) ?? {};
    final flags = (json['flags'] as Map<String, dynamic>?) ?? {};
    final languagesMap = (json['languages'] as Map<String, dynamic>?) ?? {};

    return CountryModel(
      nameCommon: (name['common'] as String?)?.trim() ?? 'Unknown',
      flagPng: (flags['png'] as String?)?.trim() ?? '',
      capital: ((json['capital'] as List<dynamic>?) ?? const [])
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty)
          .toList(),
      population: (json['population'] as num?)?.toInt() ?? 0,
      region: (json['region'] as String?)?.trim() ?? '',
      subregion: (json['subregion'] as String?)?.trim() ?? '',
      languages: languagesMap.values
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty)
          .toList(),
    );
  }
}
