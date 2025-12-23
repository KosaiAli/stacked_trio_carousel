import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:stacked_trio_carousel/stacked_trio_carousel.dart';

class YuGiOhCardsExample extends StatefulWidget {
  const YuGiOhCardsExample({super.key});

  @override
  State<YuGiOhCardsExample> createState() => _YuGiOhCardsExampleState();
}

class _YuGiOhCardsExampleState extends State<YuGiOhCardsExample>
    with TickerProviderStateMixin {
  final List _images = [
    "https://static.wikia.nocookie.net/yugioh/images/f/f5/TheWingedDragonofRa-KICO-EN-UR-1E.png/revision/latest?cb=20220328162837",
    "https://static.wikia.nocookie.net/yugioh/images/e/ef/ObelisktheTormentor-KICO-EN-UR-1E.png/revision/latest?cb=20220328162813",
    "https://static.wikia.nocookie.net/yugioh/images/f/f2/SlifertheSkyDragon-SBC1-EN-ScR-1E.png/revision/latest/scale-to-width-down/284?cb=20230919232542",
  ];

  final List _titles = [
    "The Winged Dragon of Ra",
    "Obelisk the Tormentor",
    "Slifer the Sky Dragon",
  ];

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
      autoPlayInterval: const Duration(seconds: 2),
      adaptAutoPlayDirectionToUserSwipeDirection: true,
      // Use a single-direction curve, symmetry is handled automatically.
      animationCurve: Curves.decelerate,
      swipeSensitivity: 0.5,
      swapConfirmationDistance: 0.2,
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
        title: const Text(
          "STC - Yu Gi Oh Cards Example",
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
            height: 500,
            width: MediaQuery.of(context).size.width,
            background: Container(),
            params: StackedTrioCarouselParams(
              widgetHeight: 330,
              widgetWidth: 225,
              angle: 0,
              firstWidgetPadding: const EdgeInsets.only(
                top: 150,
                right: 30,
                left: 0,
                bottom: 0,
              ),
              secondWidgetPadding: const EdgeInsets.only(
                top: 150,
                right: 0,
                left: 30,
                bottom: 0,
              ),
              scaleRatio: 0.7,
              minimumOpacity: 0.3,
            ),
            routeObserver: routeObserver,
            controller: _carouselController,
            onTap: (index) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => YuGiOhCardsExampleSecondScreen(
                    imageUrl: _images[index],
                    title: _titles[index],
                  ),
                ),
              );
            },
            children: _images
                .map((image) => Image.network(image, key: ValueKey(image)))
                .toList(),
          ),
          const SizedBox(height: 80),
          ElevatedButton(
            onPressed: () {
              _carouselController.autoPlay
                  ? _carouselController.stopAutoPlay()
                  : _carouselController.startAutoPlay();
              setState(() {});
            },
            child: Text(
              _carouselController.autoPlay
                  ? "Stop Auto Play"
                  : "Start Auto Play",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class YuGiOhCardsExampleSecondScreen extends StatelessWidget {
  final String imageUrl;
  final String title;
  const YuGiOhCardsExampleSecondScreen({
    super.key,
    required this.imageUrl,
    required this.title,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.grey.shade900,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Center(
        heightFactor: 1.5,
        child: InteractiveViewer(
          child: Image.network(imageUrl, height: 800, width: 400, scale: 0.5),
        ),
      ),
    );
  }
}
