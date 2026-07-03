import 'package:flutter/material.dart';

import '../core/database.dart';
import '../models/customer.dart';
import '../models/ticket.dart';
import '../utils/formatters.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<Customer> _customers = [];
  List<Ticket> _tickets = [];
  Map<int, Customer> _customerMap = {};
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    final customers = await AppDatabase.instance.getCustomers(query: query);
    final tickets = await AppDatabase.instance.getTickets(query: query);
    final allCustomers = await AppDatabase.instance.getCustomers();
    if (!mounted) return;
    setState(() {
      _customers = customers;
      _tickets = tickets;
      _customerMap = {for (final customer in allCustomers) customer.id!: customer};
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Search name, phone, ticket number, or lotto numbers',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _search,
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          const SizedBox(height: 16),
          Text(
            'Customers',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (_customers.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No customer matches'),
              ),
            )
          else
            ..._customers.map(
              (customer) => Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                  title: Text(customer.name),
                  subtitle: Text('${customer.phone} | WhatsApp: ${customer.whatsapp}'),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Tickets',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (_tickets.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No ticket matches'),
              ),
            )
          else
            ..._tickets.map((ticket) {
              final customer = _customerMap[ticket.customerId];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('#${ticket.id ?? ''}')),
                  title: Text('${ticket.numbers} | ${ticket.playType}'),
                  subtitle: Text(
                    '${customer?.name ?? 'Customer ${ticket.customerId}'} | '
                    '${money(ticket.stake)} | ${ticket.status}',
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
