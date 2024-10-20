import 'package:flutter/material.dart';

class StackedTrioCarouselController extends ChangeNotifier {
  bool _isVisible = true;
  bool _isAnimating = true;

  bool get isVisible => _isVisible;
  bool get isAnimating => _isAnimating;

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

  void stop() {
    if (_isAnimating != false) {
      _isAnimating = false;
      notifyListeners();
    }
  }

  void play() {
    if (_isAnimating != true) {
      _isAnimating = true;
      notifyListeners();
    }
  }
}
