import 'dart:math';
import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:stacked_trio_carousel/stacked_trio_carousel.dart';

class GiftCardsExample extends StatefulWidget {
  const GiftCardsExample({super.key});

  @override
  State<GiftCardsExample> createState() => _GiftCardsExampleState();
}

class _GiftCardsExampleState extends State<GiftCardsExample>
    with TickerProviderStateMixin {
  final List _images = [
    "https://cdn.coinsbee.com/dist/assets/img/brands/Amazon.webp",
    "https://cdn.coinsbee.com/dist/assets/img/brands/Netflix.webp",
    "https://cdn.coinsbee.com/dist/assets/img/brands/Steam.webp",
  ];

  final List _titles = [
    "Amazon Gift Card",
    "Netflix Gift Card",
    "Steam Gift Card",
  ];

  late AnimationController _scalecontroller;
  late Animation<double> _scaleAnimation;

  double widgetScale = 1;

  late StackedTrioCarouselController _carouselController;

  @override
  void initState() {
    _carouselController = StackedTrioCarouselController(
      tickerProvider: this,
      swipingDirection: .ltr,
      pauseAutoPlayDurationAfterPressingSideElements: const Duration(
        seconds: 3,
      ),
      animationDuration: const Duration(milliseconds: 1500),
      autoPlayInterval: const Duration(milliseconds: 2500),
      adaptAutoPlayDirectionToUserSwipeDirection: true,
      // Use a single-direction curve, symmetry is handled automatically.
      animationCurve: Curves.bounceOut,
      swipeSensitivity: 0.75,
      swapConfirmationDistance: 0.2,
    );

    _scalecontroller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation =
        Tween<double>(begin: 1.0, end: 1.25).animate(
          CurvedAnimation(parent: _scalecontroller, curve: Curves.easeInOut),
        )..addListener(() {
          setState(() {});
        });

    super.initState();
  }

  void _toggleScale() {
    if (_scalecontroller.status == AnimationStatus.completed) {
      _scalecontroller.reverse();
      _carouselController.startAutoPlay();
    } else {
      _scalecontroller.forward();
      _carouselController.stopAutoPlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          "STC - Gift Cards Example",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          StackedTrioCarousel(
            height: 500 - 100 * _scalecontroller.value,
            width: MediaQuery.of(context).size.width,
            background: Container(),
            params: StackedTrioCarouselParams(
              widgetHeight: 220 * _scaleAnimation.value,
              widgetWidth: 330 * _scaleAnimation.value,
              angle: pi / 2,
              firstWidgetPadding: EdgeInsets.only(
                top: 20 + 80 * _scalecontroller.value,
                right: 0,
                left: 0,
                bottom: 0,
              ),
              secondWidgetPadding: EdgeInsets.only(
                top: 0,
                right: 0,
                left: 0,
                bottom: 20 + 80 * _scalecontroller.value,
              ),
              scaleRatio: 0.68,
              minimumOpacity: 0.4,
            ),
            routeObserver: routeObserver,
            controller: _carouselController,
            onTap: (index) async {
              _toggleScale();
              await showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (BuildContext context) {
                  return SizedBox(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            'Buy ${(index + 1) * 10}\$ ${_titles[index]}?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Proceed',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
              _toggleScale();
            },
            children: _images
                .map(
                  (image) => ClipRRect(
                    key: ValueKey(image),
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      image,
                      height: 100,
                      width: 200,
                      fit: BoxFit
                          .cover, // Ensures the image fills the 500x500 area
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
