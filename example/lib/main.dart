import 'dart:math';

import 'package:flutter/material.dart';
import 'package:stacked_trio_carousel/stacked_trio_carousel.dart';

final RouteObserver routeObserver = RouteObserver();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [routeObserver],
      title: 'Stacked Trio Carousel Example',
      theme: ThemeData(colorScheme: const ColorScheme.dark(primary: Colors.grey), useMaterial3: true),
      home: const Example1(), // Switch between examples
    );
  }
}

// Example 1

class Example1 extends StatefulWidget {
  const Example1({super.key});

  @override
  State<Example1> createState() => _Example1State();
}

class _Example1State extends State<Example1> with TickerProviderStateMixin {
  final List _images = [
    "https://cdn.coinsbee.com/dist/assets/img/brands/Amazon.webp",
    "https://cdn.coinsbee.com/dist/assets/img/brands/Netflix.webp",
    "https://cdn.coinsbee.com/dist/assets/img/brands/Steam.webp",
  ];

  final List _titles = ["Amazon Gift Card", "Netflix Gift Card", "Steam Gift Card"];

  late AnimationController _scalecontroller;
  late Animation<double> _scaleAnimation;

  double widgetScale = 1;

  late StackedTrioCarouselController _carouselController;

  @override
  void initState() {
    _carouselController = StackedTrioCarouselController(
      tickerProvider: this,
      swipingDirection: .ltr,
      pauseAutoPlayDurationAfterPressingSideElements: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 1500),
      autoPlayInterval: const Duration(milliseconds: 2500),
      adaptAutoPlayDirectionToUserSwipeDirection: true,
      // Use a single-direction curve, symmetry is handled automatically.
      animationCurve: Curves.bounceOut,
      swipeSensitivity: 0.75,
      swipeConfirmationDistance: 0.2,
    );

    _scalecontroller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    _scaleAnimation =
        Tween<double>(begin: 1.0, end: 1.25).animate(CurvedAnimation(parent: _scalecontroller, curve: Curves.easeInOut))
          ..addListener(() {
            setState(() {});
          });
    ;

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
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
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
              firstWidgetPadding: EdgeInsets.only(top: 20 + 80 * _scalecontroller.value, right: 0, left: 0, bottom: 0),
              secondWidgetPadding: EdgeInsets.only(top: 0, right: 0, left: 0, bottom: 20 + 80 * _scalecontroller.value),
              scaleRatio: 0.68,
              minimumOpacity: 0.4,
            ),
            routeObserver: routeObserver,
            controller: _carouselController,
            onTap: (index) async {
              _toggleScale();
              await showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (BuildContext context) {
                  return SizedBox(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            'Buy ${(index + 1) * 10}\$ ${_titles[index]}?',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Proceed', style: TextStyle(color: Colors.white, fontSize: 18)),
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
                      fit: BoxFit.cover, // Ensures the image fills the 500x500 area
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

// Example 2

class Example2 extends StatefulWidget {
  const Example2({super.key});

  @override
  State<Example2> createState() => _Example2State();
}

class _Example2State extends State<Example2> with TickerProviderStateMixin {
  final List _images = [
    "https://static.wikia.nocookie.net/yugioh/images/f/f5/TheWingedDragonofRa-KICO-EN-UR-1E.png/revision/latest?cb=20220328162837",
    "https://static.wikia.nocookie.net/yugioh/images/e/ef/ObelisktheTormentor-KICO-EN-UR-1E.png/revision/latest?cb=20220328162813",
    "https://static.wikia.nocookie.net/yugioh/images/f/f2/SlifertheSkyDragon-SBC1-EN-ScR-1E.png/revision/latest/scale-to-width-down/284?cb=20230919232542",
  ];

  final List _titles = ["The Winged Dragon of Ra", "Obelisk the Tormentor", "Slifer the Sky Dragon"];

  late StackedTrioCarouselController _carouselController;

  @override
  void initState() {
    _carouselController = StackedTrioCarouselController(
      tickerProvider: this,
      swipingDirection: .ltr,
      pauseAutoPlayDurationAfterPressingSideElements: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 1500),
      autoPlayInterval: const Duration(seconds: 2),
      adaptAutoPlayDirectionToUserSwipeDirection: true,
      // Use a single-direction curve, symmetry is handled automatically.
      animationCurve: Curves.decelerate,
      swipeSensitivity: 0.5,
      swipeConfirmationDistance: 0.2,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.grey.shade900,
        title: Text(
          "STC - Cards Example",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          StackedTrioCarousel(
            height: 500,
            width: MediaQuery.of(context).size.width,
            background: Container(),
            params: StackedTrioCarouselParams(
              widgetHeight: 330,
              widgetWidth: 225,
              angle: 0,
              firstWidgetPadding: const EdgeInsets.only(top: 150, right: 30, left: 0, bottom: 0),
              secondWidgetPadding: const EdgeInsets.only(top: 150, right: 0, left: 30, bottom: 0),
              scaleRatio: 0.7,
              minimumOpacity: 0.3,
            ),
            routeObserver: routeObserver,
            controller: _carouselController,
            onTap: (index) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Example2SecondScreen(imageUrl: _images[index], title: _titles[index]),
                ),
              );
            },
            children: _images.map((image) => Image.network(image, key: ValueKey(image))).toList(),
          ),
          const SizedBox(height: 80),
          ElevatedButton(
            onPressed: () {
              _carouselController.autoPlay ? _carouselController.stopAutoPlay() : _carouselController.startAutoPlay();
              setState(() {});
            },
            child: Text(
              _carouselController.autoPlay ? "Stop Auto Play" : "Start Auto Play",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class Example2SecondScreen extends StatelessWidget {
  final String imageUrl;
  final String title;
  const Example2SecondScreen({super.key, required this.imageUrl, required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.grey.shade900,
        title: Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Center(
        heightFactor: 1.5,
        child: InteractiveViewer(child: Image.network(imageUrl, height: 800, width: 400, scale: 0.5)),
      ),
    );
  }
}
