// پیشرفتِ کاربر در هفت‌خان.
//
// [JourneyProgress] تنها *قاعده‌ی* بازشدنِ منزل‌هاست و هیچ I/O ندارد، تا
// بی‌نیاز از پایگاه داده آزمودنی بماند. [ProgressNotifier] آن را به Drift
// می‌بندد: هر منزلِ تمام‌شده همان‌جا روی دیسک می‌نشیند.
//
// خواندنِ نخست ناهمگام است، پس حالتِ آغازین تهی است و چند میلی‌ثانیه بعد پر
// می‌شود. صفحه‌ی هفت‌خان با تهی هم درست کار می‌کند (همه قفل جز منزلِ نخست)،
// پس نیازی به صفحه‌ی «در حالِ بارگذاری» نیست.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import '../../data/database.dart';
import '../../data/progress_repository.dart';
import '../../shared/models.dart';

enum StationState { locked, unlocked, completed }

@immutable
class JourneyProgress {
  const JourneyProgress(this.completedStations);

  /// شناسه‌ی منزل‌هایی که کاربر گذرانده است.
  final Set<String> completedStations;

  bool isCompleted(Station station) => completedStations.contains(station.id);

  int completedIn(Khan khan) =>
      khan.stations.where((s) => completedStations.contains(s.id)).length;

  /// یک منزل باز است اگر خودش گذرانده شده باشد، یا نخستین منزلِ نگذرانده باشد.
  ///
  /// راه هیچ‌گاه بن‌بست نمی‌شود: منزلِ بعدی همیشه باز است، حتی اگر کاربر
  /// منزلی را رها کرده باشد.
  StationState stateOf(Khan khan, int index) {
    final station = khan.stations[index];
    if (completedStations.contains(station.id)) return StationState.completed;
    for (var i = 0; i < index; i++) {
      if (!completedStations.contains(khan.stations[i].id)) {
        return StationState.locked;
      }
    }
    return StationState.unlocked;
  }

  JourneyProgress complete(String stationId) =>
      JourneyProgress({...completedStations, stationId});
}

class ProgressNotifier extends StateNotifier<JourneyProgress> {
  ProgressNotifier(this._repository) : super(const JourneyProgress({})) {
    _load();
  }

  final ProgressRepository? _repository;

  Future<void> _load() async {
    final stored = await _repository?.completedStations();
    if (stored != null && mounted) state = JourneyProgress(stored);
  }

  /// منزل را تمام‌شده ثبت می‌کند و روزِ فعال را برای زنجیره علامت می‌زند.
  ///
  /// حالت **پیش از** نوشتن روی دیسک به‌روز می‌شود: کاربر نباید منتظرِ SQLite
  /// بماند تا در باز شود. اگر نوشتن شکست بخورد، بدترین حالت این است که یک
  /// منزل دوباره باز شود — که از رابطِ یخ‌زده بهتر است.
  Future<void> completeStation(String stationId, {double ratio = 1.0}) async {
    state = state.complete(stationId);
    await _repository?.completeStation(stationId, ratio);
    await _repository?.markActiveDay();
  }

  @visibleForTesting
  void restore(Set<String> stationIds) => state = JourneyProgress(stationIds);
}

/// پایگاه داده‌ی اپ. در آزمون‌ها با نمونه‌ی درون‌حافظه جایگزین می‌شود.
final databaseProvider = Provider<SarehDatabase>((ref) {
  final db = SarehDatabase(openOnDisk());
  ref.onDispose(db.close);
  return db;
});

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(ref.watch(databaseProvider)),
);

final progressProvider =
    StateNotifierProvider<ProgressNotifier, JourneyProgress>(
  (ref) => ProgressNotifier(ref.watch(progressRepositoryProvider)),
);
