import 'dart:async';
import 'package:flutter/material.dart';

import 'stacked_trio_carousel.dart';

/// Enum representing the method of swiping the cards
enum SwipingMethod {
  /// Swiping is controlled by animations
  animationDriven,

  /// Swiping is controlled by user gestures
  userDriven,
}

/// Controller class for managing the StackedTrioCarousel
class StackedTrioCarouselController {
  /// AnimationController for managing card animations
  late AnimationController _animationController;

  /// Animations for card positions, opacity, and scaling
  late List<Animation<double>> positionAnimations;
  late List<Animation<double>> opacityAnimations;
  late List<Animation<double>> scaleAnimations;

  /// Timer for enabling auto-play functionality
  Timer? _timer;

  /// Current index of the active card in the carousel
  int _currentIndex = 0;

  /// Getter for the current index of the active card
  int get currentIndex => _currentIndex;

  /// Duration for the animation between cards
  final Duration animationDuration;

  /// Interval duration for auto-play transitions
  final Duration autoPlayInterval;

  /// Callback for when an animation starts
  VoidCallback? onAnimationStart;

  /// Callback for when an animation ends
  VoidCallback? onAnimationEnd;

  /// Callback for reporting animation progress
  void Function(double progress)? onAnimationProgress;

  /// The current swiping method (animation or user-driven)
  late SwipingMethod _swipingMethod;

  /// Getter for the swiping method
  SwipingMethod get swipingMethod => _swipingMethod;

  /// Flag indicating the swiping direction (forward or backward)
  bool _isSwipingforward = false;

  /// Getter for whether the swiping is forward
  bool get isSwipingforward => _isSwipingforward;

  /// Flag indicating if the card has been swapped during a swipe
  bool _cardSwapped = false;

  /// Getter for whether the card has been swapped
  bool get cardSwapped => _cardSwapped;

  /// Flag indicating if the swipe has passed the halfway point
  bool _hasPassedMid = false;

  /// Getter for whether the swipe has passed the halfway point
  bool get hasPassedMid => _hasPassedMid;

  /// Flag for enabling/disabling auto-play
  bool _autoPlay = true;

  /// Getter for whether auto-play is active
  bool get autoPlay => _autoPlay;

  get isAnimationCompleted =>
      _animationController.status == AnimationStatus.completed;

  /// Constructor for the controller
  /// - [tickerProvider] is required for animations
  /// - [animationDuration] defines the transition duration
  /// - [autoPlayInterval] defines the interval for auto-play
  /// - [autoPlay] specifies whether auto-play is enabled by default
  StackedTrioCarouselController({
    required TickerProvider tickerProvider,
    this.animationDuration = const Duration(seconds: 1),
    this.autoPlayInterval = const Duration(seconds: 3),
    bool autoPlay = true,
  }) {
    _animationController = AnimationController(
      vsync: tickerProvider,
      duration: animationDuration,
    )
      ..addStatusListener(animationStatusListener)
      ..addListener(_animationListener);

    _autoPlay = autoPlay;
    if (_autoPlay) {
      startAutoPlay();
      _swipingMethod = SwipingMethod.animationDriven;
    } else {
      _swipingMethod = SwipingMethod.userDriven;
    }
  }

  /// Listener for animation progress
  void _animationListener() {
    // Notify the listener about animation progress
    onAnimationProgress?.call(_animationController.value);
    switch (_swipingMethod) {
      case SwipingMethod.animationDriven:
        // Update halfway point flag for animation-driven swiping
        if (_animationController.value > 0.5 && !_hasPassedMid) {
          _hasPassedMid = true;
        }
        break;
      case SwipingMethod.userDriven:
        // Update halfway point flag based on swiping direction
        if (_isSwipingforward) {
          if (_animationController.value > 0.5 && !_hasPassedMid) {
            _hasPassedMid = true;
          }
        } else {
          if (_animationController.value < 0.5 && _hasPassedMid) {
            _hasPassedMid = true;
          }
        }
    }
  }

  /// Listener for animation status changes
  void animationStatusListener(status) {
    if (status == AnimationStatus.forward) {
      onAnimationStart?.call();
    } else if (status == AnimationStatus.completed) {
      _hasPassedMid = false;
      if (_swipingMethod == SwipingMethod.userDriven) {
        if (_isSwipingforward &&
            !_cardSwapped &&
            _animationController.value == 1) {
          onAnimationEnd?.call();
          _cardSwapped = true; // Mark that the card has been swapped
          _animationController.reset();
        }
      } else {
        if (_animationController.value == 1) {
          onAnimationEnd?.call();
          _animationController.reset();
        }
      }
    }
  }

