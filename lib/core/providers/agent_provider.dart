import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/services/xeris_api_service.dart';
import 'package:xeris_wallet/core/models/agent_models.dart';

final agentsProvider = FutureProvider<List<AgentModel>>((ref) async {
  final address = await ref.watch(walletAddressProvider.future);
  
  final timer = Timer.periodic(const Duration(seconds: 30), (_) {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  if (address == 'No Wallet' || address.isEmpty) return [];

  final agentsData = await XerisApiService.getAgentsRegistry(address);
  if (agentsData != null && agentsData is Map) {
    final List? agents = agentsData['agents'] ?? agentsData['data'];
    if (agents != null) {
      return agents.map((e) => AgentModel.fromJson(e)).toList();
    }
  }
  return [];
});

final openTasksProvider = FutureProvider<List<AgentTask>>((ref) async {
  final timer = Timer.periodic(const Duration(minutes: 1), (_) {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  final tasksData = await XerisApiService.getOpenTasks();
  if (tasksData != null && tasksData is Map) {
    final List? tasks = tasksData['tasks'] ?? tasksData['data'];
    if (tasks != null) {
      return tasks.map((e) => AgentTask.fromJson(e)).toList();
    }
  }
  return [];
});
