// lib/screens/ticket/ticket_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../config/theme/app_colors.dart';
import '../../models/ticket_model.dart';

class TicketDetailScreen extends StatelessWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Billet'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tickets')
            .doc(ticketId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final ticket = TicketModel.fromMap(
            snapshot.data!.data() as Map<String, dynamic>,
            snapshot.data!.id,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Carte de billet stylisée
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      children: [
                        // En-tête du billet
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.confirmation_number,
                                  color: Colors.white, size: 40),
                              const SizedBox(height: 12),
                              Text(
                                ticket.eventTitre,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  ticket.status == TicketStatus.confirme
                                      ? '✅ CONFIRMÉ'
                                      : ticket.status == TicketStatus.utilise
                                          ? '🟡 UTILISÉ'
                                          : '❌ ANNULÉ',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Séparateur style billet
                        Container(
                          height: 30,
                          color: AppColors.backgroundCard,
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 15,
                                height: 30,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(15),
                                      bottomRight: Radius.circular(15),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Flex(
                                      direction: Axis.horizontal,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: List.generate(
                                        (constraints.constrainWidth() / 15)
                                            .floor(),
                                        (index) => SizedBox(
                                          width: 8,
                                          height: 2,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: AppColors.background
                                                  .withOpacity(0.5),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(
                                width: 15,
                                height: 30,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(15),
                                      bottomLeft: Radius.circular(15),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Infos du billet
                        Container(
                          padding: const EdgeInsets.all(20),
                          color: AppColors.backgroundCard,
                          child: Column(
                            children: [
                              _buildTicketInfoRow(
                                'Participant',
                                ticket.userNom,
                                Icons.person,
                              ),
                              const Divider(color: Colors.white10),
                              _buildTicketInfoRow(
                                'Date',
                                DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR')
                                    .format(ticket.dateEvenement),
                                Icons.calendar_today,
                              ),
                              const Divider(color: Colors.white10),
                              _buildTicketInfoRow(
                                'Lieu',
                                ticket.lieuEvenement,
                                Icons.location_on,
                              ),
                              const Divider(color: Colors.white10),
                              _buildTicketInfoRow(
                                'Nombre de places',
                                '${ticket.nombrePlaces} place(s)',
                                Icons.airline_seat_recline_normal,
                              ),
                              const Divider(color: Colors.white10),
                              _buildTicketInfoRow(
                                'Prix total',
                                ticket.prixPaye == 0
                                    ? 'Gratuit'
                                    : '${ticket.prixPaye.toStringAsFixed(0)} FCFA',
                                Icons.monetization_on,
                              ),
                              const Divider(color: Colors.white10),
                              _buildTicketInfoRow(
                                'Code de confirmation',
                                ticket.codeConfirmation ?? 'N/A',
                                Icons.confirmation_num,
                              ),
                            ],
                          ),
                        ),

                        // QR Code
                        Container(
                          padding: const EdgeInsets.all(24),
                          color: AppColors.backgroundCard,
                          child: Column(
                            children: [
                              const Text(
                                'Présentez ce QR Code à l\'entrée',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: QrImageView(
                                  data: ticket.qrCodeData,
                                  version: QrVersions.auto,
                                  size: 180,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                              if (ticket.status == TicketStatus.utilise)
                                const Padding(
                                  padding: EdgeInsets.only(top: 12),
                                  child: Text(
                                    '⚠️ Ce billet a déjà été utilisé',
                                    style: TextStyle(
                                      color: AppColors.warning,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTicketInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  )),
              Text(value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}