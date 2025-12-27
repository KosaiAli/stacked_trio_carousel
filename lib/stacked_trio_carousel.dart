library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

part 'stacked_trio_carousel_controller.dart';

class StackedTrioCarousel extends StatefulWidget {
  StackedTrioCarousel({
    super.key,
    required this.background,
    required this.children,
    required this.params,
    this.routeObserver,
    this.controller,
    this.onTap,
    this.height,
    this.width,
    this.initialIndex = 0,
  }) : assert(children.length > 2, "the children list should contain 3 items at least."),
       assert(
         children.every((c) => c.key != null && c.key is ValueKey) &&
             children.map((c) => c.key).toSet().length == children.length,
         'Each child must have a non-null unique value key',
       );

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

  /// The height of the whole carousel widget
  ///
  /// make sure to specify this value for the widget to behave probably
  /// espically inside columns and vertical list view
  final double? height;

  /// The width of the whole carousel widget
  ///
  /// make sure to specify this value for the widget to behave probably
  /// espically inside row and horizontal list view
  final double? width;

  /// The initial index of the item to be displayed.
  ///
  /// The item that shows up in the beginning
  final int initialIndex;

  @override
  State<StackedTrioCarousel> createState() => _StackedTrioCarouselState();
}

class _StackedTrioCarouselState extends State<StackedTrioCarousel>
    with TickerProviderStateMixin, RouteAware {
  late StackedTrioCarouselController _controller;

  // Caching overlay entries to manage their visibility and order
  final List<OverlayEntry> _overlayEntries = [];

  // Caching children to manage their order
  late List<Widget> _children;

  // Caching children to manage their order
  late List<Widget> _childrenOriginalOrder;

  // Caching current order of elements to mitigate reinserting items on every frame
  List<int> currentOrder = [];

  // Establishes a coordinate bridge between the background (Target) and the Element (Follower)
  final LayerLink layerLink = LayerLink();

  // Store the changes in widget size
  Size _lastSize = Size.zero;

  // Store the gloabl offset of the widget
  Offset _offset = Offset.zero;

  late List<Widget> _slidingWindow;

  late int _currentIndex;

  @protected
  void _handleAnimationStart() {
    /* Might Come in Handy Later */
  }

  @override
  void initState() {
    _controller =
        widget.controller ?? StackedTrioCarouselController(tickerProvider: this);

    _controller.onAnimationStart = _handleAnimationStart;
    _controller.onAnimationEnd = _listenToAnimationEnd;
    _controller.onAnimationProgress = _listenToAnimationChanges;

    _children = List.from(widget.children);
    _childrenOriginalOrder = List.from(widget.children);

    // ensure the widget has been rendered
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      _offset = renderBox!.localToGlobal(Offset.zero);
    });
    _currentIndex = widget.initialIndex;
    _slidingWindow = [
      _children[(widget.initialIndex - 1) % _children.length],
      _children[(widget.initialIndex + 1) % _children.length],
      _children[widget.initialIndex % _children.length],
    ];

    super.initState();
  }

  void initializeAnimation(Size size) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        for (var entry in _overlayEntries) {
          if (entry.mounted) {
            entry.remove(); // Remove mounted overlay entries
          }
        }
        _controller.initializeAnimations(
          params: widget.params,
          widgetSize: size,
          widgetOffset: _offset,
          childrenLength: _children.length,
        );
      } catch (e, st) {
        debugPrint(
          '[StackedTrioCarousel:initState] Failed to initialize layout or animations.\n'
          'Reason: $e\n$st',
        );
      }
      _generateStackedCards();
      _lastSize = size;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: layerLink,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width =
              widget.width ??
              (constraints.maxWidth == double.infinity
                  ? widget.params.widgetWidth
                  : constraints.maxWidth);

          final height =
              widget.height ??
              (constraints.maxHeight == double.infinity
                  ? widget.params.widgetHeight
                  : constraints.maxHeight);

          final size = Size(width, height);

          if (_lastSize != size) {
            initializeAnimation(size);
          }

          return SizedBox(
            height: size.height,
            width: size.width,
            child: widget.background,
          );
        },
      ),
    );
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

  void _updateSlidingWindow() {
    _slidingWindow = [
      _children[(_currentIndex - 1) % _children.length],
      _children[(_currentIndex + 1) % _children.length],
      _children[_currentIndex % _children.length],
    ];
  }

  bool _sameChildren(List<Widget> a, List<Widget> b) {
    if (a.length != b.length) return false;

    for (int i = 0; i < a.length; i++) {
      if (a[i].key != b[i].key) return false;
    }
    return true;
  }

  @override
  void didUpdateWidget(covariant StackedTrioCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameChildren(oldWidget.children, widget.children)) {
      _children = List.from(widget.children);
    }
    bool shouldReinitialize =
        (oldWidget.height == widget.height && oldWidget.width == widget.width) &&
        (!_sameChildren(oldWidget.children, widget.children) ||
            (oldWidget.params != widget.params));

    if (shouldReinitialize) initializeAnimation(_lastSize);
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
    super.dispose();
  }

  @override
  void didPopNext() {
    if (_controller._autoPlay) {
      // _controller.swipingDirection == SwipingDirection.rtl
      //     ? _controller.next()
      //     : _controller.previous();
      _controller.startAutoPlay();
      return;
    }
  }

  @override
  void didPushNext() {
    // Handle the event when this widget is pushed off the screen
    Future.delayed(
      widget
          .params
          .disappearDuration, // Wait for the specified duration before disappearing
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
      _currentIndex--;
    } else {
      _currentIndex++;
    }
    _updateSlidingWindow();
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
          _slidingWindow[i],
        ),
      );
      try {
        Overlay.of(
          context,
        ).insert(_overlayEntries[i]); // Insert the overlay into the overlay stack
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
            height: widget.params.widgetHeight, // Set the height of the card
            width: widget.params.widgetWidth, // Set the width of the card
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
                      onPanDown: (details) =>
                          _onPanDown(details, child), // Handle touch down event
                      onPanUpdate: (details) =>
                          _onPanUpdate(details, child), // Handle touch movement
                      onPanCancel: () =>
                          _onPanCancel(child), // Handle cancellation of the gesture
                      onPanEnd: (details) =>
                          _onPanEnd(details), // Handle end of the gesture
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

  void pauseAutoPlayTemporarily() {
    bool activeTimerPresent = _controller._resumeAutoPlayTimer?.isActive ?? false;
    if (activeTimerPresent ||
        (_controller._autoPlay &&
            _controller._pauseAutoPlayDurationAfterPressingSideElements !=
                Duration.zero)) {
      // Cancel any previous scheduled resume
      _controller._resumeAutoPlayTimer?.cancel();
      _controller.stopAutoPlay();

      _controller._resumeAutoPlayTimer = Timer(
        _controller._pauseAutoPlayDurationAfterPressingSideElements,
        () {
          _controller.startAutoPlay();
          _controller._resumeAutoPlayTimer = null;
        },
      );
    }
  }

  /// Bring non-main element to center if pressed, and run defined onTap logic on main element
  Future<void> _onTap(Widget child) async {
    int index = _slidingWindow.indexOf(child);
    if (child != _slidingWindow.last) {
      if (index < 2) {
        index == 0 ? await _controller.previous() : await _controller.next();
        pauseAutoPlayTemporarily();
      }

      if (_controller._autoPlay) {
        _controller.startAutoPlay();
      }
      return;
    } else {
      await _controller._animationController.animateTo(0.5);
    }
    if ((_controller._animationController.value - 0.5).abs() < 0.15) {
      widget.onTap?.call(_childrenOriginalOrder.indexOf(child));
    }
  }

  /// Handles the end of a swipe gesture
  void _onPanEnd(DragEndDetails details) {
    _controller.onUserInteractionEnd();
  }

  /// Handles the cancellation of a swipe gesture
  void _onPanCancel(Widget child) {
    if (child != _slidingWindow.last) return;
    _controller.onUserInteractionCancel();
  }

  /// Handles the update of a swipe gesture
  void _onPanUpdate(DragUpdateDetails details, Widget child) {
    if (child != _slidingWindow.last) return;

    _controller.onUserInteractionUpdate(
      details,
      widget.params.widgetWidth,
      widget.params.widgetHeight,
      widget.params,
    );
  }

  /// Handles the start of a swipe gesture
  void _onPanDown(DragDownDetails dragDownDetails, Widget child) {
    if (child != _slidingWindow.last) return;
    _controller.onUserInteractionStart(
      dragDownDetails.globalPosition.dx,
      dragDownDetails.globalPosition.dy,
    );
  }

  /// Monitor Animation Changes
  void _listenToAnimationChanges(double progress) {
    if (_controller._animationController.isAnimating || _controller._isAnimating) {
      // Check if the animation is past halfway both ways and in between
      if (_controller._animationController.value <
          0.5 - _controller._swapConfirmationDistance) {
        if (!listEquals(currentOrder, [1, 2, 0]) && _children.length > 3) {
          _overlayEntries[1].remove();
          _overlayEntries[1] = _createOverlayEntry(
            _controller.positionAnimations[1],
            _controller.opacityAnimations[1],
            _controller.scaleAnimations[1],
            _children[(_currentIndex - 2) % _children.length],
          );
        }
        _reinsertOverlayEntries([1, 2, 0]);
        currentOrder = [1, 2, 0];
      }
      if (_controller._animationCurve.transform(_controller._animationController.value) >
          0.70) {
        if (!listEquals(currentOrder, [0, 2, 1]) && _children.length > 3) {
          _overlayEntries[0].remove();
          _overlayEntries[0] = _createOverlayEntry(
            _controller.positionAnimations[0],
            _controller.opacityAnimations[0],
            _controller.scaleAnimations[0],
            _children[(_currentIndex + 2) % _children.length],
          );
        }
        _reinsertOverlayEntries([0, 2, 1]);
        currentOrder = [0, 2, 1];
      }
      if (_controller._animationController.value >
          0.5 + _controller._swapConfirmationDistance) {}
      if (0.5 - _controller._swapConfirmationDistance <
              _controller._animationController.value &&
          _controller._animationController.value <
              0.5 + _controller._swapConfirmationDistance) {
        _reinsertOverlayEntries([0, 1, 2]);
        currentOrder = [0, 1, 2];
      }
    }
  }

  /// Update Overlay Entries by reinserting them
  void _reinsertOverlayEntries(List<int> order) {
    // Return if order didn't change
    if (listEquals(currentOrder, order)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    });
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
  final double widgetHeight;

  /// The width of the top card.
  ///
  /// This determines the width of the topmost visible card, which will be the maximum width.
  final double widgetWidth;

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

  /// The first background widget's padding.
  ///
  /// Use `EdgeInsets.only(...)`, `EdgeInsets.symmtric(...)` is obselete
  final EdgeInsets firstWidgetPadding;

  /// The second background widget's padding.
  ///
  /// Use `EdgeInsets.only(...)`, `EdgeInsets.symmtric(...)` is obselete
  final EdgeInsets secondWidgetPadding;

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
    required this.widgetHeight,
    required this.widgetWidth,
    this.firstWidgetPadding = EdgeInsets.zero,
    this.secondWidgetPadding = EdgeInsets.zero,
    this.scaleRatio = 0.7,
    this.minimumOpacity = 0.2,
    this.maximumOpacity = 1,
    // this.animateForward = true,
    this.angle = 0,
    this.appearDuration = const Duration(milliseconds: 275),
    this.disappearDuration = const Duration(milliseconds: 50),
  }) : assert(
         scaleRatio > 0 && scaleRatio < 1,
         "Scale ratio should be greater than 0 and smaller than 1",
       ),
       assert(
         minimumOpacity >= 0 && minimumOpacity <= 1,
         "Minimum opacity value should be between 0 and 1",
       ),
       assert(
         maximumOpacity >= 0 && maximumOpacity <= 1,
         "Maximum opacity value should be between 0 and 1",
       ),
       assert(
         maximumOpacity > minimumOpacity,
         "Maximum opacity value should be bigger than minimum opacity value",
       );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StackedTrioCarouselParams &&
        other.widgetHeight == widgetHeight &&
        other.widgetWidth == widgetWidth &&
        other.scaleRatio == scaleRatio &&
        other.minimumOpacity == minimumOpacity &&
        other.maximumOpacity == maximumOpacity &&
        other.firstWidgetPadding == firstWidgetPadding &&
        other.secondWidgetPadding == secondWidgetPadding &&
        other.disappearDuration == disappearDuration &&
        other.appearDuration == appearDuration &&
        other.angle == angle;
  }

  @override
  int get hashCode {
    return Object.hash(
      widgetHeight,
      widgetWidth,
      scaleRatio,
      minimumOpacity,
      maximumOpacity,
      firstWidgetPadding,
      secondWidgetPadding,
      disappearDuration,
      appearDuration,
      angle,
    );
  }
}
