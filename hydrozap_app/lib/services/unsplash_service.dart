import 'package:http/http.dart' as http;
import 'dart:convert';

class UnsplashService {
  static const String _baseUrl = 'https://api.unsplash.com';
  static const String _clientId = 'wP0QHYEugyZ321jhonRZuOs1iUhhLHn9CcXgOlX8nD0'; // TODO: Move to environment variables

  Future<String?> getPlantImageUrl(String plantName) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search/photos?query=$plantName plant&per_page=1'),
        headers: {
          'Authorization': 'Client-ID $_clientId',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          return data['results'][0]['urls']['regular'];
        }
      }
      return null;
    } catch (e) {
      print('Error fetching Unsplash image: $e');
      return null;
    }
  }
} 