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
      swipingDirection: .rtl,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          StackedTrioCarousel(
            height: 400,
            width: MediaQuery.of(context).size.width,
            background: Container(),
            params: StackedTrioCarouselParams(
              cardHeight: 200,
              cardWidth: 200,
              angle: pi / 2,
            ),
            routeObserver: routeObserver,
            controller: _carouselController,
            onTap: (index) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SecondScreen()),
              );
            },
            children: _color
                .map(
                  (color) => Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                )
                .toList(),
          ),
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
          ),
        ],
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
      body: const Center(child: Text('second screen')),
    );
  }
}
