import '../api/services/drill_api.dart';
import '../models/drill.dart';
import '../utils/local_storage.dart';

class DrillRepository {
  final DrillApi _api;
  final LocalStorage _localStorage;

  DrillRepository(this._api, this._localStorage);

  Future<List<Drill>> getDrills({int? difficulty, String? search}) async {
    // Try to get from API first
    try {
      final drills = await _api.getDrills(
        difficulty: difficulty,
        search: search,
      );

      // Cache results
      await _cacheDrills(drills);

      return drills;
    } catch (e) {
      // On failure, try local cache
      return _getCachedDrills(difficulty: difficulty, search: search);
    }
  }

  Future<Drill> getDrill(int drillId) async {
    try {
      final drill = await _api.getDrill(drillId);

      // Cache this individual drill
      await _cacheDrill(drill);

      return drill;
    } catch (e) {
      // Try to get from local cache
      final cachedDrill = await _getCachedDrill(drillId);
      if (cachedDrill != null) {
        return cachedDrill;
      }

      // If not found in cache, rethrow
      rethrow;
    }
  }

  // Helper methods for caching
  Future<void> _cacheDrills(List<Drill> drills) async {
    await _localStorage.setItem(
      'drills',
      drills.map((e) => e.toJson()).toList(),
    );
  }

  Future<void> _cacheDrill(Drill drill) async {
    final drills = await _getCachedDrills();
    final index = drills.indexWhere((d) => d.id == drill.id);

    if (index >= 0) {
      drills[index] = drill;
    } else {
      drills.add(drill);
    }

    await _cacheDrills(drills);
  }

  Future<List<Drill>> _getCachedDrills({
    int? difficulty,
    String? search,
  }) async {
    final data = await _localStorage.getItem('drills');
    if (data == null) return [];

    List<Drill> drills = (data as List).map((e) => Drill.fromJson(e)).toList();

    // Apply filters if provided
    if (difficulty != null) {
      drills = drills.where((d) => d.difficulty == difficulty).toList();
    }

    if (search != null && search.isNotEmpty) {
      final searchLower = search.toLowerCase();
      drills = drills
          .where(
            (d) =>
                d.name.toLowerCase().contains(searchLower) ||
                d.description.toLowerCase().contains(searchLower) ||
                d.tags.any((tag) => tag.toLowerCase().contains(searchLower)),
          )
          .toList();
    }

    return drills;
  }

  Future<Drill?> _getCachedDrill(int drillId) async {
    final drills = await _getCachedDrills();
    try {
      return drills.firstWhere((d) => d.id == drillId);
    } catch (e) {
      return null;
    }
  }
}
