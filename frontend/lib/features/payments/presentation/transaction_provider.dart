import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/core/network/api_client.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import '../domain/transaction_model.dart';

class TransactionLedgerState {
  final bool isLoading;
  final List<TransactionModel> transactions;
  final double totalAmount;
  final double escrowHeld;
  final String? errorMessage;
  final String statusFilter;

  const TransactionLedgerState({
    this.isLoading = false,
    this.transactions = const [],
    this.totalAmount = 0.0,
    this.escrowHeld = 0.0,
    this.errorMessage,
    this.statusFilter = 'all',
  });

  TransactionLedgerState copyWith({
    bool? isLoading,
    List<TransactionModel>? transactions,
    double? totalAmount,
    double? escrowHeld,
    String? errorMessage,
    String? statusFilter,
  }) {
    return TransactionLedgerState(
      isLoading: isLoading ?? this.isLoading,
      transactions: transactions ?? this.transactions,
      totalAmount: totalAmount ?? this.totalAmount,
      escrowHeld: escrowHeld ?? this.escrowHeld,
      errorMessage: errorMessage,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

class TransactionLedgerNotifier extends StateNotifier<TransactionLedgerState> {
  final ApiClient _apiClient;

  TransactionLedgerNotifier(this._apiClient) : super(const TransactionLedgerState()) {
    loadTransactions();
  }

  Future<void> loadTransactions({String? status}) async {
    final activeStatus = status ?? state.statusFilter;
    state = state.copyWith(isLoading: true, errorMessage: null, statusFilter: activeStatus);

    try {
      final queryParams = <String, String>{};
      if (activeStatus != 'all') {
        queryParams['status'] = activeStatus;
      }

      final queryStr = queryParams.isNotEmpty
          ? '?${Uri(queryParameters: queryParams).query}'
          : '';

      final response = await _apiClient.get('/payments/my-transactions$queryStr');

      if (response is Map<String, dynamic> && response['success'] == true) {
        final list = (response['data'] as List<dynamic>? ?? [])
            .map((item) => TransactionModel.fromJson(item as Map<String, dynamic>))
            .toList();

        final metrics = response['metrics'] as Map<String, dynamic>?;
        final totalVol = (metrics?['totalAmount'] is num)
            ? (metrics!['totalAmount'] as num).toDouble()
            : 0.0;
        final escrow = (metrics?['escrowHeld'] is num)
            ? (metrics!['escrowHeld'] as num).toDouble()
            : 0.0;

        state = state.copyWith(
          isLoading: false,
          transactions: list,
          totalAmount: totalVol,
          escrowHeld: escrow,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response['message']?.toString() ?? 'Failed to load transaction history',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void setFilter(String status) {
    if (state.statusFilter != status) {
      loadTransactions(status: status);
    }
  }
}

final transactionLedgerProvider =
    StateNotifierProvider<TransactionLedgerNotifier, TransactionLedgerState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TransactionLedgerNotifier(apiClient);
});

