import 'package:flutter/material.dart';

import '../core/database.dart';
import '../models/dashboard_summary.dart';
import '../services/export_service.dart';
import '../services/whatsapp_service.dart';
import '../utils/formatters.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardSummary> _summary;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _summary = AppDatabase.instance.getDashboardSummary();
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final file = await ExportService().exportToExcel();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Excel exported: ${file.path}')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Business WhatsApp',
            onPressed: () => WhatsappService.openBusinessChat(),
            icon: const Icon(Icons.chat_outlined),
          ),
          IconButton(
            tooltip: 'Export Excel',
            onPressed: _exporting ? null : _export,
            icon: _exporting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download_outlined),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => setState(_refresh),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<DashboardSummary>(
        future: _summary,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final cards = [
            StatCard(
              title: 'Total Customers',
              value: '${data.totalCustomers}',
              icon: Icons.people_outline,
            ),
            StatCard(
              title: 'Total Tickets',
              value: '${data.totalTickets}',
              icon: Icons.confirmation_number_outlined,
            ),
            StatCard(
              title: 'Total Stake',
              value: money(data.totalStake),
              icon: Icons.savings_outlined,
              color: Colors.indigo,
            ),
            StatCard(
              title: 'Total Winnings',
              value: money(data.totalWinnings),
              icon: Icons.emoji_events_outlined,
              color: Colors.orange,
            ),
            StatCard(
              title: 'Total Paid',
              value: money(data.totalPaid),
              icon: Icons.payments_outlined,
              color: Colors.green,
            ),
            StatCard(
              title: 'Profit',
              value: money(data.profit),
              icon: Icons.trending_up,
              color: data.profit >= 0 ? Colors.teal : Colors.red,
            ),
            StatCard(
              title: 'Pending Payments',
              value: money(data.pendingPayments),
              icon: Icons.pending_actions_outlined,
              color: Colors.deepPurple,
            ),
          ];

          return RefreshIndicator(
            onRefresh: () async => setState(_refresh),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.sizeOf(context).width >= 1000 ? 3 : 1,
                childAspectRatio: MediaQuery.sizeOf(context).width >= 1000 ? 2.8 : 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) => cards[index],
            ),
          );
        },
      ),
    );
  }
}
