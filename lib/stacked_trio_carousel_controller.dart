part of 'stacked_trio_carousel.dart';

// Enum representing the method of swiping the cards
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
  ltr,
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

  /// Duration for the animation between cards
  final Duration animationDuration;

  /// Interval duration for auto-play transitions
  final Duration autoPlayInterval;

  /// Callback for when an animation starts
  VoidCallback? onAnimationStart;

  /// Callback for when an animation ends
  void Function(bool finishedAtZero)? onAnimationEnd;

  /// Callback for reporting animation progress
  void Function(double progress)? onAnimationProgress;

  /// The current swiping method (animation or user-driven)
  late SwipingMethod _swipingMethod;

  /// Getter for the swiping method
  SwipingMethod get swipingMethod => _swipingMethod;

  /// Direction of Swiping
  late SwipingDirection _swipingDirection;

  SwipingDirection get swipingDirection => _swipingDirection;

  /// Flag indicating the swiping direction (forward or backward)
  bool _isAnimating = false;

  /// Getter for whether the swiping is forward
  bool get isSwipingforward => _isAnimating;

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
    _animationController =
        AnimationController(
            lowerBound: 0,
            value: 0.5,
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
  }

  /// Listener for animation status changes
  void animationStatusListener(AnimationStatus status) {
    if (status == .forward) {
      onAnimationStart?.call();
    } else if (status == .completed) {
      if (_animationController.value == 0 || _animationController.value == 1) {
        onAnimationEnd?.call(_animationController.value == 0);
        _isAnimating = false; // Mark that the card has been swapped
        _animationController.value = 0.5;
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
    _centerPoint = Offset(xCenterPoint, yCenterPoint);

    final firstPos = _firstCardPosition(
      padding: params.padding,
      angle: params.angle,
      offset: 10,
    );

    final secondPos = _secondCardPosition(
      padding: params.padding,
      angle: params.angle,
      offset: 10,
    );

    final thirdPos = _centerPoint;

    positionAnimations = [
      TweenSequence<Offset>([
        TweenSequenceItem(
          tween: Tween(begin: thirdPos, end: firstPos),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween(begin: firstPos, end: secondPos),
          weight: 50,
        ),
      ]).animate(_animationController),
      TweenSequence<Offset>([
        TweenSequenceItem(
          tween: Tween(begin: firstPos, end: secondPos),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween(begin: secondPos, end: thirdPos),
          weight: 50,
        ),
      ]).animate(_animationController),
      TweenSequence<Offset>([
        TweenSequenceItem(
          tween: Tween(begin: secondPos, end: thirdPos),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween(begin: thirdPos, end: firstPos),
          weight: 50,
        ),
      ]).animate(_animationController),
    ];

    scaleAnimations = [
      TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: params.scaleRatio), weight: 50),
        TweenSequenceItem(
          tween: Tween(begin: params.scaleRatio, end: params.scaleRatio),
          weight: 50,
        ),
      ]).animate(_animationController),
      TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: params.scaleRatio, end: params.scaleRatio),
          weight: 50,
        ),
        TweenSequenceItem(tween: Tween(begin: params.scaleRatio, end: 1.0), weight: 50),
      ]).animate(_animationController),
      TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: params.scaleRatio, end: 1.0), weight: 50),
        TweenSequenceItem(tween: Tween(begin: 1.0, end: params.scaleRatio), weight: 50),
      ]).animate(_animationController),
    ];

    opacityAnimations = [
      TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: params.maximumOpacity, end: params.minimumOpacity),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween(begin: params.minimumOpacity, end: params.minimumOpacity),
          weight: 50,
        ),
      ]).animate(_animationController),
      TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: params.minimumOpacity, end: params.minimumOpacity),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween(begin: params.minimumOpacity, end: params.maximumOpacity),
          weight: 50,
        ),
      ]).animate(_animationController),
      TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: params.minimumOpacity, end: params.maximumOpacity),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween(begin: params.maximumOpacity, end: params.minimumOpacity),
          weight: 50,
        ),
      ]).animate(_animationController),
    ];
  }

  /// Helper to calculate the position of the first card
  Offset _firstCardPosition({
    required EdgeInsets padding,
    required double angle,
    required double offset,
  }) {
    final xCord =
        _centerPoint.dx * (1 - math.cos(angle)) - padding.horizontal * math.cos(angle);
    final yCord =
        _centerPoint.dy * (1 - math.sin(angle)) - padding.vertical * math.sin(angle);
    return Offset(xCord, yCord); // Adjust position based on scale ratio and padding
  }

  /// Helper to calculate the position of the second card
  Offset _secondCardPosition({
    required EdgeInsets padding,
    required double angle,
    required double offset,
  }) {
    final xCord =
        _centerPoint.dx * (1 + math.cos(angle)) + padding.horizontal * math.cos(angle);
    final yCord =
        _centerPoint.dy * (1 + math.sin(angle)) + padding.vertical * math.sin(angle);
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
      _animationController.animateTo(0);
    }
  }

  /// Stops the ongoing animation
  void stopAnimation() {
    _animationController.stop();
  }

  /// Prepares for user interaction by stopping animations and auto-play
  void onUserInteractionStart(double swipeStartingPointdx, double swipeStartingPointdy) {
    _stopTimer();
    stopAnimation();

    _swipeStartingPointdx = swipeStartingPointdx;
    _swipeStartingPointdy = swipeStartingPointdy;
  }

  double? _swipeStartingPointdx;
  double? _swipeStartingPointdy;

  /// Updates animation progress based on user drag gestures
  void onUserInteractionUpdate(
    DragUpdateDetails details,
    double cardWidth,
    StackedTrioCarouselParams params,
  ) {
    _swipingMethod = SwipingMethod.userDriven;

    final dx = details.globalPosition.dx - _swipeStartingPointdx!;
    final dy = details.globalPosition.dy - _swipeStartingPointdy!;

    final projectedDelta = dx * math.cos(params.angle) + dy * math.sin(params.angle);

    final value = (0.5 - projectedDelta / cardWidth).clamp(0.0, 1.0);

    _isAnimating = value != 0.0 && value != 1.0;

    if (_isAnimating) {
      _animationController.value = value;
    }
  }

  /// Handles cancellation of user interaction
  void onUserInteractionCancel() {
    _swipeStartingPointdx = null;
    _isAnimating = false;
    if (_autoPlay) {
      _swipingMethod = SwipingMethod.animationDriven;
    } else {
      _swipingMethod = SwipingMethod.userDriven;
    }
  }

  /// Handles the end of user interaction
  void onUserInteractionEnd() {
    _swipingMethod = SwipingMethod.animationDriven;
    _swipeStartingPointdx = null;
    _isAnimating = false;
    // Check if the swipe was significant enough to trigger an animation
    if (_animationController.value > 0.75) {
      _animationController.animateTo(1).then((value) {
        _isAnimating = false;
        if (_autoPlay) {
          _swipingMethod = SwipingMethod.animationDriven;
        } else {
          _swipingMethod = SwipingMethod.userDriven;
        }
      });
    } else if (_animationController.value < 0.25) {
      _animationController.animateTo(0);
    } else {
      _animationController.animateTo(0.5);
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
