import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/country_model.dart';
import '../providers/quiz_provider.dart';

class ExplorerScreen extends StatefulWidget {
  const ExplorerScreen({super.key});

  @override
  State<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends State<ExplorerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuizProvider>();
    final countries = provider.countries;
    final filtered = countries
        .where(
          (country) =>
              country.nameCommon.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Country Explorer')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search country...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    _query = value;
                  });
                },
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No countries found.'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final country = filtered[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: SizedBox(
                              width: 42,
                              child: country.flagPng.isEmpty
                                  ? const Icon(Icons.flag_outlined)
                                  : Image.network(
                                      country.flagPng,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.broken_image),
                                    ),
                            ),
                            title: Text(country.nameCommon),
                            subtitle: Text(country.regionLabel),
                            onTap: () => _showCountryDetails(context, country),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCountryDetails(BuildContext context, CountryModel country) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                country.nameCommon,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (country.flagPng.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: Image.network(
                      country.flagPng,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Center(child: Icon(Icons.broken_image)),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              _DetailRow(title: 'Capital', value: country.primaryCapital),
              _DetailRow(
                title: 'Population',
                value: _formatPopulation(country.population),
              ),
              _DetailRow(title: 'Region', value: country.regionLabel),
              _DetailRow(
                title: 'Subregion',
                value: country.subregion.isEmpty
                    ? 'Unknown'
                    : country.subregion,
              ),
              _DetailRow(
                title: 'Languages',
                value: country.languages.isEmpty
                    ? 'Unknown'
                    : country.languages.join(', '),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatPopulation(int value) {
    final text = value.toString();
    return text.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyLarge,
          children: [
            TextSpan(
              text: '$title: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