  /// Initialize animations for positions, opacity, and scaling
  void initializeAnimations(
      StackedTrioCarouselParams params, xStartPoint, parentWidth) {
    positionAnimations = [
      // Position animation for the first card
      Tween(
          begin: _firstCardPosition(
            xPoint: xStartPoint,
            cardWidth: params.cardWidth,
            horizontalPadding: params.padding.horizontal,
            scaleRatio: params.scaleRatio,
          ),
          end: _secondCardPosition(
            cardWidth: params.cardWidth,
            horizontalPadding: params.padding.horizontal,
            scaleRatio: params.scaleRatio,
            width: parentWidth,
          )).animate(_animationController),
      // Position animation for the second card
      Tween(
          begin: _secondCardPosition(
            cardWidth: params.cardWidth,
            horizontalPadding: params.padding.horizontal,
            scaleRatio: params.scaleRatio,
            width: parentWidth,
          ),
          end: _thirdCardPosition(
            cardWidth: params.cardWidth,
            width: parentWidth,
          )).animate(_animationController),
      // Position animation for the third card
      Tween(
          begin: _thirdCardPosition(
            cardWidth: params.cardWidth,
            width: parentWidth,
          ),
          end: _firstCardPosition(
            xPoint: xStartPoint,
            cardWidth: params.cardWidth,
            horizontalPadding: params.padding.horizontal,
            scaleRatio: params.scaleRatio,
          )).animate(_animationController)
    ];

    opacityAnimations = [
      // Opacity animation for the first card
      Tween<double>(begin: params.minimumOpacity, end: params.minimumOpacity)
          .animate(_animationController),
      // Opacity animation for the second card
      Tween<double>(begin: params.minimumOpacity, end: params.maximumOpacity)
          .animate(_animationController),
      // Opacity animation for the third card
      Tween<double>(begin: params.maximumOpacity, end: params.minimumOpacity)
          .animate(_animationController),
    ];

    scaleAnimations = [
      // Scale animation for the first card
      Tween<double>(begin: params.scaleRatio, end: params.scaleRatio)
          .animate(_animationController),
      // Scale animation for the second card
      Tween<double>(begin: params.scaleRatio, end: 1)
          .animate(_animationController),
      // Scale animation for the third card
      Tween<double>(begin: 1, end: params.scaleRatio)
          .animate(_animationController),
    ];
  }

  /// Helper to calculate the position of the first card
  double _firstCardPosition({
    required double xPoint,
    required double cardWidth,
    required double scaleRatio,
    required double horizontalPadding,
  }) {
    return xPoint -
        ((cardWidth - cardWidth * scaleRatio) / 2) +
        horizontalPadding; // Adjust position based on scale ratio and padding
  }

  /// Helper to calculate the position of the second card
  double _secondCardPosition({
    required double width,
    required double cardWidth,
    required double scaleRatio,
    required double horizontalPadding,
  }) {
    return width -
        (cardWidth * scaleRatio + ((cardWidth - cardWidth * scaleRatio) / 2)) -
        horizontalPadding; // Adjust position based on scale ratio and padding
  }

  /// Helper to calculate the position of the third card
  double _thirdCardPosition({
    required double width,
    required double cardWidth,
  }) {
    return (width / 2) -
        (cardWidth / 2); // Center the card within the parent width
  }

  /// Starts the auto-play timer
  void startAutoPlay() {
    _stopTimer(); // Ensure no duplicate timers
    _timer = Timer.periodic(autoPlayInterval, (_) {
      next(); // Automatically move to the next card
    });
    _autoPlay = true;
    _swipingMethod = SwipingMethod.animationDriven;
  }

  /// Stops the auto-play timer
  void stopAutoPlay() {
    _stopTimer();
    _autoPlay = false;
  }

  /// Stops and cleans up the auto-play timer
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Animates to the next card in the carousel
  void next() {
    if (!_animationController.isAnimating) {
      _currentIndex = (_currentIndex + 1) % 3; // Circular logic for 3 cards
      _animationController.animateTo(1);
    }
  }

  /// Animates to the previous card in the carousel
  void previous() {
    if (!_animationController.isAnimating) {
      _currentIndex = (_currentIndex - 1 + 3) % 3; // Circular logic for 3 cards
      _animationController.animateTo(1);
    }
  }

  /// Stops the ongoing animation
  void stopAnimation() {
    _animationController.stop();
  }

  /// Animates to a specific value
  Future animateTo(double value) {
    return _animationController.animateTo(value);
  }

  /// Prepares for user interaction by stopping animations and auto-play
  void onUserInteractionStart() {
    _stopTimer();
    stopAnimation();
    _cardSwapped = false;
    _hasPassedMid = false;
  }

  /// Updates animation progress based on user drag gestures
  void onUserInteractionUpdate(DragUpdateDetails details, double cardWidth) {
    _swipingMethod =
        SwipingMethod.userDriven; // Set swiping method to user-driven

    // Determine swipe direction and update state
    if (_isSwipingforward != details.delta.dx < 0) {
      _hasPassedMid = false; // Reset mid-swipe state
    }
    _isSwipingforward = details.delta.dx < 0; // Update swiping direction

    if (!_cardSwapped) {
      double value = 1 -
          (details.globalPosition.dx /
              cardWidth); // Calculate new animation value
      _animationController.value =
          value.clamp(0, 1); // Clamp value between 0 and 1
    }
  }

  /// Handles cancellation of user interaction
  void onUserInteractionCancel() {
    _cardSwapped = false; // Reset card swapped state
    if (_autoPlay) {
      _swipingMethod = SwipingMethod.animationDriven;
    } else {
      _swipingMethod = SwipingMethod.userDriven;
    }
  }

  /// Handles the end of user interaction
  void onUserInteractionEnd() {
    _cardSwapped = false; // Reset card swapped state
    _swipingMethod = SwipingMethod.animationDriven;

    // Check if the swipe was significant enough to trigger an animation
    if (_animationController.value > 0.5 && _animationController.value != 1) {
      _animationController.animateTo(1).then(
        (value) {
          _hasPassedMid = false; // Reset mid-swipe state=
          _isSwipingforward = false;
          if (_autoPlay) {
            _swipingMethod = SwipingMethod.animationDriven;
          } else {
            _swipingMethod = SwipingMethod.userDriven;
          }
        },
      );
    } else if (_animationController.value < 0.5) {
      _animationController.animateTo(0).then(
        (value) {
          _hasPassedMid = false; // Reset mid-swipe state
        },
      );
    }
    if (_autoPlay) {
      startAutoPlay();
    }
  }

  /// Disposes of the animation controller and timer
  void dispose() {
    _animationController.dispose();
    _stopTimer();
  }
}
