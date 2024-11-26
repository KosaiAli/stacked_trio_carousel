library stacked_trio_carousel;

import 'dart:async';

import 'package:flutter/material.dart';

import 'stacked_trio_carousel_controller.dart';

class StackedTrioCarousel extends StatefulWidget {
  const StackedTrioCarousel({
    super.key,
    required this.background,
    required this.children,
    required this.params,
    this.routeObserver,
    this.controller,
  }) : assert(children.length == 3,
            "the children list should contain exactly 3 items.");

  /// The background widget.
  ///
  /// A custom widget to be used as the background. The width and height of
  /// the background widget are important, as they determine the alignment
  /// of cards within the center of the widget.
  final Widget background;

  /// List of children to be rendered as stacked cards.
  ///
  /// This list should contain exactly 3 items.
  final List<Widget> children;

  /// Route Observer.
  ///
  /// If the children have navigation functionality, this should be provided.
  /// Otherwise, the cards will remain visible after navigating to another screen.
  final RouteObserver? routeObserver;

  /// A parameter object containing the configurations for the carousel.
  ///
  /// Includes values such as card dimensions, scaling ratios, and padding,
  /// encapsulated within the [StackedTrioCarouselParams] class for better organization
  /// and reusability.
  final StackedTrioCarouselParams params;

  /// An optional controller for the carousel to handle animations and user interactions.
  ///
  /// If a controller is provided, it allows external control of the carousel's
  /// animation and state. If not provided, an internal controller is created
  /// and managed by the widget.
  final StackedTrioCarouselController? controller;

  @override
  State<StackedTrioCarousel> createState() => _StackedTrioCarouselState();
}

