class AppConstants {
  static const String appName = 'Flag Genius';
  static const String restCountriesBaseUrl = 'https://restcountries.com/v3.1';
  static const int maxLives = 3;
  static const int questionTimeLimitSeconds = 10;
  static const int minCountriesToStart = 20;

  static const String countriesFieldsQuery =
      'name,flags,capital,population,region,subregion,languages';
}
