import 'dart:async';
import 'package:flutter/material.dart';

import 'stacked_trio_carousel.dart';
import 'dart:math' as math;

/// Enum representing the method of swiping the cards
enum SwipingMethod {
  /// Swiping is controlled by animations
  animationDriven,

  /// Swiping is controlled by user gestures
  userDriven,
}

enum SwipingDirection {
  /// Swiping from Right to Left
  rtl,

  /// Swiping from Left to Right
  ltr
}

/// Controller class for managing the StackedTrioCarousel
class StackedTrioCarouselController {
  /// AnimationController for managing card animations
  late AnimationController _animationController;

  /// Animations for card positions, opacity, and scaling
  late List<Animation<Offset>> positionAnimations;
  late List<Animation<double>> opacityAnimations;
  late List<Animation<double>> scaleAnimations;

  late Offset _centerPoint;

  /// Timer for enabling auto-play functionality
  Timer? _timer;

  // /// Current index of the active card in the carousel
  // int _currentIndex = 0;

  // /// Getter for the current index of the active card
  // int get currentIndex => _currentIndex;

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

  /// The Offset of the Widget relative to the main screen
  late Offset _widgetOffset;

  /// The Size of widget
  late Size _widgetSize;

  /// Getter for the swiping method
  SwipingMethod get swipingMethod => _swipingMethod;

  /// Direction of Swiping
  late SwipingDirection _swipingDirection;

  SwipingDirection get swipingDirection => _swipingDirection;

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

