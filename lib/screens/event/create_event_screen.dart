// lib/screens/event/create_event_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme/app_colors.dart';
import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  // ✅ Un formKey PAR étape pour valider indépendamment
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();

  final _titreController = TextEditingController();
  final _descController = TextEditingController();
  final _adresseController = TextEditingController();
  final _villeController = TextEditingController();
  final _prixController = TextEditingController();
  final _capaciteController = TextEditingController();
  final _salleController = TextEditingController();
  final _tagController = TextEditingController();
  final List<String> _tags = [];

  File? _selectedImage;
  EventCategory _selectedCategory = EventCategory.concert;
  DateTime _dateDebut = DateTime.now().add(const Duration(days: 7));
  DateTime _dateFin =
      DateTime.now().add(const Duration(days: 7, hours: 3));
  bool _isGratuit = true;
  bool _isPremium = false;
  int _currentStep = 0;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titreController.dispose();
    _descController.dispose();
    _adresseController.dispose();
    _villeController.dispose();
    _prixController.dispose();
    _capaciteController.dispose();
    _salleController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  // ✅ FIX BUG 1: Validation par étape
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        // Valider étape 1 : titre, description, image
        if (_selectedImage == null) {
          _showSnackBar('Veuillez sélectionner une image', isError: true);
          return false;
        }
        return _formKeyStep1.currentState?.validate() ?? false;

      case 1:
        // Valider étape 2 : dates et lieu
        if (_dateFin.isBefore(_dateDebut)) {
          _showSnackBar(
            'La date de fin doit être après la date de début',
            isError: true,
          );
          return false;
        }
        return _formKeyStep2.currentState?.validate() ?? false;

      case 2:
        // Valider étape 3 : billetterie
        return _formKeyStep3.currentState?.validate() ?? false;

      case 3:
        // Étape 4 : tags + résumé, pas de validation requise
        return true;

      default:
        return true;
    }
  }

  void _onStepContinue() {
    // ✅ Valider l'étape courante avant de continuer
    if (!_validateCurrentStep()) return;

    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _submitForm();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _selectDate(bool isStart) async {
    final initialDate = isStart ? _dateDebut : _dateFin;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.backgroundCard,
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null || !mounted) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.backgroundCard,
          ),
        ),
        child: child!,
      ),
    );

    if (time == null) return;

    final fullDate = DateTime(
      picked.year, picked.month, picked.day,
      time.hour, time.minute,
    );

    setState(() {
      if (isStart) {
        _dateDebut = fullDate;
      } else {
        _dateFin = fullDate;
      }
    });
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    final authProvider = context.read<AuthProvider>();
    final eventProvider = context.read<EventProvider>();
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (authProvider.currentUser == null) return;

    final organisateurId = authProvider.currentUser!.id;
    final organisateurNom = authProvider.currentUser!.fullName;
    final organisateurPhoto = authProvider.currentUser!.photoUrl;
    final prix = _isGratuit
        ? 0.0
        : double.tryParse(_prixController.text) ?? 0.0;
    final capacite = int.tryParse(_capaciteController.text) ?? 0;

    final event = EventModel(
      id: '',
      titre: _titreController.text.trim(),
      description: _descController.text.trim(),
      organisateurId: organisateurId,
      organisateurNom: organisateurNom,
      organisateurPhoto: organisateurPhoto,
      categorie: _selectedCategory,
      imageUrl: '',
      dateDebut: _dateDebut,
      dateFin: _dateFin,
      location: EventLocation(
        adresse: _adresseController.text.trim(),
        ville: _villeController.text.trim(),
        pays: "Côte d'Ivoire",
        latitude: 5.3600,
        longitude: -4.0083,
        salleNom: _salleController.text.isNotEmpty
            ? _salleController.text.trim()
            : null,
      ),
      prix: prix,
      capaciteMax: capacite,
      tags: List<String>.from(_tags),
      isPremium: _isPremium,
      createdAt: DateTime.now(),
    );

    final success = await eventProvider.createEvent(
      event: event,
      imageFile: _selectedImage!,
    );

    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Événement créé avec succès ! 🎉'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      router.go('/home');
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            eventProvider.error ?? 'Erreur lors de la création',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Créer un événement'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // ✅ Indicateur de progression personnalisé
          _buildProgressIndicator(),

          // Contenu de l'étape
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildCurrentStep(),
            ),
          ),

          // Boutons navigation
          _buildNavigationButtons(eventProvider),
        ],
      ),
    );
  }

  // ✅ Indicateur de progression visuel
  Widget _buildProgressIndicator() {
    final steps = ['Infos', 'Date & Lieu', 'Billetterie', 'Résumé'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: AppColors.backgroundCard,
      child: Column(
        children: [
          Row(
            children: List.generate(steps.length, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;
              return Expanded(
                child: Row(
                  children: [
                    // Cercle numéroté
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: isCompleted || isCurrent
                            ? AppColors.primaryGradient
                            : null,
                        color: isCompleted || isCurrent
                            ? null
                            : AppColors.backgroundLight,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isCurrent
                                      ? Colors.white
                                      : AppColors.textHint,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ),
                    // Ligne de connexion
                    if (index < steps.length - 1)
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 2,
                          color: index < _currentStep
                              ? AppColors.primary
                              : AppColors.backgroundLight,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          // Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: steps.map((step) {
              final index = steps.indexOf(step);
              return Text(
                step,
                style: TextStyle(
                  fontSize: 10,
                  color: index <= _currentStep
                      ? AppColors.primary
                      : AppColors.textHint,
                  fontWeight: index == _currentStep
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ✅ Retourne le contenu de l'étape courante
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      case 3:
        return _buildStep4();
      default:
        return const SizedBox.shrink();
    }
  }

  // ✅ Boutons navigation en bas
  Widget _buildNavigationButtons(EventProvider eventProvider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton Retour
          if (_currentStep > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _onStepCancel,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  side: const BorderSide(color: AppColors.textSecondary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Retour',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 12),

          // Bouton Suivant / Publier
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: eventProvider.isLoading ? null : _onStepContinue,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 52,
                decoration: BoxDecoration(
                  gradient: eventProvider.isLoading
                      ? null
                      : AppColors.primaryGradient,
                  color: eventProvider.isLoading
                      ? AppColors.textHint
                      : null,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: eventProvider.isLoading
                      ? []
                      : [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                alignment: Alignment.center,
                child: eventProvider.isLoading && _currentStep == 3
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _currentStep < 3
                            ? 'Suivant →'
                            : '🚀 Publier l\'événement',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ÉTAPES ====================

  // ÉTAPE 1: Informations de base
  Widget _buildStep1() {
    return Form(
      key: _formKeyStep1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📝 Informations générales',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Image picker
          GestureDetector(
            onTap: _pickImage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedImage != null
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.3),
                  width: _selectedImage != null ? 2 : 1,
                ),
                image: _selectedImage != null
                    ? DecorationImage(
                        image: FileImage(_selectedImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _selectedImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 52,
                          color: AppColors.primary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ajouter une affiche *',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Appuyez pour choisir',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Container(color: Colors.transparent),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedImage = null),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '✅ Image sélectionnée',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Titre
          TextFormField(
            controller: _titreController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: "Titre de l'événement *",
              prefixIcon: Icon(Icons.title),
              hintText: 'Ex: Concert de Jazz au Plateau',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Le titre est obligatoire';
              }
              if (v.trim().length < 3) {
                return 'Minimum 3 caractères';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Description
          TextFormField(
            controller: _descController,
            style: const TextStyle(color: Colors.white),
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Description *',
              prefixIcon: Icon(Icons.description),
              alignLabelWithHint: true,
              hintText: 'Décrivez votre événement...',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'La description est obligatoire';
              }
              if (v.trim().length < 10) {
                return 'Minimum 10 caractères';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Catégorie
          DropdownButtonFormField<EventCategory>(
            value: _selectedCategory,
            dropdownColor: AppColors.backgroundCard,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Catégorie *',
              prefixIcon: Icon(Icons.category),
            ),
            items: EventCategory.values.map((cat) {
              return DropdownMenuItem(
                value: cat,
                child: Text(
                  _getCategoryLabel(cat),
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCategory = value);
              }
            },
          ),
        ],
      ),
    );
  }

  // ÉTAPE 2: Date et Lieu
  Widget _buildStep2() {
    return Form(
      key: _formKeyStep2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📅 Date & Localisation',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Date Début
          _buildDateSelector(
            label: 'Date et heure de début *',
            date: _dateDebut,
            icon: Icons.calendar_today,
            color: AppColors.accent,
            onTap: () => _selectDate(true),
          ),
          const SizedBox(height: 12),

          // Date Fin
          _buildDateSelector(
            label: 'Date et heure de fin *',
            date: _dateFin,
            icon: Icons.event_available,
            color: AppColors.primary,
            onTap: () => _selectDate(false),
          ),

          // Warning si date fin avant date début
          if (_dateFin.isBefore(_dateDebut))
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: AppColors.error, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'La date de fin doit être après le début',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          const Divider(color: Colors.white10),
          const SizedBox(height: 16),

          const Text(
            '📍 Lieu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Salle
          TextFormField(
            controller: _salleController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Nom du lieu / salle (optionnel)',
              prefixIcon: Icon(Icons.business),
              hintText: 'Ex: Palais de la Culture',
            ),
          ),
          const SizedBox(height: 12),

          // Adresse
          TextFormField(
            controller: _adresseController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Adresse *',
              prefixIcon: Icon(Icons.location_on),
              hintText: 'Ex: Boulevard Lagunaire',
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Adresse requise' : null,
          ),
          const SizedBox(height: 12),

          // Ville
          TextFormField(
            controller: _villeController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Ville *',
              prefixIcon: Icon(Icons.location_city),
              hintText: 'Ex: Abidjan',
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Ville requise' : null,
          ),
        ],
      ),
    );
  }

  // ÉTAPE 3: Billetterie
  Widget _buildStep3() {
    return Form(
      key: _formKeyStep3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎫 Billetterie',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Toggle Gratuit/Payant
          _buildSwitchCard(
            title: 'Événement gratuit',
            subtitle:
                _isGratuit ? 'Accès libre sans billet' : 'Billetterie payante activée',
            value: _isGratuit,
            onChanged: (v) => setState(() => _isGratuit = v),
          ),
          const SizedBox(height: 16),

          // Prix (si payant)
          if (!_isGratuit) ...[
            TextFormField(
              controller: _prixController,
              style: const TextStyle(color: Colors.white),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Prix par billet (FCFA) *',
                prefixIcon: Icon(Icons.monetization_on),
                hintText: 'Ex: 5000',
              ),
              validator: (v) {
                if (!_isGratuit) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Le prix est obligatoire';
                  }
                  final price = double.tryParse(v);
                  if (price == null || price <= 0) {
                    return 'Entrez un prix valide';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],

          // Capacité
          TextFormField(
            controller: _capaciteController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Nombre de places *',
              prefixIcon: Icon(Icons.people),
              hintText: 'Ex: 200',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'La capacité est obligatoire';
              }
              final cap = int.tryParse(v);
              if (cap == null || cap <= 0) {
                return 'Entrez un nombre valide';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Premium
          _buildSwitchCard(
            title: '⭐ Mettre en avant',
            subtitle: 'Apparaît dans le slider "À la une"',
            value: _isPremium,
            onChanged: (v) => setState(() => _isPremium = v),
          ),
        ],
      ),
    );
  }

  // ÉTAPE 4: Tags + Résumé
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🏷️ Tags & Résumé',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),

        // Champ tags
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Ajouter un tag (optionnel)',
                  prefixIcon: Icon(Icons.tag),
                  hintText: 'Ex: rock, famille...',
                ),
                onSubmitted: (_) => _addTag(),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _addTag,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(Icons.add, color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Tags ajoutés
        if (_tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags
                .map((tag) => Chip(
                      label: Text(
                        '#$tag',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.2),
                      deleteIconColor: Colors.white70,
                      onDeleted: () => setState(() => _tags.remove(tag)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
        ],

        const Divider(color: Colors.white10),
        const SizedBox(height: 16),

        // Résumé
        const Text(
          '📋 Récapitulatif',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildSummaryCard(),
      ],
    );
  }

  // ==================== WIDGETS HELPERS ====================

  Widget _buildDateSelector({
    required String label,
    required DateTime date,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('EEEE dd MMMM yyyy - HH:mm', 'fr_FR')
                        .format(date),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.edit_outlined,
              color: AppColors.textHint,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? activeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          _summaryRow(
            '🖼️ Image',
            _selectedImage != null ? '✅ Sélectionnée' : '❌ Manquante',
            _selectedImage != null ? AppColors.success : AppColors.error,
          ),
          _divider(),
          _summaryRow(
            '📝 Titre',
            _titreController.text.isEmpty ? '-' : _titreController.text,
            null,
          ),
          _divider(),
          _summaryRow(
            '🎭 Catégorie',
            _getCategoryLabel(_selectedCategory),
            null,
          ),
          _divider(),
          _summaryRow(
            '📅 Début',
            DateFormat('dd/MM/yyyy HH:mm').format(_dateDebut),
            null,
          ),
          _divider(),
          _summaryRow(
            '🏁 Fin',
            DateFormat('dd/MM/yyyy HH:mm').format(_dateFin),
            null,
          ),
          _divider(),
          _summaryRow(
            '📍 Ville',
            _villeController.text.isEmpty ? '-' : _villeController.text,
            null,
          ),
          _divider(),
          _summaryRow(
            '💰 Prix',
            _isGratuit ? 'Gratuit' : '${_prixController.text} FCFA',
            _isGratuit ? AppColors.success : AppColors.accent,
          ),
          _divider(),
          _summaryRow(
            '👥 Places',
            _capaciteController.text.isEmpty
                ? '-'
                : '${_capaciteController.text} personnes',
            null,
          ),
          _divider(),
          _summaryRow(
            '⭐ Premium',
            _isPremium ? 'Oui' : 'Non',
            _isPremium ? AppColors.accent : null,
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(color: Colors.white10, height: 16);

  Widget _summaryRow(String label, String value, Color? valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
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
      case EventCategory.autre: return '📅 Autre';
    }
  }
}