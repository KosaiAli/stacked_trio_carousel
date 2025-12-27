import 'dart:math';

import 'package:example/gift_cards_example.dart';
import 'package:example/yu_gi_oh_cards_example.dart';
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
      debugShowCheckedModeBanner: false,
      title: 'Stacked Trio Carousel Example',
      theme: ThemeData(colorScheme: const ColorScheme.dark(primary: Colors.grey), useMaterial3: true),
      // Switch between examples //
      home: const MyHomePage(),
      // home: const GiftCardsExample(),
      // home: const YuGiOhCardsExample(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late StackedTrioCarouselController _carouselController;

  @override
  void initState() {
    _carouselController = StackedTrioCarouselController(tickerProvider: this, autoPlay: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final List colors = [Colors.transparent, Colors.transparent, Colors.blue, Colors.orange, Colors.purple];
    return Theme(
      data: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true),
      child: Scaffold(
        appBar: AppBar(centerTitle: true, elevation: 2, title: const Text("STC Example")),
        body: Column(
          children: [
            StackedTrioCarousel(
              height: 400,
              width: MediaQuery.of(context).size.width,
              background: Container(),
              params: StackedTrioCarouselParams(widgetHeight: 200, widgetWidth: 200),
              routeObserver: routeObserver,
              controller: _carouselController,
              initialIndex: 1,
              onTap: (index) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SecondScreen()));
              },
              children: colors
                  .map(
                    (color) => Container(
                      key: ValueKey(Random().nextInt(100000)),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(25)),
                    ),
                  )
                  .toList(),
            ),
            ElevatedButton(
              onPressed: () {
                _carouselController.autoPlay ? _carouselController.stopAutoPlay() : _carouselController.startAutoPlay();
                setState(() {});
              },
              child: Text(_carouselController.autoPlay ? "Stop Auto Play" : "Start Auto Play"),
            ),
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
    return Theme(
      data: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true),
      child: Scaffold(
        appBar: AppBar(centerTitle: true, elevation: 2, title: const Text('second screen')),
        body: const Center(child: Text('second screen')),
      ),
    );
  }
}
