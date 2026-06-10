// lib/services/cloudinary_service.dart

import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';

class CloudinaryService {
  static const String _baseUrl = 
      'https://api.cloudinary.com/v1_1/${AppConfig.cloudinaryCloudName}';

  // Upload d'une image
  static Future<CloudinaryResponse> uploadImage({
    required File imageFile,
    required String folder,
    String? publicId,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/image/upload');
      final request = http.MultipartRequest('POST', uri);
      
      // Paramètres obligatoires
      request.fields['upload_preset'] = AppConfig.cloudinaryUploadPreset;
      request.fields['folder'] = folder;
      
      // ID personnalisé optionnel
      if (publicId != null) {
        request.fields['public_id'] = publicId;
      }
      
      // Transformation automatique (qualité auto + format auto)
      request.fields['quality'] = 'auto';
      request.fields['fetch_format'] = 'auto';
      
      // Ajout du fichier
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CloudinaryResponse(
          secureUrl: data['secure_url'],
          publicId: data['public_id'],
          width: data['width'],
          height: data['height'],
          format: data['format'],
          bytes: data['bytes'],
        );
      } else {
        throw Exception('Erreur Cloudinary: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur upload image: $e');
    }
  }

  // Upload multiple images
  static Future<List<CloudinaryResponse>> uploadMultipleImages({
    required List<File> images,
    required String folder,
  }) async {
    final futures = images.map(
      (image) => uploadImage(imageFile: image, folder: folder),
    );
    return await Future.wait(futures);
  }

  // Supprimer une image
  static Future<bool> deleteImage(String publicId) async {
    try {
      final uri = Uri.parse('$_baseUrl/image/destroy');
      final response = await http.post(
        uri,
        body: {
          'public_id': publicId,
          'api_key': AppConfig.cloudinaryApiKey,
        },
      );
      final data = json.decode(response.body);
      return data['result'] == 'ok';
    } catch (e) {
      return false;
    }
  }

  // Générer URL optimisée pour thumbnail
  static String getThumbnailUrl(String originalUrl, {
    int width = 300,
    int height = 200,
  }) {
    return originalUrl.replaceFirst(
      '/upload/',
      '/upload/w_$width,h_$height,c_fill,q_auto,f_auto/',
    );
  }

  // Générer URL optimisée pour bannière
  static String getBannerUrl(String originalUrl) {
    return originalUrl.replaceFirst(
      '/upload/',
      '/upload/w_800,h_400,c_fill,q_auto,f_auto/',
    );
  }

  // URL pour profil (cercle)
  static String getProfileUrl(String originalUrl) {
    return originalUrl.replaceFirst(
      '/upload/',
      '/upload/w_150,h_150,c_fill,g_face,r_max,q_auto/',
    );
  }
}

class CloudinaryResponse {
  final String secureUrl;
  final String publicId;
  final int width;
  final int height;
  final String format;
  final int bytes;

  CloudinaryResponse({
    required this.secureUrl,
    required this.publicId,
    required this.width,
    required this.height,
    required this.format,
    required this.bytes,
  });
}