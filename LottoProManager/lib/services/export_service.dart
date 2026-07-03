import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/database.dart';
import '../models/customer.dart';
import '../models/payment.dart';
import '../models/ticket.dart';
import '../utils/formatters.dart';

class ExportService {
  ExportService({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<File> exportToExcel() async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    final customers = await _database.getCustomers();
    final tickets = await _database.getTickets();
    final payments = await _database.getPayments();

    _writeCustomers(excel, customers);
    _writeTickets(excel, tickets);
    _writePayments(excel, payments);

    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'lotto_pro_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File(p.join(directory.path, fileName));
    await file.writeAsBytes(excel.encode() ?? <int>[], flush: true);
    return file;
  }

  void _writeCustomers(Excel excel, List<Customer> customers) {
    final sheet = excel['Customers'];
    sheet.appendRow(_textRow(['ID', 'Name', 'Phone', 'WhatsApp', 'Created']));
    for (final customer in customers) {
      sheet.appendRow([
        IntCellValue(customer.id ?? 0),
        TextCellValue(customer.name),
        TextCellValue(customer.phone),
        TextCellValue(customer.whatsapp),
        TextCellValue(dateTimeFormatter.format(customer.createdAt)),
      ]);
    }
  }

  void _writeTickets(Excel excel, List<Ticket> tickets) {
    final sheet = excel['Tickets'];
    sheet.appendRow(_textRow([
      'ID',
      'Customer ID',
      'Numbers',
      'Play Type',
      'Stake',
      'Draw Date',
      'Status',
      'Winnings',
    ]));
    for (final ticket in tickets) {
      sheet.appendRow([
        IntCellValue(ticket.id ?? 0),
        IntCellValue(ticket.customerId),
        TextCellValue(ticket.numbers),
        TextCellValue(ticket.playType),
        DoubleCellValue(ticket.stake),
        TextCellValue(dateFormatter.format(ticket.drawDate)),
        TextCellValue(ticket.status),
        DoubleCellValue(ticket.winnings),
      ]);
    }
  }

  void _writePayments(Excel excel, List<Payment> payments) {
    final sheet = excel['Payments'];
    sheet.appendRow(_textRow(['ID', 'Customer ID', 'Amount', 'Payment Type', 'Date']));
    for (final payment in payments) {
      sheet.appendRow([
        IntCellValue(payment.id ?? 0),
        IntCellValue(payment.customerId),
        DoubleCellValue(payment.amount),
        TextCellValue(payment.paymentType),
        TextCellValue(dateTimeFormatter.format(payment.date)),
      ]);
    }
  }

  List<CellValue?> _textRow(List<String> values) {
    return values.map<CellValue?>((value) => TextCellValue(value)).toList();
  }
}
