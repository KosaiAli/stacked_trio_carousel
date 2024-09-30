library stacked_trio_carousel;

import 'dart:async';

import 'package:flutter/material.dart';

enum _SwipingMethod {
  animationDriven,
  userDriven,
}

class StackedTrioCarousel extends StatefulWidget {
  const StackedTrioCarousel(
      {super.key,
      required this.background,
      required this.cardHeight,
      required this.cardWidth,
      required this.children,
      this.scaleRatio = 0.7,
      this.minimumOpacity = 0.2,
      this.maximumOpacity = 1,
      this.animationDuration = const Duration(milliseconds: 500),
      this.durationBetweenAnimations = const Duration(seconds: 7),
      this.appearDuration = const Duration(milliseconds: 275),
      this.disappearDuration = const Duration(milliseconds: 50),
      this.padding = EdgeInsets.zero,
      this.isAnimated = true,
      this.routeObserver})
      : assert(scaleRatio > 0 && scaleRatio < 1,
            "Scale ratio should be greater than 0 and smaller than 1"),
        assert(minimumOpacity >= 0 && minimumOpacity <= 1,
            "Minimum opacity value should be between 0 and 1"),
        assert(maximumOpacity >= 0 && maximumOpacity <= 1,
            "Maximum opacity value should be between 0 and 1"),
        assert(maximumOpacity > minimumOpacity,
            "Maximum opacity value should be bigger than minimum opacity value"),
        assert(children.length == 3,
            "the children list should contain exactly 3 items."),
        assert(durationBetweenAnimations >= animationDuration,
            "the duration between animations should be equal to or greater than the animation duration");

  /// The background widget.
  ///
  /// A custom widget to be used as the background. The width and height of
  /// the background widget are important, as they determine the alignment
  /// of cards within the center of the widget.
  ///
  /// If `isAnimated` is set to true, the width of the background widget will
  /// also affect the animation behavior.
  final Widget background;

  /// The height of the top card.
  ///
  /// This determines the height of the topmost visible card, which will be the maximum height.
  final double cardHeight;

  /// The width of the top card.
  ///
  /// This determines the width of the topmost visible card, which will be the maximum width.
  final double cardWidth;

  /// The scale ratio.
  ///
  /// This determines how much the background cards will be resized when swiping
  /// or animating. The value should be greater than 0 and less than 1.
  final double scaleRatio;

  /// The minimum opacity for the background cards.
  ///
  /// This determines how much the background cards will fade when swiping
  /// or animating. The value should be between 0 and 1
  /// (inclusive) and must be smaller than the `maximumOpacity`.
  final double minimumOpacity;

  /// The maximum opacity for the top visible card.
  ///
  /// This determines how visible the top card is. The value should be between 0 and 1
  /// (inclusive) and must be greater than the `minimumOpacity`.
  final double maximumOpacity;

  /// List of children to be rendered as stacked cards.
  ///
  /// This list should contain exactly 3 items.
  final List<Widget> children;

  /// The animation duration.
  ///
  /// This specifies the duration it takes to animate the cards.
  final Duration animationDuration;

  /// The duration between each animation.
  ///
  /// This determines how often the animation is played.
  /// This value should be equal to or greater than the `animationDuration`.
  final Duration durationBetweenAnimations;

  /// The background cards padding.
  ///
  /// This padding is applied only horizontally. To achieve the same effect vertically,
  /// adjust the card height accordingly.
  ///
  /// ```dart
  /// const EdgeInsets.symmetric(horizontal: 8.0)
  /// ```
  final EdgeInsets padding;

  /// Is Animated.
  ///
  /// This determines whether the animation is active.
  /// If set to false, the cards won't animate, but they can still be swiped manually.
  final bool isAnimated;

  /// Route Observer.
  ///
  /// If the children have navigation functionality, this should be provided.
  /// Otherwise, the cards will remain visible after navigating to another screen.
  final RouteObserver? routeObserver;

