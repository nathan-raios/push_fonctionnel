// lib/screens/organizer/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_colors.dart';
import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/event_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/ticket_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final EventService _eventService = EventService();
  final TicketService _ticketService = TicketService();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _openQRScanner(context),
            tooltip: 'Scanner un billet',
          ),
        ],
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: _eventService.getOrganizerEvents(
          authProvider.currentUser!.id,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data ?? [];

          // Statistiques
          final totalEvents = events.length;
          final activeEvents = events
              .where((e) => e.status == EventStatus.actif)
              .length;
          final totalParticipants = events.fold(
            0,
            (sum, e) => sum + e.nombreParticipants,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats cards
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.4,
                  children: [
                    _buildStatCard(
                      'Total événements',
                      '$totalEvents',
                      Icons.event,
                      AppColors.primary,
                    ),
                    _buildStatCard(
                      'Événements actifs',
                      '$activeEvents',
                      Icons.event_available,
                      AppColors.success,
                    ),
                    _buildStatCard(
                      'Total participants',
                      '$totalParticipants',
                      Icons.people,
                      AppColors.accent,
                    ),
                    _buildStatCard(
                      'Revenus estimés',
                      '${_calculateRevenue(events).toStringAsFixed(0)} FCFA',
                      Icons.monetization_on,
                      AppColors.secondary,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Mes événements
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mes Événements',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => context.push('/create-event'),
                      icon: const Icon(Icons.add, color: AppColors.primary),
                      label: const Text(
                        'Nouveau',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (events.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.event_busy,
                            size: 80, color: AppColors.textHint),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucun événement créé',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/create-event'),
                          icon: const Icon(Icons.add),
                          label: const Text('Créer mon premier événement'),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildOrganizerEventCard(events[index], context);
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizerEventCard(EventModel event, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.titre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${event.nombreParticipants}/${event.capaciteMax} participants',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: event.nombreParticipants / event.capaciteMax,
                  backgroundColor: AppColors.backgroundLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    event.isComplet ? AppColors.error : AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(event.status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  event.status.name.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(event.status),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => context.push('/event/${event.id}'),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(EventStatus status) {
    switch (status) {
      case EventStatus.actif: return AppColors.success;
      case EventStatus.annule: return AppColors.error;
      case EventStatus.complet: return AppColors.warning;
      case EventStatus.termine: return AppColors.textHint;
      default: return AppColors.primary;
    }
  }

  double _calculateRevenue(List<EventModel> events) {
    return events.fold(
      0.0,
      (sum, e) => sum + (e.prix * e.nombreParticipants),
    );
  }

  void _openQRScanner(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Scanner un billet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MobileScanner(
                  onDetect: (capture) async {
                    final barcode = capture.barcodes.first;
                    if (barcode.rawValue != null) {
                      Navigator.pop(context);
                      final result = await _ticketService.validateTicket(
                        barcode.rawValue!,
                      );
                      if (context.mounted) {
                        _showValidationResult(context, result);
                      }
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showValidationResult(
    BuildContext context,
    dynamic result,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              result.isValid ? Icons.check_circle : Icons.cancel,
              size: 80,
              color: result.isValid ? AppColors.success : AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              result.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (result.ticket != null) ...[
              const SizedBox(height: 12),
              Text(
                result.ticket!.userNom,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              Text(
                '${result.ticket!.nombrePlaces} place(s)',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}