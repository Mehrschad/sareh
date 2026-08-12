// پیشرفتِ کاربر در هفت‌خان.
//
// اینجا تنها *قاعده‌ی* بازشدنِ منزل‌هاست و هیچ I/O ندارد، تا بی‌نیاز از پایگاه
// داده آزمودنی بماند. ماندگاری با Drift انجام می‌شود؛ طرح‌واره‌ی جدول‌ها در
// docs/ARCHITECTURE.md آمده و `InMemoryProgressStore` تا آن هنگام جای آن را
// می‌گیرد.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

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
      if (!completedStations.contains(khan.stations[i].id)) return StationState.locked;
    }
    return StationState.unlocked;
  }

  JourneyProgress complete(String stationId) =>
      JourneyProgress({...completedStations, stationId});
}

class ProgressNotifier extends StateNotifier<JourneyProgress> {
  ProgressNotifier() : super(const JourneyProgress({}));

  void completeStation(String stationId) => state = state.complete(stationId);

  @visibleForTesting
  void restore(Set<String> stationIds) => state = JourneyProgress(stationIds);
}

final progressProvider =
    StateNotifierProvider<ProgressNotifier, JourneyProgress>((ref) => ProgressNotifier());
