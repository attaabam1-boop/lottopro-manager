import 'package:flutter/material.dart';

import '../core/database.dart';
import '../models/customer.dart';
import '../services/whatsapp_service.dart';
import '../utils/formatters.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();
  late Future<List<Customer>> _customers;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    _customers = AppDatabase.instance.getCustomers(query: _searchController.text);
  }

  Future<void> _openForm([Customer? customer]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => CustomerFormDialog(customer: customer),
    );
    if (saved == true) setState(_refresh);
  }

  Future<void> _delete(Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete customer'),
        content: Text('Delete ${customer.name} and all related tickets/payments?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AppDatabase.instance.deleteCustomer(customer.id!);
      setState(_refresh);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add Customer'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search customers',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(_refresh),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Customer>>(
              future: _customers,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final customers = snapshot.data!;
                if (customers.isEmpty) {
                  return const Center(child: Text('No customers found'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: customers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(customer.name.substring(0, 1).toUpperCase()),
                        ),
                        title: Text(customer.name),
                        subtitle: Text(
                          '${customer.phone} | WhatsApp: ${customer.whatsapp}\nCreated ${dateFormatter.format(customer.createdAt)}',
                        ),
                        isThreeLine: true,
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              tooltip: 'WhatsApp',
                              onPressed: () => WhatsappService.openCustomerChat(customer.whatsapp),
                              icon: const Icon(Icons.chat_outlined),
                            ),
                            IconButton(
                              tooltip: 'Edit',
                              onPressed: () => _openForm(customer),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              onPressed: () => _delete(customer),
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

class CustomerFormDialog extends StatefulWidget {
  const CustomerFormDialog({super.key, this.customer});

  final Customer? customer;

  @override
  State<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _whatsapp;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.customer?.name ?? '');
    _phone = TextEditingController(text: widget.customer?.phone ?? '');
    _whatsapp = TextEditingController(text: widget.customer?.whatsapp ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final customer = Customer(
      id: widget.customer?.id,
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      whatsapp: _whatsapp.text.trim().isEmpty ? _phone.text.trim() : _whatsapp.text.trim(),
      createdAt: widget.customer?.createdAt ?? DateTime.now(),
    );
    if (widget.customer == null) {
      await AppDatabase.instance.insertCustomer(customer);
    } else {
      await AppDatabase.instance.updateCustomer(customer);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.customer == null ? 'Add customer' : 'Edit customer'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.trim().isEmpty ? 'Phone is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _whatsapp,
                decoration: const InputDecoration(labelText: 'WhatsApp number'),
                keyboardType: TextInputType.phone,
              ),
            ],
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
