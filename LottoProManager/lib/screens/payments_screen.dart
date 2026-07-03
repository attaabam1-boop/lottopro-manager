import 'package:flutter/material.dart';

import '../core/database.dart';
import '../models/customer.dart';
import '../models/payment.dart';
import '../models/ticket.dart';
import '../utils/formatters.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<Customer> _customers = [];
  List<Payment> _payments = [];
  List<Ticket> _tickets = [];
  int? _customerId;
  final _amount = TextEditingController();
  String _paymentType = 'Partial';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final customers = await AppDatabase.instance.getCustomers();
    final payments = await AppDatabase.instance.getPayments();
    final tickets = await AppDatabase.instance.getTickets();
    if (!mounted) return;
    setState(() {
      _customers = customers;
      _payments = payments;
      _tickets = tickets;
      _customerId ??= customers.isEmpty ? null : customers.first.id;
    });
  }

  double _wonForCustomer(int customerId) {
    return _tickets
        .where((ticket) => ticket.customerId == customerId)
        .fold<double>(0, (sum, ticket) => sum + ticket.winnings);
  }

  double _paidForCustomer(int customerId) {
    return _payments
        .where((payment) => payment.customerId == customerId)
        .fold<double>(0, (sum, payment) => sum + payment.amount);
  }

  Future<void> _savePayment() async {
    if (_customerId == null) return;
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) return;
    await AppDatabase.instance.insertPayment(
      Payment(
        customerId: _customerId!,
        amount: amount,
        paymentType: _paymentType,
        date: DateTime.now(),
      ),
    );
    _amount.clear();
    await _load();
  }

  void _fillFullPayment() {
    if (_customerId == null) return;
    final pending = _wonForCustomer(_customerId!) - _paidForCustomer(_customerId!);
    _amount.text = (pending < 0 ? 0 : pending).toStringAsFixed(2);
    setState(() => _paymentType = 'Full');
  }

  @override
  Widget build(BuildContext context) {
    final customerMap = {for (final customer in _customers) customer.id!: customer};
    final selectedPending = _customerId == null
        ? 0.0
        : (_wonForCustomer(_customerId!) - _paidForCustomer(_customerId!)).clamp(0, double.infinity);

    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Record payment',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _customerId,
                    decoration: const InputDecoration(labelText: 'Customer'),
                    items: _customers
                        .map((customer) => DropdownMenuItem(value: customer.id, child: Text(customer.name)))
                        .toList(),
                    onChanged: (value) => setState(() => _customerId = value),
                  ),
                  const SizedBox(height: 12),
                  Text('Pending for selected customer: ${money(selectedPending)}'),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Partial', label: Text('Partial')),
                      ButtonSegment(value: 'Full', label: Text('Full')),
                    ],
                    selected: {_paymentType},
                    onSelectionChanged: (selection) {
                      setState(() => _paymentType = selection.first);
                      if (selection.first == 'Full') _fillFullPayment();
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _savePayment,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Payment'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Payment history',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (_payments.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No payments recorded'),
              ),
            )
          else
            ..._payments.map((payment) {
              final customer = customerMap[payment.customerId];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
                  title: Text('${customer?.name ?? 'Customer ${payment.customerId}'} | ${money(payment.amount)}'),
                  subtitle: Text('${payment.paymentType} | ${dateTimeFormatter.format(payment.date)}'),
                ),
              );
            }),
        ],
      ),
    );
  }
}
