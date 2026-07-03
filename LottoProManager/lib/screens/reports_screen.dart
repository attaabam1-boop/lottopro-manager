import 'package:flutter/material.dart';

import '../core/database.dart';
import '../models/report_summary.dart';
import '../utils/formatters.dart';
import '../widgets/stat_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _period = 'Daily';
  late Future<ReportSummary> _report;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final now = DateTime.now();
    final start = switch (_period) {
      'Weekly' => DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1)),
      'Monthly' => DateTime(now.year, now.month),
      _ => DateTime(now.year, now.month, now.day),
    };
    final end = switch (_period) {
      'Weekly' => start.add(const Duration(days: 7)),
      'Monthly' => DateTime(now.year, now.month + 1),
      _ => start.add(const Duration(days: 1)),
    };
    _report = AppDatabase.instance.getReportSummary(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Daily', label: Text('Daily'), icon: Icon(Icons.today_outlined)),
              ButtonSegment(value: 'Weekly', label: Text('Weekly'), icon: Icon(Icons.date_range_outlined)),
              ButtonSegment(value: 'Monthly', label: Text('Monthly'), icon: Icon(Icons.calendar_month_outlined)),
            ],
            selected: {_period},
            onSelectionChanged: (selection) {
              setState(() {
                _period = selection.first;
                _refresh();
              });
            },
          ),
          const SizedBox(height: 16),
          FutureBuilder<ReportSummary>(
            future: _report,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final report = snapshot.data!;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: MediaQuery.sizeOf(context).width >= 1000 ? 2 : 1,
                childAspectRatio: MediaQuery.sizeOf(context).width >= 1000 ? 3.2 : 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  StatCard(
                    title: 'Total Stake',
                    value: money(report.totalStake),
                    icon: Icons.savings_outlined,
                    color: Colors.indigo,
                  ),
                  StatCard(
                    title: 'Total Winnings',
                    value: money(report.totalWinnings),
                    icon: Icons.emoji_events_outlined,
                    color: Colors.orange,
                  ),
                  StatCard(
                    title: 'Total Profit',
                    value: money(report.totalProfit),
                    icon: Icons.trending_up,
                    color: report.totalProfit >= 0 ? Colors.teal : Colors.red,
                  ),
                  StatCard(
                    title: 'Pending Payments',
                    value: money(report.pendingPayments),
                    icon: Icons.pending_actions_outlined,
                    color: Colors.deepPurple,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
