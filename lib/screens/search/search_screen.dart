// lib/screens/search/search_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_colors.dart';
import '../../providers/event_provider.dart';
import '../home/widgets/event_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Rechercher')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Concerts, soirées, jeux...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          eventProvider.searchEvents('');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => eventProvider.searchEvents(value),
            ),
          ),
          Expanded(
            child: eventProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : eventProvider.searchResults.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'Tapez pour rechercher'
                              : 'Aucun résultat trouvé',
                          style: const TextStyle(
                              color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: eventProvider.searchResults.length,
                        itemBuilder: (context, index) {
                          final event = eventProvider.searchResults[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: EventCard(
                              event: event,
                              onTap: () =>
                                  context.push('/event/${event.id}'),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}