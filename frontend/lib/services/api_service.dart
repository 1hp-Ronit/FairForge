import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  /// Uploads a dataset to FastAPI and returns header details.
  static Future<Map<String, dynamic>> uploadFile({
    required String filename,
    required List<int> fileBytes,
  }) async {
    final uri = Uri.parse('$baseUrl/upload');
    final request = http.MultipartRequest('POST', uri);

    // Determine content type based on extension
    MediaType? contentType;
    if (filename.endsWith('.csv')) {
      contentType = MediaType('text', 'csv');
    } else if (filename.endsWith('.json')) {
      contentType = MediaType('application', 'json');
    }

    final multipartFile = http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: filename,
      contentType: contentType,
    );

    request.files.add(multipartFile);

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(responseBody);
    } else {
      throw Exception('Failed to upload file: $responseBody');
    }
  }

  /// Triggers the ML Bias Audit.
  static Future<Map<String, dynamic>> runAudit({
    required String fileId,
    required String filename,
    required List<String> protectedAttributes,
    required String domain,
  }) async {
    final uri = Uri.parse('$baseUrl/audit');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'file_id': fileId,
        'filename': filename,
        'protected_attributes': protectedAttributes,
        'domain': domain,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(responseBody(response));
    } else {
      throw Exception('Audit failed: ${responseBody(response)}');
    }
  }

  /// Fetches paginated history with optional filters.
  static Future<Map<String, dynamic>> getAuditHistory({
    String? domain,
    String? riskLevel,
    String? search,
    int page = 1,
    int perPage = 10,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (domain != null && domain != 'All') 'domain': domain,
      if (riskLevel != null && riskLevel != 'All') 'risk_level': riskLevel,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final uri = Uri.parse('$baseUrl/history').replace(queryParameters: queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(responseBody(response));
    } else {
      throw Exception('Failed to fetch history: ${responseBody(response)}');
    }
  }

  /// Fetches details for a specific audit by ID.
  static Future<Map<String, dynamic>> getAuditDetails(String auditId) async {
    final uri = Uri.parse('$baseUrl/audit/$auditId');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(responseBody(response));
    } else {
      throw Exception('Failed to load audit: ${responseBody(response)}');
    }
  }

  /// Applies debiasing mitigations to a specific audit.
  static Future<Map<String, dynamic>> applyMitigations({
    required String auditId,
    required List<String> mitigations,
  }) async {
    final uri = Uri.parse('$baseUrl/audit/$auditId/apply');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mitigations': mitigations}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(responseBody(response));
    } else {
      throw Exception('Failed to apply mitigations: ${responseBody(response)}');
    }
  }

  /// Returns the literal URL needed to fetch the PDF. This can be passed to url_launcher.
  static String getExportPdfUrl(String auditId) {
    return '$baseUrl/audit/$auditId/export';
  }

  /// Helper to decode utf8 properly
  static String responseBody(http.Response res) {
    return utf8.decode(res.bodyBytes);
  }
}
