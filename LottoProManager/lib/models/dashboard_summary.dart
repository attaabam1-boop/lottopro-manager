class DashboardSummary {
  const DashboardSummary({
    required this.totalCustomers,
    required this.totalTickets,
    required this.totalStake,
    required this.totalWinnings,
    required this.totalPaid,
  });

  final int totalCustomers;
  final int totalTickets;
  final double totalStake;
  final double totalWinnings;
  final double totalPaid;

  double get profit => totalStake - totalWinnings;
  double get pendingPayments {
    final pending = totalWinnings - totalPaid;
    return pending < 0 ? 0 : pending;
  }
}
