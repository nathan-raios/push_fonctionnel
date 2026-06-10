// lib/screens/event/event_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/theme/app_colors.dart';
import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/event_service.dart';
import '../../services/ticket_service.dart';
import '../../services/cloudinary_service.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final EventService _eventService = EventService();
  final TicketService _ticketService = TicketService();
  int _selectedPlaces = 1;
  bool _isFavorite = false;
  bool _isBooking = false;

  // ✅ FIX: Couleur par catégorie
  Color _getCategoryColor(EventCategory category) {
    switch (category) {
      case EventCategory.concert:
        return AppColors.concert;
      case EventCategory.soiree:
        return AppColors.soiree;
      case EventCategory.rencontre:
        return AppColors.rencontre;
      case EventCategory.jeux:
        return AppColors.jeux;
      case EventCategory.sport:
        return AppColors.sport;
      case EventCategory.culture:
        return AppColors.culture;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: StreamBuilder<EventModel?>(
        stream: _eventService.getEventStream(widget.eventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text(
                'Événement non trouvé',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final event = snapshot.data!;

          _isFavorite =
              authProvider.currentUser?.favorisIds.contains(event.id) ??
                  false;

          return CustomScrollView(
            slivers: [
              // ==================== APP BAR ====================
              SliverAppBar(
                expandedHeight: 350,
                pinned: true,
                backgroundColor: AppColors.background,
                leading: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                  ),
                ),
                actions: [
                  // Bouton Favori
                  GestureDetector(
                    onTap: () {
                      if (authProvider.currentUser != null) {
                        _toggleFavorite(
                          authProvider.currentUser!.id,
                          event.id,
                        );
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          _isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _isFavorite
                              ? AppColors.error
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Bouton Partager
                  GestureDetector(
                    onTap: () {
                      Share.share(
                        'Rejoins-moi à "${event.titre}" le '
                        '${DateFormat('dd MMM yyyy').format(event.dateDebut)}',
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.share, color: Colors.white),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image principale
                      CachedNetworkImage(
                        imageUrl: CloudinaryService.getBannerUrl(
                          event.imageUrl,
                        ),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.backgroundCard,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.backgroundCard,
                          child: const Icon(
                            Icons.image_outlined,
                            color: AppColors.textHint,
                            size: 60,
                          ),
                        ),
                      ),
                      // Gradient du bas
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.background,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ==================== CONTENU ====================
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges (Catégorie + Premium + Complet)
                      Row(
                        children: [
                          _buildCategoryChip(event.categorie),
                          const SizedBox(width: 8),
                          if (event.isPremium) _buildPremiumBadge(),
                          const SizedBox(width: 8),
                          if (event.isComplet) _buildCompletBadge(),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Titre
                      Text(
                        event.titre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Carte d'informations
                      _buildInfoCard([
                        _buildInfoRow(
                          Icons.calendar_today,
                          'Date',
                          DateFormat('EEEE dd MMMM yyyy', 'fr_FR')
                              .format(event.dateDebut),
                          AppColors.accent,
                        ),
                        const Divider(color: Colors.white10),
                        _buildInfoRow(
                          Icons.access_time,
                          'Horaire',
                          '${DateFormat('HH:mm').format(event.dateDebut)}'
                              ' - '
                              '${DateFormat('HH:mm').format(event.dateFin)}',
                          AppColors.primary,
                        ),
                        const Divider(color: Colors.white10),
                        _buildInfoRow(
                          Icons.location_on,
                          'Lieu',
                          event.location.salleNom != null
                              ? '${event.location.salleNom}\n'
                                  '${event.location.fullAddress}'
                              : event.location.fullAddress,
                          AppColors.secondary,
                        ),
                        const Divider(color: Colors.white10),
                        _buildInfoRow(
                          Icons.people,
                          'Participants',
                          '${event.nombreParticipants} / ${event.capaciteMax}',
                          AppColors.success,
                        ),
                      ]),
                      const SizedBox(height: 20),

                      // Barre de progression des places
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${event.placesRestantes} places restantes',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: event.capaciteMax > 0
                                  ? event.nombreParticipants /
                                      event.capaciteMax
                                  : 0,
                              backgroundColor: AppColors.backgroundLight,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                event.isComplet
                                    ? AppColors.error
                                    : AppColors.success,
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Organisateur
                      const Text(
                        'Organisateur',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildOrganizerCard(event),
                      const SizedBox(height: 24),

                      // Description
                      const Text(
                        'À propos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        event.description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.6,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tags
                      if (event.tags.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: event.tags
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    '#$tag',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Sélecteur de places
                      // ✅ FIX: isPasse au lieu de isPassé
                      if (!event.isComplet && !event.isPasse) ...[
                        const Text(
                          'Nombre de places',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildQuantityButton(
                              Icons.remove,
                              () {
                                if (_selectedPlaces > 1) {
                                  setState(() => _selectedPlaces--);
                                }
                              },
                            ),
                            const SizedBox(width: 20),
                            Text(
                              '$_selectedPlaces',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 20),
                            _buildQuantityButton(
                              Icons.add,
                              () {
                                if (_selectedPlaces < event.placesRestantes) {
                                  setState(() => _selectedPlaces++);
                                }
                              },
                            ),
                            const Spacer(),
                            Text(
                              event.isGratuit
                                  ? 'Gratuit'
                                  : '${(event.prix * _selectedPlaces).toStringAsFixed(0)} FCFA',
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 100),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),

      // ==================== BOTTOM BAR ====================
      bottomNavigationBar: StreamBuilder<EventModel?>(
        stream: _eventService.getEventStream(widget.eventId),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const SizedBox.shrink();
          }
          final event = snapshot.data!;

          // ✅ FIX: isPasse au lieu de isPassé
          if (event.isPasse) {
            return _buildBottomBar(
              child: const Text(
                'Événement terminé',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              color: AppColors.textHint,
            );
          }

          if (event.isComplet) {
            return _buildBottomBar(
              child: const Text(
                'Événement complet',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              color: AppColors.error,
            );
          }

          return _buildBottomBar(
            child: _isBooking
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    event.isGratuit
                        ? 'Réserver gratuitement'
                        : 'Acheter $_selectedPlaces billet(s)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            onTap: () => _bookEvent(event, context),
          );
        },
      ),
    );
  }

  // ==================== WIDGETS HELPERS ====================

  Widget _buildBottomBar({
    required Widget child,
    Color? color,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: onTap != null ? AppColors.primaryGradient : null,
            color: onTap == null ? (color ?? AppColors.textHint) : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizerCard(EventModel event) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary,
            backgroundImage: event.organisateurPhoto != null
                ? NetworkImage(event.organisateurPhoto!)
                : null,
            child: event.organisateurPhoto == null
                ? Text(
                    event.organisateurNom
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.organisateurNom,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'Organisateur',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            child: const Text(
              'Suivre',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(EventCategory category) {
    final color = _getCategoryColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPremiumBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        '⭐ PREMIUM',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCompletBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        '🔴 COMPLET',
        style: TextStyle(
          color: AppColors.error,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
    );
  }

  // ==================== ACTIONS ====================

  Future<void> _toggleFavorite(String userId, String eventId) async {
    setState(() => _isFavorite = !_isFavorite);
    await _eventService.toggleFavorite(userId, eventId, _isFavorite);
  }

  // ✅ FIX: BuildContext async gap corrigé
  Future<void> _bookEvent(EventModel event, BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser == null) return;

    setState(() => _isBooking = true);

    // ✅ Capturer les références AVANT les opérations async
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final user = authProvider.currentUser!;

    try {
      final ticket = await _ticketService.createTicket(
        event: event,
        user: user,
        nombrePlaces: _selectedPlaces,
      );

      if (mounted) {
        router.push('/ticket/${ticket.id}');
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }
}