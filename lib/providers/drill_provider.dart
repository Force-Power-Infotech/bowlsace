import 'package:flutter/foundation.dart';
import '../models/drill.dart';

class DrillProvider extends ChangeNotifier {
  List<Drill> _drills = [];
  Drill? _selectedDrill;
  bool _isLoading = false;

  List<Drill> get drills => _drills;
  Drill? get selectedDrill => _selectedDrill;
  bool get isLoading => _isLoading;

  void setDrills(List<Drill> drills) {
    _drills = drills;
    notifyListeners();
  }

  void setSelectedDrill(Drill drill) {
    _selectedDrill = drill;
    notifyListeners();
  }

  void clearSelectedDrill() {
    _selectedDrill = null;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void addDrill(Drill drill) {
    _drills.add(drill);
    notifyListeners();
  }

  void updateDrill(Drill drill) {
    final index = _drills.indexWhere((d) => d.id == drill.id);
    if (index != -1) {
      _drills[index] = drill;

      // Update selected drill if it's the same one
      if (_selectedDrill != null && _selectedDrill!.id == drill.id) {
        _selectedDrill = drill;
      }

      notifyListeners();
    }
  }

  void removeDrill(int drillId) {
    _drills.removeWhere((d) => d.id == drillId);

    // Clear selected drill if it's the same one
    if (_selectedDrill != null && _selectedDrill!.id == drillId) {
      _selectedDrill = null;
    }

    notifyListeners();
  }

  void clearDrills() {
    _drills = [];
    _selectedDrill = null;
    notifyListeners();
  }
}
