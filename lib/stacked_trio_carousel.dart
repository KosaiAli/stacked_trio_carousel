library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

part 'stacked_trio_carousel_controller.dart';

class StackedTrioCarousel extends StatefulWidget {
  const StackedTrioCarousel({
    super.key,
    required this.background,
    required this.children,
    required this.params,
    this.routeObserver,
    this.controller,
    this.onTap,
  }) : assert(children.length == 3, "the children list should contain exactly 3 items.");

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

  /// Element onTap Override.
  ///
  /// Takes the index of the element that the user taps.
  final Function(int index)? onTap;

  @override
  State<StackedTrioCarousel> createState() => _StackedTrioCarouselState();
}

class _StackedTrioCarouselState extends State<StackedTrioCarousel> with TickerProviderStateMixin, RouteAware {
  late StackedTrioCarouselController _controller;

  // Caching overlay entries to manage their visibility and order
  final List<OverlayEntry> _overlayEntries = [];

  // Caching children to manage their order
  late List<Widget> _children;

  // Caching current order of elements to mitigate reinserting items on every frame
  List<int> currentOrder = [];

  // Establishes a coordinate bridge between the background (Target) and the Element (Follower)
  final LayerLink layerLink = LayerLink();  
  
  @protected
  void _handleAnimationStart() {
     /* Might Come in Handy Later */
  }

  @override
  void initState() {
    _controller = widget.controller ?? StackedTrioCarouselController(tickerProvider: this);

    _controller.onAnimationStart = _handleAnimationStart;
    _controller.onAnimationEnd = _listenToAnimationEnd;
    _controller.onAnimationProgress = _listenToAnimationChanges;

    _children = List.from(widget.children);

    // ensure the widget has been rendered
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      try {
        // Retrieving the size and offset of the entire widget for layout calculations
        RenderBox? renderBox = context.findRenderObject() as RenderBox?;
        final size = renderBox!.size;
        Offset widgetOffset = renderBox.localToGlobal(Offset.zero);

        _controller.initializeAnimations(params: widget.params, widgetSize: size, widgetOffset: widgetOffset);
      } catch (e, st) {
        debugPrint(
          '[StackedTrioCarousel:initState] Failed to initialize layout or animations.\n'
          'Reason: $e\n$st',
        );
      }

      _generateStackedCards();
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(link: layerLink, child: widget.background);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to the route observer if it is provided
    if (widget.routeObserver != null) {
      try {
        widget.routeObserver?.subscribe(this, ModalRoute.of(context)!);
      } catch (e, st) {
        debugPrint(
          '[StackedTrioCarousel:RouteObserver] Failed to subscribe.\n'
          'Route: ${ModalRoute.of(context)}\n'
          'Error: $e\n$st',
        );
      }
    }
  }

  @override
  void dispose() {
    // Unsubscribe from the route observer if it is provided to avoid memory leaks
    if (widget.routeObserver != null) {
      try {
        widget.routeObserver?.unsubscribe(this);
      } catch (e, st) {
        debugPrint(
          '[StackedTrioCarousel:RouteObserver] Failed to unsubscribe.\n'
          'Error: $e\n$st',
        );
      }
    }

    _removeOverlayEntries();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    if (_controller._autoPlay) {
      _controller.swipingDirection == SwipingDirection.rtl ? _controller.next() : _controller.previous();
      _controller.startAutoPlay();
      return;
    }
  }

  @override
  void didPushNext() {
    // Handle the event when this widget is pushed off the screen
    Future.delayed(
      widget.params.disappearDuration, // Wait for the specified duration before disappearing
      () {},
    );

    super.didPushNext(); // Call the superclass method to ensure proper functionality
  }

  /// Rearranging the cards.
  ///
  /// The animation is based on changing the animation assigned to each card.
  /// The card overlays will be removed and reordered by removing the last card
  /// and inserting it at index 0. This process regenerates the card with the
  /// proper animation after resetting the animation controller.
  void _listenToAnimationEnd(bool finishedAtZero) {
    _removeOverlayEntries();
    if (finishedAtZero) {
      _children.insert(2, _children.removeAt(0));
    } else {
      _children.insert(0, _children.removeLast());
    }
    _generateStackedCards();
  }

  /// Generates and inserts stacked card overlays into the widget.
  void _generateStackedCards() {
    _overlayEntries.clear(); // Clear existing overlay entries
    for (int i = 0; i < _controller.positionAnimations.length; i++) {
      // Create and add overlay entries for each card based on position, opacity, scale, and child widget
      _overlayEntries.add(
        _createOverlayEntry(
          _controller.positionAnimations[i],
          _controller.opacityAnimations[i],
          _controller.scaleAnimations[i],
          _children[i],
        ),
      );
      try {
        Overlay.of(context).insert(_overlayEntries[i]); // Insert the overlay into the overlay stack
      } catch (e, st) {
        debugPrint(
          '[StackedTrioCarousel:OverlayEntries] Failed to insert entry: ${_overlayEntries[i]}'
          'Error: $e\n$st',
        );
      }
    }
  }

