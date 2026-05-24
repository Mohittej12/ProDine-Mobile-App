import 'package:intl/intl.dart';

class Formatters {
  static String formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(amount);
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
}