  bool get isAnimationCompleted =>
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
    SwipingDirection swipingDirection = SwipingDirection.rtl,
    bool autoPlay = true,
  }) {
    _swipingDirection = swipingDirection;
    _animationController = AnimationController(
      // lowerBound: -1,
      value: 0,
      upperBound: 1,
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
    // print(_swipingDirection);
    switch (_swipingMethod) {
      case SwipingMethod.animationDriven:
        // Update halfway point flag for animation-driven swiping
        if (_animationController.value.abs() > 0.5 && !_hasPassedMid) {
          _hasPassedMid = true;
        }
        break;
      case SwipingMethod.userDriven:
        // Update halfway point flag based on swiping direction
        if (_isSwipingforward) {
          if (_animationController.value.abs() > 0.5 && !_hasPassedMid) {
            _hasPassedMid = true;
          }
        } else {
          // if (_animationController.value < 0.5 && _hasPassedMid) {
          //   _hasPassedMid = true; // is indeed true :D
          // }
        }
    }
  }

  /// Listener for animation status changes
  void animationStatusListener(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
      onAnimationStart?.call();
    } else if (status == AnimationStatus.completed) {
      _hasPassedMid = false;
      if (_swipingMethod == SwipingMethod.userDriven) {
        // TODO: Fix the behaviour
        if (_isSwipingforward && !_cardSwapped && _animationController.value.abs() == 1) {
          onAnimationEnd?.call();
          _cardSwapped = true; // Mark that the card has been swapped
          _animationController.value = 0;
        }
      } else {
        if (_animationController.value.abs() == 1) {
          onAnimationEnd?.call();
          _animationController.value = 0;
        }
      }
    }
  }

  /// Initialize animations for positions, opacity, and scaling
  void initializeAnimations({
    required StackedTrioCarouselParams params,
    required Size widgetSize,
    required Offset widgetOffset,
  }) {
    final xCenterPoint = (widgetSize.width - params.cardWidth) / 2;
    final yCenterPoint = (widgetSize.height - params.cardHeight) / 2;
    _widgetOffset = widgetOffset;
    _widgetSize = widgetSize;
    _centerPoint = Offset(xCenterPoint, yCenterPoint);
    // Position animation for the first card
    updateAnimations(params);
  }

  void updateAnimations(StackedTrioCarouselParams params) {
    bool forward = (_swipingDirection == SwipingDirection.rtl);
    // bool forward = false;

    final firstPos = _firstCardPosition(
      padding: params.padding,
      angle: params.angle,
    );

    final secondPos = _secondCardPosition(
      padding: params.padding,
      angle: params.angle,
    );

    final thirdPos = _centerPoint;

    Tween<T> biTween<T>(T a, T b) => Tween(begin: a, end: b);
    if (forward) {
      positionAnimations = [
        biTween(firstPos, secondPos).animate(_animationController),
        biTween(secondPos, thirdPos).animate(_animationController),
        biTween(thirdPos, firstPos).animate(_animationController),
      ];
    } else {
      positionAnimations = [
        biTween(secondPos, firstPos).animate(_animationController),
        biTween(firstPos, thirdPos).animate(_animationController),
        biTween(thirdPos, secondPos).animate(_animationController),
      ];
    }

    if (forward) {
      scaleAnimations = [
        // Scale animation for the first card
        biTween(params.scaleRatio, params.scaleRatio).animate(_animationController),
        // Scale animation for the second card
        biTween(params.scaleRatio, 1.0).animate(_animationController),
        // Scale animation for the third card
        biTween(1.0, params.scaleRatio).animate(_animationController),
      ];
    } else {
      scaleAnimations = [
        // Scale animation for the first card
        biTween(params.scaleRatio, params.scaleRatio).animate(_animationController),
        // Scale animation for the third card
        biTween(params.scaleRatio, 1.0).animate(_animationController),
        // Scale animation for the second card
        biTween(1.0, params.scaleRatio).animate(_animationController),
      ];
    }

    // positionAnimations = [
    //   biTween(firstPos, secondPos).animate(_animationController),
    //   biTween(thirdPos, firstPos).animate(_animationController),
    //   biTween(secondPos, thirdPos).animate(_animationController),
    // ];

    opacityAnimations = [
      // Opacity animation for the first card
      biTween(params.minimumOpacity, params.minimumOpacity).animate(_animationController),
      // Opacity animation for the second card
      biTween(params.minimumOpacity, params.maximumOpacity).animate(_animationController),
      // Opacity animation for the third card
      biTween(params.maximumOpacity, params.minimumOpacity).animate(_animationController),
    ];

    opacityAnimations = [
      // Opacity animation for the first card
      biTween(params.minimumOpacity, params.minimumOpacity).animate(_animationController),
      // Opacity animation for the third card
      biTween(params.maximumOpacity, params.minimumOpacity).animate(_animationController),
      // Opacity animation for the second card
      biTween(params.minimumOpacity, params.maximumOpacity).animate(_animationController),
    ];

    // scaleAnimations = [
    //   // Scale animation for the first card
    //   biTween(params.scaleRatio, params.scaleRatio).animate(_animationController),
    //   // Scale animation for the third card
    //   biTween(1.0, params.scaleRatio).animate(_animationController),
    //   // Scale animation for the second card
    //   biTween(params.scaleRatio, 1.0).animate(_animationController),
    // ];

    // positionAnimations = [biTween(firstPos, secondPos).animate(_animationController)];
    // opacityAnimations = [
    //   biTween(params.minimumOpacity, params.minimumOpacity).animate(_animationController)
    // ];
    // scaleAnimations = [
    //   biTween(params.scaleRatio, params.scaleRatio).animate(_animationController)
    // ];

    // if (forward) {
    //   positionAnimations.add(biTween(secondPos, thirdPos).animate(_animationController));
    //   positionAnimations.add(biTween(thirdPos, firstPos).animate(_animationController));
    //   opacityAnimations.add(biTween(params.minimumOpacity, params.maximumOpacity)
    //       .animate(_animationController));
    //   opacityAnimations.add(biTween(params.maximumOpacity, params.minimumOpacity)
    //       .animate(_animationController));
    //   scaleAnimations.add(biTween(params.scaleRatio, 1.0).animate(_animationController));
    //   scaleAnimations.add(biTween(1.0, params.scaleRatio).animate(_animationController));
    // } else {
    //   positionAnimations.add(biTween(thirdPos, firstPos).animate(_animationController));
    //   positionAnimations.add(biTween(secondPos, thirdPos).animate(_animationController));
    //   opacityAnimations.add(biTween(params.maximumOpacity, params.minimumOpacity)
    //       .animate(_animationController));
    //   opacityAnimations.add(biTween(params.minimumOpacity, params.maximumOpacity)
    //       .animate(_animationController));
    //   scaleAnimations.add(biTween(1.0, params.scaleRatio).animate(_animationController));
    //   scaleAnimations.add(biTween(params.scaleRatio, 1.0).animate(_animationController));
    // }
  }

  /// Helper to calculate the position of the first card
  Offset _firstCardPosition({
    required EdgeInsets padding,
    required double angle,
  }) {
    final xCord = _centerPoint.dx * (1 - math.cos(angle)) + padding.horizontal;
    final yCord = _centerPoint.dy * (1 - math.sin(angle)) + padding.vertical;
    return Offset(xCord, yCord); // Adjust position based on scale ratio and padding
  }

  /// Helper to calculate the position of the second card
  Offset _secondCardPosition({
    required EdgeInsets padding,
    required double angle,
  }) {
    final xCord = _centerPoint.dx * (1 + math.cos(angle)) - padding.horizontal;
    final yCord = _centerPoint.dy * (1 + math.sin(angle)) - padding.vertical;
    return Offset(xCord, yCord); // Adjust position based on scale ratio and padding
  }

  /// Starts the auto-play timer
  void startAutoPlay() {
    _stopTimer(); // Ensure no duplicate timers
    _timer = Timer.periodic(autoPlayInterval, (_) {
      _swipingDirection == SwipingDirection.rtl
          ? next()
          : previous(); // Automatically move to the next card
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
      // _currentIndex = (_currentIndex + 1) % 3; // Circular logic for 3 cards
      _animationController.animateTo(1);
    }
  }

  /// Animates to the previous card in the carousel
  void previous() {
    if (!_animationController.isAnimating) {
      // _currentIndex = (_currentIndex - 1 + 3) % 3; // Circular logic for 3 cards
      _animationController.animateTo(1);
    }
  }

  /// Stops the ongoing animation
  void stopAnimation() {
    _animationController.stop();
  }

  /// Prepares for user interaction by stopping animations and auto-play
  void onUserInteractionStart() {
    _stopTimer();
    stopAnimation();
    _cardSwapped = false;
    _hasPassedMid = false;
  }

  /// Updates animation progress based on user drag gestures
  void onUserInteractionUpdate(
      DragUpdateDetails details, double cardWidth, StackedTrioCarouselParams params) {
    _swipingMethod = SwipingMethod.userDriven; // Set swiping method to user-driven

    bool swipingRTL = details.delta.dx < 0;
    bool leftOfCenter =
        (_widgetOffset.dx + _widgetSize.width / 2) > details.globalPosition.dx;
    SwipingDirection newSwipingDirection =
        leftOfCenter ? SwipingDirection.rtl : SwipingDirection.ltr;

    if (newSwipingDirection != _swipingDirection) {
      _swipingDirection = newSwipingDirection;
      _isSwipingforward = !_isSwipingforward;
      updateAnimations(params);
    }

    // Determine swipe direction and update state
    if (_isSwipingforward != swipingRTL) {
      _hasPassedMid = false; // Reset mid-swipe state
    }
    // Update swiping direction

    if (!_cardSwapped) {
      double value = 1 - (details.globalPosition.dx / cardWidth);
      if (leftOfCenter) {
        value =
            1 - (details.globalPosition.dx / cardWidth); // Calculate new animation value
      } else {
        value = -(1 - (details.globalPosition.dx / cardWidth));
      }
      _animationController.value = value; // Clamp value between 0 and 1
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
    if (_animationController.value.abs() > 0.5 && _animationController.value != 1) {
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
    } else if (_animationController.value.abs() < 0.5) {
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
