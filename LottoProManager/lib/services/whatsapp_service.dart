import 'package:url_launcher/url_launcher.dart';

import '../utils/constants.dart';
import '../utils/formatters.dart';

class WhatsappService {
  static Future<void> openBusinessChat({String? message}) {
    return _launchWhatsapp(businessWhatsappNumber, message: message);
  }

  static Future<void> openCustomerChat(String phone, {String? message}) {
    return _launchWhatsapp(normalizePhone(phone), message: message);
  }

  static String winnerMessage({
    required String customerName,
    required String ticketNumbers,
    required double winnings,
  }) {
    return 'Hello $customerName, congratulations. Your lotto ticket '
        '$ticketNumbers has won ${money(winnings)}. Please contact LottoPro '
        'Manager for payment.';
  }

  static Future<void> _launchWhatsapp(String phone, {String? message}) async {
    final normalized = normalizePhone(phone);
    final uri = Uri.parse(
      'https://wa.me/$normalized${message == null ? '' : '?text=${Uri.encodeComponent(message)}'}',
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not open WhatsApp link: $uri');
    }
  }
}
