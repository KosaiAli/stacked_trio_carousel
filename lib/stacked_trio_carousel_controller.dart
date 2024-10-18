import 'package:flutter/material.dart';

class StackedTrioCarouselController extends ChangeNotifier {
  bool _isVisible = true;

  bool get isVisible => _isVisible;

  void show() {
    if (_isVisible != true) {
      _isVisible = true;
      notifyListeners();
    }
  }

  void hide() {
    if (_isVisible != false) {
      _isVisible = false;
      notifyListeners();
    }
  }
}