  /// Creates an OverlayEntry for a stacked card with animations
  OverlayEntry _createOverlayEntry(
    Animation<Offset?> animation,
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
              offset: animation.value!,
              child: Opacity(
                opacity: opacity.value!,
                child: Transform.scale(
                  scale: scale.value, // Scale the card based on animation
                  child: Material(
                    color: Colors.transparent,
                    child: GestureDetector(
                      onTap: () => _onTap(child),
                      onPanDown: _onPanDown, // Handle touch down event
                      onPanUpdate: _onPanUpdate, // Handle touch movement
                      onPanCancel: _onPanCancel, // Handle cancellation of the gesture
                      onPanEnd: _onPanEnd, // Handle end of the gesture
                      child: child,
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
  void _onPanEnd(DragEndDetails details) {
    _controller.onUserInteractionEnd();
  }

  /// Handles the cancellation of a swipe gesture
  void _onPanCancel() {
    _controller.onUserInteractionCancel();
  }

  /// Handles the update of a swipe gesture
  void _onPanUpdate(DragUpdateDetails details) {
    _controller.onUserInteractionUpdate(details, widget.params.cardWidth, widget.params);
  }

  /// Handles the start of a swipe gesture
  void _onPanDown(DragDownDetails dragDownDetails) {
    _controller.onUserInteractionStart(dragDownDetails.globalPosition.dx, dragDownDetails.globalPosition.dy);
  }

  /// Monitor Animation Changes
  void _listenToAnimationChanges(double progress) {
    if (_controller._animationController.isAnimating || _controller._isAnimating) {
      // Check if the animation is past halfway both ways and in between
      if (_controller._animationController.value < 0.25) {
        _reinsertOverlayEntries([1, 2, 0]);
        currentOrder = [1, 2, 0];
      }
      if (_controller._animationController.value > 0.75) {
        _reinsertOverlayEntries([0, 2, 1]);
        currentOrder = [0, 2, 1];
      }
      if (0.25 < _controller._animationController.value && _controller._animationController.value < 0.75) {
        _reinsertOverlayEntries([0, 1, 2]);
        currentOrder = [0, 1, 2];
      }
    }
  }

  /// Bring non-main element to center if pressed, and run defined onTap logic on main element  
  void _onTap(Widget child) {
    int index = _children.indexOf(child);
    if (child != _children.last && !_controller._animationController.isAnimating) {
      if (index == 0) {
        _controller.previous();
      }
      if (index == 1) {
        _controller.next();
      }
      return;
    }
    widget.onTap?.call(index);
  }

  /// Update Overlay Entries by reinserting them
  void _reinsertOverlayEntries(List<int> order) {
    
    // Return if order didn't change
    if (listEquals(currentOrder, order)) {
      return;
    }
    _removeOverlayEntries();
    // Reinserts overlay entries in a new order for a smooth transition
    try {
      Overlay.of(context).insert(_overlayEntries[order[0]]);
    } catch (e, st) {
      debugPrint(
        '[StackedTrioCarousel:OverlayEntries] Failed to insert entry: ${_overlayEntries[order[0]]}'
        'Error: $e\n$st',
      );
    }
    try {
      Overlay.of(context).insert(_overlayEntries[order[1]]);
    } catch (e, st) {
      debugPrint(
        '[StackedTrioCarousel:OverlayEntries] Failed to insert entry: ${_overlayEntries[order[1]]}'
        'Error: $e\n$st',
      );
    }
    try {
      Overlay.of(context).insert(_overlayEntries[order[2]]);
    } catch (e, st) {
      debugPrint(
        '[StackedTrioCarousel:OverlayEntries] Failed to insert entry: ${_overlayEntries[order[2]]}'
        'Error: $e\n$st',
      );
    }
  }

  /// remove mounted overlay entries from view
  void _removeOverlayEntries() {
    for (var entry in _overlayEntries) {
      try {
        if (entry.mounted) {
          entry.remove(); // Remove mounted overlay entries
        } // Remove each overlay entry from the overlay
      } catch (e, st) {
        debugPrint(
          '[StackedTrioCarousel:OverlayEntries] Failed to remove entry: $entry'
          'Error: $e\n$st',
        );
      }
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

  /// The angle of rotation for items in the carosuel (in radians).
  ///
  /// the default is 0 rad
  final double angle;

  StackedTrioCarouselParams({
    required this.cardHeight,
    required this.cardWidth,
    this.padding = EdgeInsets.zero,
    this.scaleRatio = 0.7,
    this.minimumOpacity = 0.2,
    this.maximumOpacity = 1,
    // this.animateForward = true,
    this.angle = 0,
    this.appearDuration = const Duration(milliseconds: 275),
    this.disappearDuration = const Duration(milliseconds: 50),
  }) : assert(scaleRatio > 0 && scaleRatio < 1, "Scale ratio should be greater than 0 and smaller than 1"),
       assert(minimumOpacity >= 0 && minimumOpacity <= 1, "Minimum opacity value should be between 0 and 1"),
       assert(maximumOpacity >= 0 && maximumOpacity <= 1, "Maximum opacity value should be between 0 and 1"),
       assert(maximumOpacity > minimumOpacity, "Maximum opacity value should be bigger than minimum opacity value");
}
