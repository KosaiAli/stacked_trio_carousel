import 'package:flutter/material.dart';
import 'package:stacked_trio_carousel/stacked_trio_carousel.dart';
import 'package:stacked_trio_carousel/stacked_trio_carousel_controller.dart';

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
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Stacked Trio Carousel'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  final List _color = [Colors.red, Colors.green, Colors.blue];

  late StackedTrioCarouselController _carouselController;

  @override
  void initState() {
    _carouselController = StackedTrioCarouselController(
        tickerProvider: this,
        animationDuration: const Duration(milliseconds: 200),
        autoPlayInterval: const Duration(seconds: 1),
        autoPlay: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StackedTrioCarousel(
              background: Container(),
              params: StackedTrioCarouselParams(
                cardHeight: 200,
                cardWidth: 200,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              routeObserver: routeObserver,
              controller: _carouselController,
              children: _color
                  .map(
                    (color) => GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SecondScreen(),
                            ));
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 200),
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
                style: const TextStyle(color: Colors.black),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('second screen'),
      ),
      body: const Center(
        child: Text('second screen'),
      ),
    );
  }
}
