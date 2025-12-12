import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:magicslides/features/generator/domain/presentation_request_model.dart';

class GeneratorRepository {
  Future<Map<String, dynamic>> generatePresentation(
    PresentationRequest request,
  ) async {
    final url = Uri.parse(
      'https://api.magicslides.app/public/api/ppt_from_topic',
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData;
    } else {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }
}
