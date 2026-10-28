import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/core/network/api_client.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import '../domain/support_ticket_model.dart';

class SupportTicketsState {
  final bool isLoading;
  final List<SupportTicketModel> tickets;
  final SupportTicketModel? selectedTicket;
  final String statusFilter;
  final String? errorMessage;

  const SupportTicketsState({
    this.isLoading = false,
    this.tickets = const [],
    this.selectedTicket,
    this.statusFilter = 'all',
    this.errorMessage,
  });

  SupportTicketsState copyWith({
    bool? isLoading,
    List<SupportTicketModel>? tickets,
    SupportTicketModel? selectedTicket,
    String? statusFilter,
    String? errorMessage,
  }) {
    return SupportTicketsState(
      isLoading: isLoading ?? this.isLoading,
      tickets: tickets ?? this.tickets,
      selectedTicket: selectedTicket ?? this.selectedTicket,
      statusFilter: statusFilter ?? this.statusFilter,
      errorMessage: errorMessage,
    );
  }
}

class SupportTicketsNotifier extends StateNotifier<SupportTicketsState> {
  final ApiClient _apiClient;

  SupportTicketsNotifier(this._apiClient) : super(const SupportTicketsState()) {
    loadTickets();
  }

  Future<void> loadTickets({String? status}) async {
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

      final response = await _apiClient.get('/tickets/my$queryStr');

      if (response is Map<String, dynamic> && response['success'] == true) {
        final list = (response['data'] as List<dynamic>? ?? [])
            .map((item) => SupportTicketModel.fromJson(item as Map<String, dynamic>))
            .toList();

        state = state.copyWith(
          isLoading: false,
          tickets: list,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response['message']?.toString() ?? 'Failed to load support tickets',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<SupportTicketModel?> createTicket({
    required String subject,
    required String description,
    String category = 'other',
    String priority = 'medium',
    String? bookingId,
  }) async {
    try {
      final body = {
        'subject': subject.trim(),
        'description': description.trim(),
        'category': category,
        'priority': priority,
        if (bookingId != null && bookingId.isNotEmpty) 'bookingId': bookingId,
      };

      final response = await _apiClient.post('/tickets', body: body);

      if (response is Map<String, dynamic> && response['success'] == true) {
        final created = SupportTicketModel.fromJson(response['data'] as Map<String, dynamic>);
        await loadTickets();
        return created;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<SupportTicketModel?> loadTicketDetails(String id) async {
    try {
      final response = await _apiClient.get('/tickets/$id');
      if (response is Map<String, dynamic> && response['success'] == true) {
        final detail = SupportTicketModel.fromJson(response['data'] as Map<String, dynamic>);
        state = state.copyWith(selectedTicket: detail);
        return detail;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> addReply(String id, String message) async {
    try {
      final response = await _apiClient.post(
        '/tickets/$id/reply',
        body: {'message': message.trim()},
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        final updated = SupportTicketModel.fromJson(response['data'] as Map<String, dynamic>);
        state = state.copyWith(selectedTicket: updated);
        await loadTickets();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resolveTicket(String id) async {
    try {
      final response = await _apiClient.patch(
        '/tickets/$id/resolve',
        body: {'status': 'resolved'},
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        final updated = SupportTicketModel.fromJson(response['data'] as Map<String, dynamic>);
        state = state.copyWith(selectedTicket: updated);
        await loadTickets();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void setFilter(String status) {
    if (state.statusFilter != status) {
      loadTickets(status: status);
    }
  }
}

final supportTicketsProvider =
    StateNotifierProvider<SupportTicketsNotifier, SupportTicketsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SupportTicketsNotifier(apiClient);
});

