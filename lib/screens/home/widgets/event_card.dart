// lib/screens/home/widgets/event_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../config/theme/app_colors.dart';
import '../../../models/event_model.dart';
import '../../../services/cloudinary_service.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  Color _getCategoryColor(EventCategory category) {
    switch (category) {
      case EventCategory.concert: return AppColors.concert;
      case EventCategory.soiree: return AppColors.soiree;
      case EventCategory.rencontre: return AppColors.rencontre;
      case EventCategory.jeux: return AppColors.jeux;
      case EventCategory.sport: return AppColors.sport;
      case EventCategory.culture: return AppColors.culture;
      default: return AppColors.primary;
    }
  }

  String _getCategoryLabel(EventCategory category) {
    switch (category) {
      case EventCategory.concert: return '🎵 Concert';
      case EventCategory.soiree: return '🎉 Soirée';
      case EventCategory.rencontre: return '🤝 Rencontre';
      case EventCategory.jeux: return '🎮 Jeux';
      case EventCategory.sport: return '⚽ Sport';
      case EventCategory.culture: return '🎭 Culture';
      case EventCategory.festival: return '🎪 Festival';
      case EventCategory.conference: return '🎤 Conférence';
      case EventCategory.atelier: return '🛠 Atelier';
      default: return '📅 Autre';
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(event.categorie);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: CachedNetworkImage(
                imageUrl: CloudinaryService.getThumbnailUrl(
                  event.imageUrl,
                  width: 120,
                  height: 120,
                ),
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.backgroundLight,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.backgroundLight,
                  child: const Icon(Icons.image_outlined,
                      color: AppColors.textHint),
                ),
              ),
            ),

            // Contenu
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Catégorie + Prix
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getCategoryLabel(event.categorie),
                            style: TextStyle(
                              color: categoryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          event.isGratuit
                              ? 'Gratuit'
                              : '${event.prix.toStringAsFixed(0)} FCFA',
                          style: TextStyle(
                            color: event.isGratuit
                                ? AppColors.success
                                : AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Titre
                    Text(
                      event.titre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Date
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: AppColors.textSecondary, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM - HH:mm', 'fr_FR')
                              .format(event.dateDebut),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Lieu + Places
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: AppColors.textSecondary, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              event.location.ville,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (event.isComplet)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Complet',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Text(
                            '${event.placesRestantes} places',
                            style: const TextStyle(
                              color: AppColors.success,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}