  /// Disappear duration.
  ///
  /// This is the duration the cards will wait before they disappear when
  /// navigating. This will only take effect if a `routeObserver` is provided.
  final Duration disappearDuration;

  /// Appear duration.
  ///
  /// This is the duration the cards will wait before reappearing when
  /// navigating back.This will only take effect if a `routeObserver` is provided.
  final Duration appearDuration;

  @override
  State<StackedTrioCarousel> createState() => _StackedTrioCarouselState();
}

class _StackedTrioCarouselState extends State<StackedTrioCarousel>
    with TickerProviderStateMixin, RouteAware {
  // AnimationController for managing the animation sequence
  late AnimationController _animationController;

  // List of position animations for various cards
  late List<Animation<double?>> _positionAnimations;

  // List of opacity animations for controlling the visibility of cards
  late List<Animation<double?>> _opacityAnimations;

  // List of scale animations for adjusting the size of cards
  late List<Animation<double?>> _scaleAnimations;

  // Timer used to forward the animation after a certain period
  Timer? _timer;

  // Boolean variable to ensure that the order of overlay entities changes
  // only once during the animation period
  bool _hasPassedMid = false;

  // The vertical offset of the cards to center them on the background
  late double _verticalStartingPoint;

  // Caching overlay entries to manage their visibility and order
  final List<OverlayEntry> _overlayEntries = [];

  // Caching children to manage their order
  late List<Widget> _children;

  // Boolean variable to prevent timer reassignment when
  // the swiping method is user-driven
  bool _stopTimer = false;

  // Boolean variable to ensure one reassignment of the timer
  bool _isFutureRegistered = false;

  // the user start swiping manually
  bool _startSwiping = false;

  // the user swiping in animation direction
  bool _isSwipingforward = false;

  bool _cardSwapped = false;

  // detemines the method of the swiping
  late _SwipingMethod _swipingMethod;

  @override
  void initState() {
    _children = List.from(widget.children);

    // intial the swip method based on isAnimated value
    if (widget.isAnimated) {
      _swipingMethod = _SwipingMethod.animationDriven;
    } else {
      _swipingMethod = _SwipingMethod.userDriven;
    }

    _animationController =
        AnimationController(vsync: this, duration: widget.animationDuration)
          ..addStatusListener(_animationStatusListener)
          ..addListener(_animationListener);

    // ensure the widget has been rendered
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        // Retrieving the size and offset of the entire widget for layout calculations
        RenderBox? renderBox = context.findRenderObject() as RenderBox?;
        final size = renderBox!.size;
        final centerPoint = renderBox.size.height / 2;
        final offset = renderBox.localToGlobal(Offset.zero);

        // calculating the card Y offset based on the widget offset,the center of
        // the widget and the height of the card
        _verticalStartingPoint =
            offset.dy + centerPoint - widget.cardHeight / 2;

        _generatePositionAnimations(offset.dx, size.width);

        _generateOpacityAnimations();

        _generateScaleAnimations();

        _generateStackedCards();

        if (widget.isAnimated) {
          // assign the timer to start the animation
          Future.delayed(
            const Duration(seconds: 2),
            () {
              _animationController.forward();
              _timer =
                  Timer.periodic(widget.durationBetweenAnimations, (timer) {
                _animationController.forward();
              });
            },
          );
        }
      },
    );

    super.initState();
  }

  // Reinitialize the variables when the widget state changes
  @override
  void didUpdateWidget(covariant StackedTrioCarousel oldWidget) {
    // Check if the minimum or maximum opacity has changed
    if ((widget.minimumOpacity != oldWidget.minimumOpacity) ||
        (widget.maximumOpacity != oldWidget.maximumOpacity)) {
      _generateOpacityAnimations(); // Regenerate opacity animations if opacity values change
    }

    // Check if the scale ratio has changed
    if (widget.scaleRatio != oldWidget.scaleRatio) {
      _generateScaleAnimations(); // Regenerate scale animations if scale ratio changes
    }

    // Update the children list if it has changed
    if (widget.children != oldWidget.children) {
      _children = List.from(widget
          .children); // Create a new list of children from the updated widget
    }

    // Check if the animation duration has changed
    if ((widget.animationDuration != oldWidget.animationDuration)) {
      _animationController.stop(); // Stop the current animation
      // Reinitialize the animation controller with the new duration
      _animationController =
          AnimationController(vsync: this, duration: widget.animationDuration)
            ..addStatusListener(
                _animationStatusListener) // Re-add the status listener
            ..addListener(_animationListener); // Re-add the animation listener
    }

    // Check if the duration between animations has changed
    if (widget.durationBetweenAnimations !=
        oldWidget.durationBetweenAnimations) {
      if (widget.isAnimated) {
        _timer?.cancel(); // Cancel any existing timer
        // Create a new periodic timer for the new duration
        _timer = Timer.periodic(widget.durationBetweenAnimations, (timer) {
          _animationController
              .forward(); // Move the animation forward at each interval
        });
      }
    }

    // Check if the animation state has changed (animated or not)
    if (widget.isAnimated != oldWidget.isAnimated) {
      if (widget.isAnimated) {
        _timer?.cancel(); // Cancel any existing timer
        // Create a new periodic timer for the new duration
        _timer = Timer.periodic(widget.durationBetweenAnimations, (timer) {
          _animationController
              .forward(); // Move the animation forward at each interval
        });
        _animationController.forward(); // Start the animation immediately
      } else {
        _timer?.cancel(); // Cancel the timer if animation is disabled
        _timer = null; // Set timer to null
      }
    }

    // Add a post-frame callback to ensure the layout is completed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Find the render box for the current context
      RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      final size = renderBox!.size; // Get the size of the render box

      // Get the global offset of the render box
      final offset = renderBox.localToGlobal(Offset.zero);

      // Generate position animations based on the offset and size
      _generatePositionAnimations(offset.dx, size.width);

      // Calculate the vertical starting point for the cards
      final centerPoint = size.height / 2; // Center point of the height
      _verticalStartingPoint = offset.dy + centerPoint - widget.cardHeight / 2;

      bool overliesMounted =
          true; // Flag to check if overlay entries are still mounted
      for (var entry in _overlayEntries) {
        overliesMounted =
            entry.mounted; // Update the flag based on entry's mount status
        if (entry.mounted) {
          entry.remove(); // Remove mounted overlay entries
        }
      }
      // If any overlays were mounted, regenerate the stacked cards
      if (overliesMounted) _generateStackedCards();
    });

    super.didUpdateWidget(oldWidget); // Call the superclass method
  }

  @override
  void didChangeDependencies() {
    super
        .didChangeDependencies(); // Call the superclass method to ensure proper initialization
    // Subscribe to the route observer if it is provided
    if (widget.routeObserver != null) {
      widget.routeObserver?.subscribe(this, ModalRoute.of(context)!);
    }
  }

  @override
  void dispose() {
    // Unsubscribe from the route observer if it is provided to avoid memory leaks
    if (widget.routeObserver != null) {
      widget.routeObserver?.unsubscribe(this);
    }
    super.dispose(); // Call the superclass dispose method
  }

  @override
  void didPopNext() {
    // Handle the event when this widget is brought back into view
    Future.delayed(
      widget.appearDuration, // Wait for the specified duration before appearing
      () {
        for (var entry in _overlayEntries) {
          if (mounted) {
            // Check if the widget is still in the widget tree
            Overlay.of(context)
                .insert(entry); // Re-insert each overlay entry into the overlay
          }
        }
      },
    );
  }

  @override
  void didPushNext() {
    // Handle the event when this widget is pushed off the screen
    Future.delayed(
      widget
          .disappearDuration, // Wait for the specified duration before disappearing
      () {
        for (var entry in _overlayEntries) {
          entry.remove(); // Remove each overlay entry from the overlay
        }
      },
    );

    super
        .didPushNext(); // Call the superclass method to ensure proper functionality
  }

  /// Listens for changes in the animation and adjusts the overlay entries accordingly
  void _animationListener() {
    switch (_swipingMethod) {
      case _SwipingMethod.animationDriven:
        // Check if the animation controller value indicates that the animation is past halfway
        if (_animationController.value > 0.5) {
          // Change the order of the card overlay entries so the animation appears smooth
          // This block will only execute once when transitioning past the midpoint
          if (!_hasPassedMid) {
            // Remove all overlay entries to prepare for re-insertion
            for (var entry in _overlayEntries) {
              entry.remove();
            }
            _hasPassedMid = true; // Mark that we've passed the midpoint
            // Reinsert the overlay entries in a new order for a smooth transition
            Overlay.of(context).insert(_overlayEntries.first);
            Overlay.of(context).insert(_overlayEntries.last);
            Overlay.of(context).insert(_overlayEntries[1]);
          }
        }
        break;

      case _SwipingMethod.userDriven:
        // Handle user-driven swiping logic
        if (_isSwipingforward) {
          // Check if the user is swiping forward (to the left)
          if (_animationController.value > 0.5) {
            // Change order of overlay entries when swiping forward past the midpoint
            if (!_hasPassedMid) {
              for (var entry in _overlayEntries) {
                entry.remove(); // Remove all entries for reordering
              }
              _hasPassedMid = true; // Mark that we've passed the midpoint
              // Reinsert the overlay entries in a new order
              Overlay.of(context).insert(_overlayEntries.first);
              Overlay.of(context).insert(_overlayEntries.last);
              Overlay.of(context).insert(_overlayEntries[1]);
            }
          }
        } else {
          // If the user is swiping backward (to the right)
          if (_animationController.value < 0.5) {
            // Change order of overlay entries when swiping backward past the midpoint
            if (!_hasPassedMid) {
              for (var entry in _overlayEntries) {
                entry.remove(); // Remove all entries for reordering
              }
              _hasPassedMid = true; // Mark that we've passed the midpoint
              // Reinsert the overlay entries in a new order
              Overlay.of(context).insert(_overlayEntries.first);
              Overlay.of(context).insert(_overlayEntries[1]);
              Overlay.of(context).insert(_overlayEntries.last);
            }
          }
        }
        break;
    }
  }

  /// Listens for the status of the animation and triggers rearrangement of cards if needed
  void _animationStatusListener(status) {
    switch (_swipingMethod) {
      case _SwipingMethod.animationDriven:
        // If the animation is completed, rearrange the stacked cards
        if (status == AnimationStatus.completed) {
          _rearrangeStackedCards();
        }
        break;

      case _SwipingMethod.userDriven:
        // For user-driven swiping, rearrange cards only if the swipe is forward and animation is completed
        if (_isSwipingforward &&
            status == AnimationStatus.completed &&
            _animationController.value == 1 &&
            !_cardSwapped) {
          _cardSwapped = true; // Mark that the card has been swapped
          _rearrangeStackedCards(); // Rearrange the stacked cards
        }
        break;
    }
  }

  // Rearranging the cards
  // The animation is based on changing the animation assigned to each card.
  // The card overlays will be removed and reordered by removing the last card
  // and inserting it at index 0. This process regenerates the card with the
  // proper animation after resetting the animation controller.
  void _rearrangeStackedCards() {
    for (var entry in _overlayEntries) {
      entry.remove();
    }

    _children.insert(0, _children.removeLast());
    _generateStackedCards();

    _hasPassedMid = false;
    _animationController.reset();
  }

  /// Generates and inserts stacked card overlays into the widget.
  void _generateStackedCards() {
    _overlayEntries.clear(); // Clear existing overlay entries
    for (int i = 0; i < _positionAnimations.length; i++) {
      // Create and add overlay entries for each card based on position, opacity, scale, and child widget
      _overlayEntries.add(_createOverlayEntry(_positionAnimations[i],
          _opacityAnimations[i], _scaleAnimations[i], _children[i]));
      Overlay.of(context).insert(
          _overlayEntries[i]); // Insert the overlay into the overlay stack
    }
  }

  /// Generates opacity animations for the stacked cards based on the minimum and maximum opacity values.
  void _generateOpacityAnimations() {
    _opacityAnimations = [
      // Tween for maintaining minimum opacity
      Tween<double>(begin: widget.minimumOpacity, end: widget.minimumOpacity)
          .animate(_animationController),
      // Tween for transitioning from minimum to maximum opacity
      Tween<double>(begin: widget.minimumOpacity, end: widget.maximumOpacity)
          .animate(_animationController),
      // Tween for transitioning from maximum to minimum opacity
      Tween<double>(begin: widget.maximumOpacity, end: widget.minimumOpacity)
          .animate(_animationController),
    ];
  }

  /// Generates scale animations for the stacked cards based on the scale ratio.
  void _generateScaleAnimations() {
    _scaleAnimations = [
      // Tween for maintaining the scale ratio
      Tween<double>(begin: widget.scaleRatio, end: widget.scaleRatio)
          .animate(_animationController),
      // Tween for scaling from the scale ratio to the default size (1)
      Tween<double>(begin: widget.scaleRatio, end: 1)
          .animate(_animationController),
      // Tween for scaling back from the default size (1) to the scale ratio
      Tween<double>(begin: 1, end: widget.scaleRatio)
          .animate(_animationController),
    ];
  }

  /// Generates position animations for the stacked cards based on start point and parent width.
  void _generatePositionAnimations(double xStartPoint, double parentWidth) {
    _positionAnimations = [
      // Tween for moving the first card from its starting position to the second card's position
      Tween(
              begin: _firstCardPosition(xStartPoint),
              end: _secondCardPosition(parentWidth))
          .animate(_animationController),
      // Tween for moving the second card from its position to the third card's position
      Tween(
              begin: _secondCardPosition(parentWidth),
              end: _thirdCardPosition(parentWidth))
          .animate(_animationController),
      // Tween for moving the third card from its position back to the first card's position
      Tween(
              begin: _thirdCardPosition(parentWidth),
              end: _firstCardPosition(xStartPoint))
          .animate(_animationController)
    ];
  }

  /// Calculates the position of the first card based on the starting point and widget properties.
  double _firstCardPosition(double xPoint) {
    return xPoint -
        ((widget.cardWidth - widget.cardWidth * widget.scaleRatio) / 2) +
        widget.padding
            .horizontal; // Adjust position based on scale ratio and padding
  }

  /// Calculates the position of the second card based on the parent width and widget properties.
  double _secondCardPosition(double width) {
    return width -
        (widget.cardWidth * widget.scaleRatio +
            ((widget.cardWidth - widget.cardWidth * widget.scaleRatio) / 2)) -
        widget.padding
            .horizontal; // Adjust position based on scale ratio and padding
  }

  /// Calculates the position of the third card to center it in the parent width.
  double _thirdCardPosition(double width) {
    return (width / 2) -
        (widget.cardWidth / 2); // Center the card within the parent width
  }

  /// Creates an OverlayEntry for a stacked card with animations
  OverlayEntry _createOverlayEntry(
    Animation<double?> animation,
    Animation<double?> opacity,
    Animation<double?> scale,
    Widget child,
  ) {
    return OverlayEntry(
      builder: (ctx) => AnimatedBuilder(
        animation: animation,
        builder: (ctx, _) {
          return Positioned(
            height: widget.cardHeight, // Set the height of the card
            width: widget.cardWidth, // Set the width of the card
            top: _verticalStartingPoint, // Set the vertical position
            left: animation
                .value, // Set the horizontal position based on animation value
            child: Opacity(
              opacity: opacity.value!, // Set the opacity based on animation
              child: Transform.scale(
                scale: scale.value, // Scale the card based on animation
                child: Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onPanDown: _onPanDown, // Handle touch down event
                    onPanUpdate: _onPanUpdate, // Handle touch movement
                    onPanCancel:
                        _onPanCancel, // Handle cancellation of the gesture
                    onPanEnd: _onPanEnd, // Handle end of the gesture
                    child: IgnorePointer(
                        ignoring: child != _children.last &&
                            _animationController.value != 1,
                        child: child // Display the child widget
                        ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Handles the end of a swipe gesture
  void _onPanEnd(details) {
    _startSwiping = false; // Reset swiping state
    _cardSwapped = false; // Reset card swapped state

    // Check if the swipe was significant enough to trigger an animation
    if (_animationController.value > 0.5 && _animationController.value != 1) {
      _animationController.animateTo(1).then(
        (value) {
          _hasPassedMid = false; // Reset mid-swipe state
          // Determine if the swipe method was animation or user-driven
          _swipingMethod = widget.isAnimated
              ? _SwipingMethod.animationDriven
              : _SwipingMethod.userDriven;
        },
      );
    } else if (_animationController.value < 0.5) {
      _animationController.animateTo(0).then(
        (value) {
          _hasPassedMid = false; // Reset mid-swipe state
          _swipingMethod = widget.isAnimated
              ? _SwipingMethod.animationDriven
              : _SwipingMethod.userDriven;
        },
      );
    }

    _stopTimer = false; // Reset stop timer flag

    // If animations are enabled, set up a timer to trigger further animations
    if (widget.isAnimated) {
      if (!_isFutureRegistered) {
        _isFutureRegistered = true;
        Future.delayed(
          const Duration(seconds: 5), // Delay before starting the animation
          () {
            if (!_stopTimer) {
              _animationController.forward(); // Start animation
              // Set up periodic timer to continue animating
              _timer =
                  Timer.periodic(widget.durationBetweenAnimations, (timer) {
                _animationController.forward();
              });
            }
            _isFutureRegistered = false; // Reset future registration flag
          },
        );
      }
    }
  }

  /// Handles the cancellation of a swipe gesture
  void _onPanCancel() {
    _startSwiping = false; // Reset swiping state
    _cardSwapped = false; // Reset card swapped state

    // Determine the swiping method based on whether animations are enabled
    _swipingMethod = widget.isAnimated
        ? _SwipingMethod.animationDriven
        : _SwipingMethod.userDriven;

    // If animations are enabled, set up a periodic timer
    if (widget.isAnimated) {
      _timer ??= Timer.periodic(widget.durationBetweenAnimations, (timer) {
        _animationController.forward();
      });
    }
  }

  /// Handles the update of a swipe gesture
  void _onPanUpdate(DragUpdateDetails details) {
    _animationController.stop(); // Stop the current animation
    _swipingMethod =
        _SwipingMethod.userDriven; // Set swiping method to user-driven

    // Determine swipe direction and update state
    if (_isSwipingforward != details.delta.dx < 0) {
      _hasPassedMid = false; // Reset mid-swipe state
    }
    _isSwipingforward = details.delta.dx < 0; // Update swiping direction

    // If swiping to the left, mark it as starting
    if (details.delta.dx < 0) {
      _startSwiping = true;
    }

    // If the swiping has started, update the animation controller value
    if (_startSwiping) {
      if (!_cardSwapped) {
        double value = 1 -
            (details.localPosition.dx /
                widget.cardWidth); // Calculate new animation value
        _animationController.value =
            value.clamp(0, 1); // Clamp value between 0 and 1
      }
    }
  }

  /// Handles the start of a swipe gesture
  void _onPanDown(_) {
    // Cancel any existing timer when the user begins to swipe
    if (_timer != null) {
      _timer!.cancel();
      _timer = null; // Clear the timer
    }

    _animationController.stop(); // Stop the current animation
    _cardSwapped = false; // Reset card swapped state
    _hasPassedMid = false; // Reset mid-swipe state
    _stopTimer = true; // Set flag to stop the timer
  }

  @override
  Widget build(BuildContext context) {
    return widget.background;
  }
}
