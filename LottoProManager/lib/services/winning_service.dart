import '../core/database.dart';
import '../models/ticket.dart';
import '../utils/formatters.dart';

class WinningResult {
  const WinningResult({
    required this.ticket,
    required this.matchCount,
    required this.isWinner,
    required this.winnings,
  });

  final Ticket ticket;
  final int matchCount;
  final bool isWinner;
  final double winnings;
}

class WinningService {
  WinningService({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<WinningResult>> checkTickets(String winningNumbers) async {
    final winningSet = parseLottoNumbers(winningNumbers).toSet();
    final tickets = await _database.getTickets();
    final results = <WinningResult>[];

    for (final ticket in tickets) {
      final ticketSet = parseLottoNumbers(ticket.numbers).toSet();
      final matchCount = ticketSet.intersection(winningSet).length;
      final isWinner = _isWinningTicket(ticket, winningSet, matchCount);
      final winnings = isWinner ? _calculateWinnings(ticket, matchCount) : 0.0;
      final updated = ticket.copyWith(
        status: isWinner ? 'Won' : 'Lost',
        winnings: winnings,
      );
      await _database.updateTicket(updated);
      results.add(
        WinningResult(
          ticket: updated,
          matchCount: matchCount,
          isWinner: isWinner,
          winnings: winnings,
        ),
      );
    }

    return results.where((result) => result.isWinner).toList();
  }

  bool _isWinningTicket(Ticket ticket, Set<String> winningSet, int matches) {
    final ticketNumbers = parseLottoNumbers(ticket.numbers);
    switch (ticket.playType) {
      case 'Direct':
        return ticketNumbers.length == winningSet.length &&
            ticketNumbers.every(winningSet.contains);
      case 'Banker':
        return matches >= 1;
      case 'Pair':
      case 'Perm 2':
      case 'Perm 3':
      case 'Perm 4':
      case 'Perm 5':
        return matches >= 2;
      default:
        return false;
    }
  }

  double _calculateWinnings(Ticket ticket, int matches) {
    final multiplier = switch (ticket.playType) {
      'Direct' => 8.0,
      'Banker' => 2.0,
      'Pair' => 3.0,
      'Perm 2' => 3.0,
      'Perm 3' => 4.0,
      'Perm 4' => 5.0,
      'Perm 5' => 6.0,
      _ => 1.0,
    };
    return ticket.stake * multiplier * matches.clamp(1, 5);
  }
}
