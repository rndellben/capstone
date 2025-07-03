import 'dart:typed_data';
import 'package:hydrozap_app/core/api/api_service.dart';

class PDFReportService {
  static Future<Uint8List?> getReportBytes({
    required String userId,
    required String deviceId,
  }) async {
    try {
      return await ApiService().generateReport(
        userId: userId,
        deviceId: deviceId,
      );
    } catch (e) {
      print('Error generating PDF: $e');
      return null;
    }
  }
} 