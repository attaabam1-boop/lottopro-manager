import 'package:flutter/material.dart';

import '../core/database.dart';
import '../models/customer.dart';
import '../services/whatsapp_service.dart';
import '../services/winning_service.dart';
import '../utils/formatters.dart';

class WinningScreen extends StatefulWidget {
  const WinningScreen({super.key});

  @override
  State<WinningScreen> createState() => _WinningScreenState();
}

class _WinningScreenState extends State<WinningScreen> {
  final _numbersController = TextEditingController();
  final _service = WinningService();
  bool _checking = false;
  List<WinningResult> _winners = [];
  Map<int, Customer> _customers = {};

  @override
  void dispose() {
    _numbersController.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    if (parseLottoNumbers(_numbersController.text).isEmpty) return;
    setState(() => _checking = true);
    final customers = await AppDatabase.instance.getCustomers();
    final winners = await _service.checkTickets(_numbersController.text);
    if (!mounted) return;
    setState(() {
      _customers = {for (final customer in customers) customer.id!: customer};
      _winners = winners;
      _checking = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${winners.length} winning ticket(s) found')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Winning Checker')),
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
                    'Input winning numbers',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _numbersController,
                    decoration: const InputDecoration(
                      labelText: 'Winning numbers',
                      hintText: '12-25-36',
                      prefixIcon: Icon(Icons.emoji_events_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _checking ? null : _check,
                    icon: _checking
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.fact_check_outlined),
                    label: const Text('Check All Tickets'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Winners',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          if (_winners.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No winners checked yet'),
              ),
            )
          else
            ..._winners.map((winner) {
              final customer = _customers[winner.ticket.customerId];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.emoji_events_outlined)),
                  title: Text('${winner.ticket.numbers} | ${winner.ticket.playType}'),
                  subtitle: Text(
                    '${customer?.name ?? 'Customer ${winner.ticket.customerId}'}\n'
                    '${winner.matchCount} match(es) | ${money(winner.winnings)}',
                  ),
                  isThreeLine: true,
                  trailing: customer == null
                      ? null
                      : IconButton(
                          tooltip: 'Message winner',
                          onPressed: () => WhatsappService.openCustomerChat(
                            customer.whatsapp,
                            message: WhatsappService.winnerMessage(
                              customerName: customer.name,
                              ticketNumbers: winner.ticket.numbers,
                              winnings: winner.winnings,
                            ),
                          ),
                          icon: const Icon(Icons.chat_outlined),
                        ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
