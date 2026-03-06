import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../data/services/api_service.dart';

/// The name of the Hive box used to queue pending (offline) sales.
const String kPendingSalesBox = 'pending_sales';

// ─────────────────────────────────────────────────────────────────────────────
// Offline Queue Service
// ─────────────────────────────────────────────────────────────────────────────
class OfflineSyncService {
  final ApiService _api;

  OfflineSyncService(this._api);

  /// Checks connectivity. Returns true if online.
  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }

  /// Queue a sale locally when offline.
  Future<void> queueSale(Map<String, dynamic> saleData) async {
    final box = Hive.box(kPendingSalesBox);
    final key = DateTime.now().millisecondsSinceEpoch.toString();
    await box.put(key, jsonEncode(saleData));
    debugPrint('[OfflineQueue] Sale queued locally. Total pending: ${box.length}');
  }

  /// Returns the number of pending (un-synced) sales.
  int pendingCount() {
    final box = Hive.box(kPendingSalesBox);
    return box.length;
  }

  /// Attempts to sync all queued sales to the server.
  /// Returns how many were successfully synced.
  Future<int> syncPending() async {
    final box = Hive.box(kPendingSalesBox);
    if (box.isEmpty) return 0;

    int synced = 0;
    final keys = box.keys.toList();

    for (final key in keys) {
      try {
        final raw = box.get(key);
        final saleData = jsonDecode(raw as String);
        await _api.post('/sales', data: saleData);
        await box.delete(key);
        synced++;
        debugPrint('[OfflineQueue] Synced sale key=$key ✓');
      } catch (e) {
        debugPrint('[OfflineQueue] Failed to sync key=$key: $e');
        // Keep in queue for next retry
      }
    }

    return synced;
  }
}

final offlineSyncProvider = Provider<OfflineSyncService>((ref) {
  return OfflineSyncService(ref.read(apiServiceProvider));
});

// ─────────────────────────────────────────────────────────────────────────────
// Connectivity notifier — watches real-time connectivity changes
// ─────────────────────────────────────────────────────────────────────────────
class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier() : super(true) {
    _init();
  }

  void _init() async {
    // Initial check
    final result = await Connectivity().checkConnectivity();
    state = result.any((r) => r != ConnectivityResult.none);

    // Subscribe to changes
    Connectivity().onConnectivityChanged.listen((results) {
      state = results.any((r) => r != ConnectivityResult.none);
    });
  }
}

final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier();
});

// ─────────────────────────────────────────────────────────────────────────────
// Offline Banner Widget — shows a red bar at top when offline
// ─────────────────────────────────────────────────────────────────────────────
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider);

    if (isOnline) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: const Color(0xFFB91C1C),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: const Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '⚠ Xiriirka Internetku ma shaqaynayo — Offline Mode. Iibka ayaa local loo keydinayaa.',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sync Button Widget — use in app bar to manually trigger sync
// ─────────────────────────────────────────────────────────────────────────────
class SyncPendingButton extends ConsumerStatefulWidget {
  const SyncPendingButton({super.key});

  @override
  ConsumerState<SyncPendingButton> createState() => _SyncPendingButtonState();
}

class _SyncPendingButtonState extends ConsumerState<SyncPendingButton> {
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final syncService = ref.read(offlineSyncProvider);
    final pending = syncService.pendingCount();
    final isOnline = ref.watch(connectivityProvider);

    if (pending == 0 || !isOnline) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: TextButton.icon(
        onPressed: _isSyncing ? null : _doSync,
        icon: _isSyncing
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.cloud_upload_outlined, size: 16),
        label: Text('Sync ($pending)', style: const TextStyle(fontSize: 12)),
        style: TextButton.styleFrom(
          foregroundColor: Colors.orange,
          backgroundColor: Colors.orange.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Future<void> _doSync() async {
    setState(() => _isSyncing = true);
    final synced = await ref.read(offlineSyncProvider).syncPending();
    setState(() => _isSyncing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(synced > 0
              ? '✓ $synced iib ayaa si guul leh u is-duway!'
              : 'Sync waa fashilantay. Isku day mar kale.'),
          backgroundColor: synced > 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        ),
      );
    }
  }
}
