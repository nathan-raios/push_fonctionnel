// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../models/event_model.dart';
import 'widgets/featured_events_slider.dart';
import 'widgets/event_card.dart';
import 'widgets/category_filter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  // ✅ Stream initialisé une seule fois
  late final Stream<List<EventModel>> _featuredStream;

  @override
  void initState() {
    super.initState();
    _featuredStream =
        context.read<EventProvider>().getFeaturedEvents();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<EventProvider>().loadEvents(refresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final authProvider = context.watch<AuthProvider>();
    final eventProvider = context.watch<EventProvider>();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => eventProvider.loadEvents(refresh: true),
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [

            // ==================== APP BAR ====================
            SliverAppBar(
              expandedHeight: 80,
              floating: true,
              snap: true,
              backgroundColor: AppColors.background,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Salutation
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bonjour, ${authProvider.currentUser?.prenom ?? ''} 👋',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Text(
                          "Que fait-on ce soir ?",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    // Actions
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Cloche notifications
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                                size: 22,
                              ),
                              onPressed: () {},
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Avatar utilisateur
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary,
                          backgroundImage:
                              authProvider.currentUser?.photoUrl != null
                                  ? NetworkImage(
                                      authProvider.currentUser!.photoUrl!,
                                    )
                                  : null,
                          child: authProvider.currentUser?.photoUrl == null
                              ? Text(
                                  authProvider.currentUser?.prenom
                                          .substring(0, 1)
                                          .toUpperCase() ??
                                      'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ==================== 🔥 À LA UNE ====================
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  '🔥 À la une',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Slider événements vedettes
            SliverToBoxAdapter(
              child: SizedBox(
                height: 220,
                child: StreamBuilder<List<EventModel>>(
                  stream: _featuredStream,
                  builder: (context, snapshot) {
                    // Chargement
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }

                    // Erreur
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Erreur: ${snapshot.error}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }

                    final events = snapshot.data ?? [];

                    // Vide
                    if (events.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.star_outline,
                              size: 48,
                              color: AppColors.textHint
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Aucun événement en vedette',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return FeaturedEventsSlider(events: events);
                  },
                ),
              ),
            ),

            // ==================== CATÉGORIES ====================
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text(
                  'Catégories',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: CategoryFilter(
                selectedCategory: eventProvider.selectedCategory,
                onCategorySelected: eventProvider.setCategory,
              ),
            ),

            // ==================== ÉVÉNEMENTS À VENIR ====================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Événements à venir',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/search'),
                      child: const Text(
                        'Voir tout',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Erreur
            if (eventProvider.error != null)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          eventProvider.error!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            eventProvider.loadEvents(refresh: true),
                        child: const Text(
                          'Réessayer',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Loading initial
            if (eventProvider.isLoading &&
                eventProvider.events.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              )

            // Liste vide
            else if (!eventProvider.isLoading &&
                eventProvider.filteredEvents.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: AppColors.textHint
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          eventProvider.selectedCategory != null
                              ? 'Aucun événement dans cette catégorie'
                              : 'Aucun événement disponible',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tirez vers le bas pour actualiser',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          onPressed: () =>
                              eventProvider.loadEvents(refresh: true),
                          icon: const Icon(
                            Icons.refresh,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          label: const Text(
                            'Actualiser',
                            style:
                                TextStyle(color: AppColors.primary),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.primary,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )

            // ✅ Liste des événements
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final events = eventProvider.filteredEvents;

                      // Loader pagination en bas
                      if (index == events.length) {
                        if (eventProvider.isLoading) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }

                      if (index >= events.length) {
                        return const SizedBox.shrink();
                      }

                      final event = events[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: EventCard(
                          event: event,
                          onTap: () =>
                              context.push('/event/${event.id}'),
                        ),
                      );
                    },
                    childCount: eventProvider.filteredEvents.length +
                        (eventProvider.isLoading &&
                                eventProvider.events.isNotEmpty
                            ? 1
                            : 0),
                  ),
                ),
              ),

            // Espace bas de page
            const SliverToBoxAdapter(
              child: SizedBox(height: 120),
            ),
          ],
        ),
      ),

      // FAB organisateur
      floatingActionButton: authProvider.isOrganisateur
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/create-event'),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Créer',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }
}