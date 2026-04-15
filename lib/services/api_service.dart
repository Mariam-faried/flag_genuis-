import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../models/country_model.dart';

class ApiService {
  Future<List<CountryModel>> fetchCountries() async {
    final uri = Uri.parse(
      '${AppConstants.restCountriesBaseUrl}/all?fields=${AppConstants.countriesFieldsQuery}',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load countries. Status code: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Unexpected API response format.');
    }

    final countries =
        decoded
            .whereType<Map<dynamic, dynamic>>()
            .map((raw) => Map<String, dynamic>.from(raw))
            .map(CountryModel.fromJson)
            .where((country) => country.nameCommon != 'Unknown')
            .toList()
          ..sort((a, b) => a.nameCommon.compareTo(b.nameCommon));

    return countries;
  }
}
