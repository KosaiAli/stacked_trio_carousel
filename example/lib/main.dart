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
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(primary: Colors.grey),
        useMaterial3: true,
      ),
      home: const MyHomePage(), // Switch between examples
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
    _carouselController = StackedTrioCarouselController(tickerProvider: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final List colors = [Colors.red, Colors.green, Colors.blue];
    return Theme(
      data: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          elevation: 2,
          title: const Text("STC Example"),
        ),
        body: Column(
          children: [
            StackedTrioCarousel(
              height: 400,
              width: MediaQuery.of(context).size.width,
              background: Container(),
              params: StackedTrioCarouselParams(
                widgetHeight: 200,
                widgetWidth: 200,
              ),
              routeObserver: routeObserver,
              controller: _carouselController,
              onTap: (index) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SecondScreen()),
                );
              },
              children: colors
                  .map(
                    (color) => Container(
                      key: ValueKey(color),
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
              ),
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
      data: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          elevation: 2,
          title: const Text('second screen'),
        ),
        body: const Center(child: Text('second screen')),
      ),
    );
  }
}
