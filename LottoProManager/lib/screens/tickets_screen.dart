import 'package:flutter/material.dart';

import '../core/database.dart';
import '../models/customer.dart';
import '../models/ticket.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final _searchController = TextEditingController();
  late Future<List<Ticket>> _tickets;
  Map<int, Customer> _customers = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    final customers = await AppDatabase.instance.getCustomers();
    _customers = {for (final customer in customers) customer.id!: customer};
  }

  void _load() {
    _tickets = AppDatabase.instance.getTickets(query: _searchController.text);
    _loadCustomers().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _openForm([Ticket? ticket]) async {
    await _loadCustomers();
    if (!mounted) return;
    if (_customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a customer before creating tickets')),
      );
      return;
    }
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => TicketFormDialog(
        ticket: ticket,
        customers: _customers.values.toList(),
      ),
    );
    if (saved == true) setState(_load);
  }

  Future<void> _delete(Ticket ticket) async {
    await AppDatabase.instance.deleteTicket(ticket.id!);
    setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tickets')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Ticket'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search ticket ID or lotto numbers',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(_load),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Ticket>>(
              future: _tickets,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final tickets = snapshot.data!;
                if (tickets.isEmpty) return const Center(child: Text('No tickets found'));
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: tickets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];
                    final customer = _customers[ticket.customerId];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text('#${ticket.id ?? ''}')),
                        title: Text('${ticket.numbers} | ${ticket.playType}'),
                        subtitle: Text(
                          '${customer?.name ?? 'Customer ${ticket.customerId}'}\n'
                          'Stake ${money(ticket.stake)} | Draw ${dateFormatter.format(ticket.drawDate)} | '
                          '${ticket.status} | Win ${money(ticket.winnings)}',
                        ),
                        isThreeLine: true,
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              onPressed: () => _openForm(ticket),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              onPressed: () => _delete(ticket),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TicketFormDialog extends StatefulWidget {
  const TicketFormDialog({
    super.key,
    required this.customers,
    this.ticket,
  });

  final List<Customer> customers;
  final Ticket? ticket;

  @override
  State<TicketFormDialog> createState() => _TicketFormDialogState();
}

class _TicketFormDialogState extends State<TicketFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late int _customerId;
  late String _playType;
  late String _status;
  late DateTime _drawDate;
  late final TextEditingController _numbers;
  late final TextEditingController _stake;

  @override
  void initState() {
    super.initState();
    _customerId = widget.ticket?.customerId ?? widget.customers.first.id!;
    _playType = widget.ticket?.playType ?? playTypes.first;
    _status = widget.ticket?.status ?? 'Pending';
    _drawDate = widget.ticket?.drawDate ?? DateTime.now();
    _numbers = TextEditingController(text: widget.ticket?.numbers ?? '');
    _stake = TextEditingController(text: widget.ticket?.stake.toString() ?? '');
  }

  @override
  void dispose() {
    _numbers.dispose();
    _stake.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _drawDate,
    );
    if (date != null) setState(() => _drawDate = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ticket = Ticket(
      id: widget.ticket?.id,
      customerId: _customerId,
      numbers: _numbers.text.trim(),
      playType: _playType,
      stake: double.parse(_stake.text.trim()),
      drawDate: _drawDate,
      status: _status,
      winnings: widget.ticket?.winnings ?? 0,
    );
    if (widget.ticket == null) {
      await AppDatabase.instance.insertTicket(ticket);
    } else {
      await AppDatabase.instance.updateTicket(ticket);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.ticket == null ? 'Add ticket' : 'Edit ticket'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: _customerId,
                  decoration: const InputDecoration(labelText: 'Customer'),
                  items: widget.customers
                      .map((customer) => DropdownMenuItem<int>(
                            value: customer.id,
                            child: Text(customer.name),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _customerId = value!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _numbers,
                  decoration: const InputDecoration(
                    labelText: 'Numbers',
                    hintText: '12-25-36',
                  ),
                  validator: (value) => value == null || parseLottoNumbers(value).length < 1
                      ? 'Enter lotto numbers'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _playType,
                  decoration: const InputDecoration(labelText: 'Play type'),
                  items: playTypes
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) => setState(() => _playType = value!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _stake,
                  decoration: const InputDecoration(labelText: 'Stake amount'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final amount = double.tryParse(value ?? '');
                    return amount == null || amount <= 0 ? 'Enter a valid stake' : null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: ticketStatuses
                      .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                      .toList(),
                  onChanged: (value) => setState(() => _status = value!),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Draw date: ${dateFormatter.format(_drawDate)}'),
                  trailing: IconButton(
                    tooltip: 'Pick draw date',
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save'),
        ),
      ],
    );
  }
}