class _StackedTrioCarouselState extends State<StackedTrioCarousel>
    with TickerProviderStateMixin, RouteAware {
  // The vertical offset of the cards to center them on the background
  late double _verticalStartingPoint;

  // Caching overlay entries to manage their visibility and order
  final List<OverlayEntry> _overlayEntries = [];

  // Caching children to manage their order
  late List<Widget> _children;

  late StackedTrioCarouselController _controller;

  @override
  void initState() {
    _controller = widget.controller ??
        StackedTrioCarouselController(tickerProvider: this);

    _controller.onAnimationStart = _handleAnimationStart;
    _controller.onAnimationEnd = _handleAnimationEnd;
    _controller.onAnimationProgress = _listenToAnimationChanges;

    _children = List.from(widget.children);

    // ensure the widget has been rendered
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        try {
          // Retrieving the size and offset of the entire widget for layout calculations
          RenderBox? renderBox = context.findRenderObject() as RenderBox?;
          final size = renderBox!.size;
          final centerPoint = renderBox.size.height / 2;
          final offset = renderBox.localToGlobal(Offset.zero);

          // calculating the card Y offset based on the widget offset,the center of
          // the widget and the height of the card
          _verticalStartingPoint = centerPoint - widget.params.cardHeight / 2;
          _controller.initializeAnimations(
            widget.params,
            offset.dx,
            size.width,
          );
        } catch (_) {}

        _generateStackedCards();
      },
    );

    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to the route observer if it is provided
    if (widget.routeObserver != null) {
      try {
        widget.routeObserver?.subscribe(this, ModalRoute.of(context)!);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    // Unsubscribe from the route observer if it is provided to avoid memory leaks
    if (widget.routeObserver != null) {
      widget.routeObserver?.unsubscribe(this);
    }

    for (var entry in _overlayEntries) {
      try {
        if (entry.mounted) {
          entry.remove(); // Remove mounted overlay entries
        } // Remove each overlay entry from the overlay
      } catch (_) {}
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Handle the event when this widget is brought back into view
    Future.delayed(
      widget.params
          .appearDuration, // Wait for the specified duration before appearing
      () {
        for (var entry in _overlayEntries) {
          if (mounted) {
            // Check if the widget is still in the widget tree
            try {
              Overlay.of(context).insert(
                  entry); // Re-insert each overlay entry into the overlay
            } catch (_) {}
          }
        }
      },
    );
  }

  @override
  void didPushNext() {
    // Handle the event when this widget is pushed off the screen
    Future.delayed(
      widget.params
          .disappearDuration, // Wait for the specified duration before disappearing
      () {
        for (var entry in _overlayEntries) {
          if (entry.mounted) {
            try {
              entry.remove(); // Remove mounted overlay entries
            } catch (_) {}
          } // Remove each overlay entry from the overlay
        }
      },
    );

    super
        .didPushNext(); // Call the superclass method to ensure proper functionality
  }

  // Rearranging the cards
  // The animation is based on changing the animation assigned to each card.
  // The card overlays will be removed and reordered by removing the last card
  // and inserting it at index 0. This process regenerates the card with the
  // proper animation after resetting the animation controller.
  void _rearrangeStackedCards() {
    for (var entry in _overlayEntries) {
      if (entry.mounted) {
        entry.remove(); // Remove mounted overlay entries
      }
    }

    _children.insert(0, _children.removeLast());
    _generateStackedCards();
  }

  /// Generates and inserts stacked card overlays into the widget.
  void _generateStackedCards() {
    _overlayEntries.clear(); // Clear existing overlay entries
    for (int i = 0; i < _controller.positionAnimations.length; i++) {
      // Create and add overlay entries for each card based on position, opacity, scale, and child widget
      _overlayEntries.add(_createOverlayEntry(
        _controller.positionAnimations[i],
        _controller.opacityAnimations[i],
        _controller.scaleAnimations[i],
        _children[i],
      ));
      try {
        Overlay.of(context).insert(
            _overlayEntries[i]); // Insert the overlay into the overlay stack
      } catch (_) {}
    }
  }

  final LayerLink layerLink = LayerLink();

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
            height: widget.params.cardHeight, // Set the height of the card
            width: widget.params.cardWidth, // Set the width of the card
            child: CompositedTransformFollower(
              link: layerLink,
              showWhenUnlinked: false,
              offset: Offset(animation.value!, _verticalStartingPoint),
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
                              !_controller.isAnimationCompleted,
                          child: child // Display the child widget
                          ),
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
    _controller.onUserInteractionEnd();
  }

  /// Handles the cancellation of a swipe gesture
  void _onPanCancel() {
    _controller.onUserInteractionCancel();
  }

  /// Handles the update of a swipe gesture
  void _onPanUpdate(DragUpdateDetails details) {
    _controller.onUserInteractionUpdate(details, widget.params.cardWidth);
  }

  /// Handles the start of a swipe gesture
  void _onPanDown(_) {
    _controller.onUserInteractionStart();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(link: layerLink, child: widget.background);
  }

  void _handleAnimationEnd() {
    switch (_controller.swipingMethod) {
      case SwipingMethod.animationDriven:
        _rearrangeStackedCards();
        break;

      case SwipingMethod.userDriven:
        // For user-driven swiping, rearrange cards only if the swipe is forward and animation is completed
        _rearrangeStackedCards(); // Rearrange the stacked cards

        break;
    }
  }

  void _handleAnimationStart() {}

  void _listenToAnimationChanges(double progress) {
    switch (_controller.swipingMethod) {
      case SwipingMethod.animationDriven:
        // Check if the animation controller value indicates that the animation is past halfway
        if (progress > 0.5) {
          // Change the order of the card overlay entries so the animation appears smooth
          // This block will only execute once when transitioning past the midpoint
          if (!_controller.hasPassedMid) {
            // Remove all overlay entries to prepare for re-insertion
            for (var entry in _overlayEntries) {
              if (entry.mounted) {
                entry.remove(); // Remove mounted overlay entries
              }
            }
            // Reinsert the overlay entries in a new order for a smooth transition
            try {
              Overlay.of(context).insert(_overlayEntries.first);
            } catch (_) {}
            try {
              Overlay.of(context).insert(_overlayEntries.last);
            } catch (_) {}
            try {
              Overlay.of(context).insert(_overlayEntries[1]);
            } catch (_) {}
          }
        }
        break;

      case SwipingMethod.userDriven:
        // Handle user-driven swiping logic
        if (_controller.isSwipingforward) {
          // Check if the user is swiping forward (to the left)
          if (progress > 0.5) {
            // Change order of overlay entries when swiping forward past the midpoint
            if (!_controller.hasPassedMid) {
              for (var entry in _overlayEntries) {
                if (entry.mounted) {
                  entry.remove(); // Remove mounted overlay entries
                } // Remove all entries for reordering
              }

              // Reinsert the overlay entries in a new order
              try {
                Overlay.of(context).insert(_overlayEntries.first);
              } catch (_) {}
              try {
                Overlay.of(context).insert(_overlayEntries.last);
              } catch (_) {}
              try {
                Overlay.of(context).insert(_overlayEntries[1]);
              } catch (_) {}
            }
          }
        } else {
          // If the user is swiping backward (to the right)
          if (progress < 0.5) {
            // Change order of overlay entries when swiping backward past the midpoint
            if (!_controller.hasPassedMid) {
              for (var entry in _overlayEntries) {
                if (entry.mounted) {
                  entry.remove(); // Remove mounted overlay entries
                } // Remove all entries for reordering
              }

              // Reinsert the overlay entries in a new order
              try {
                Overlay.of(context).insert(_overlayEntries.first);
              } catch (_) {}
              try {
                Overlay.of(context).insert(_overlayEntries[1]);
              } catch (_) {}
              try {
                Overlay.of(context).insert(_overlayEntries.last);
              } catch (_) {}
            }
          }
        }
        break;
    }
  }
}

class StackedTrioCarouselParams {
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

  /// The background cards padding.
  ///
  /// This padding is applied only horizontally. To achieve the same effect vertically,
  /// adjust the card height accordingly.
  ///
  /// ```dart
  /// const EdgeInsets.symmetric(horizontal: 8.0)
  /// ```
  final EdgeInsets padding;

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

  StackedTrioCarouselParams({
    required this.cardHeight,
    required this.cardWidth,
    this.padding = EdgeInsets.zero,
    this.scaleRatio = 0.7,
    this.minimumOpacity = 0.2,
    this.maximumOpacity = 1,
    this.appearDuration = const Duration(milliseconds: 275),
    this.disappearDuration = const Duration(milliseconds: 50),
  })  : assert(scaleRatio > 0 && scaleRatio < 1,
            "Scale ratio should be greater than 0 and smaller than 1"),
        assert(minimumOpacity >= 0 && minimumOpacity <= 1,
            "Minimum opacity value should be between 0 and 1"),
        assert(maximumOpacity >= 0 && maximumOpacity <= 1,
            "Maximum opacity value should be between 0 and 1"),
        assert(maximumOpacity > minimumOpacity,
            "Maximum opacity value should be bigger than minimum opacity value");
}
