import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../notifiers/auth_notifier.dart';

import '../services/api_service.dart';
import '../repositories/provider_repository.dart';
import '../repositories/ticket_repository.dart';

// Repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthRepository(apiService);
});

final providerRepositoryProvider = Provider<ProviderRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ProviderRepository(apiService);
});

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return TicketRepository(apiService);
});

// Data Providers
final providersListProvider = FutureProvider((ref) {
  final repository = ref.watch(providerRepositoryProvider);
  return repository.getProviders();
});

final ticketsListProvider = FutureProvider((ref) {
  final repository = ref.watch(ticketRepositoryProvider);
  return repository.getTickets();
});

final dashboardStatsProvider = FutureProvider((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getDashboardStats();
});

// Notifiers
final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

final ticketMessagesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, ticketId) {
      final repository = ref.watch(ticketRepositoryProvider);
      return repository.getTicketMessages(ticketId);
    });
