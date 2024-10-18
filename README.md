# Stacked Trio Carousel

**Stacked Trio Carousel** is a Flutter package that provides a visually engaging card carousel with a stacked layout of three cards.

## Features

The carousel features one prominent card in the foreground and two cards in the background, making it perfect for showcasing content in a layered and dynamic way. With built-in animations and customizable properties, users can swipe through the cards or enable automatic transitions for a smooth and interactive experience.

<img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/default.gif"/>

## Getting Started

To use this package, add `stacked_trio_carousel` as a dependency in your `pubspec.yaml` file. For example:

```yaml
dependencies:
  stacked_trio_carousel: ^0.0.1
```

## Usage

Specify the background, and set the width and height of the card. Then, provide the children.

```dart
final List _color = [Colors.red, Colors.green, Colors.blue];
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: Text(widget.title),
    ),
    body: Center(
      child: StackedTrioCarousel(
        background: Container(),
        cardHeight: 200,
        cardWidth: 200,
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
    ),
  );
}
```

### Change the Width and Height

You can modify the dimensions of the cards by changing the `cardHeight` and `cardWidth` properties.

```dart
cardHeight: 150,
cardWidth: 150,
```

<div style="display: flex; justify-content: space-around;">
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/change_size_1.gif" width="300"/>
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/change_size_2.gif" width="300"/>
</div>

### Add Padding

To apply padding to the background cards (horizontal padding only), use the `padding` property.

```dart
padding: const EdgeInsets.symmetric(horizontal: 10),
```

<div style="display: flex; justify-content: space-around;">
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/change_size_2.gif" width="300"/>
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/padding.gif" width="300"/>
</div>

### Change Scale and Minimum Opacity

The `scaleRatio` and `minimumOpacity` properties affect the background cards only.

```dart
scaleRatio: 0.2,
minimumOpacity: 0.1,
```

<div style="display: flex; justify-content: space-around;">
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/scale_and_opacity_1.gif" width="300"/>
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/scale_and_opacity_2.gif" width="300"/>
</div>

### Change Animation Duration

You can modify the animation duration and the delay between animations. A hot restart may be required for changes to take effect.

```dart
animationDuration: const Duration(milliseconds: 200),
durationBetweenAnimations: const Duration(seconds: 1),
```

<div style="display: flex; justify-content: space-around;">
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/default.gif" width="300"/>
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/animation_duration.gif" width="300"/>
</div>

### Manual Swiping

You can also allow manual swiping:

<div style="display: flex; justify-content: space-around;">
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/no_animation.gif" width="300"/>
</div>

### Stop Automatic Animation

To stop the automatic animation, set `isAnimated` to `false`.

```dart
isAnimated: false,
```

### Navigation Support with `RouteObserver`

If your app includes navigation functionality, you need to provide a `RouteObserver` to ensure the carousel behaves correctly when navigating between screens. Without this, the carousel might still be visible after navigation.

#### Steps to Add `RouteObserver`:

1. **Define the `RouteObserver` as a top-level variable and assign it to your `MaterialApp`:**

```dart
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
```

2. **Pass the `RouteObserver` to the `StackedTrioCarousel` widget:**

```dart
routeObserver: routeObserver,
```

3. **Perform a hot restart of the application.**

<div style="display: flex; justify-content: space-around;">
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/navigation_1.gif" width="300"/>
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/navigation_2.gif" width="300"/>
</div>

### Add controller 

```dart
final StackedTrioCarouselController _carouselController = StackedTrioCarouselController();
```

```dart
controller: _carouselController,
```
hide and show the carousel based on visibility 
```dart
ElevatedButton(
  onPressed: () {
    if (_carouselController.isVisible) {
      _carouselController.hide();
    } else {
      _carouselController.show();
    }
    setState(() {});
  },
  child: Text(_carouselController.isVisible ? "Hide" : "Show", style: const TextStyle(color: Colors.black)),
)
```
<div style="display: flex; justify-content: space-around;">
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/controller.gif" width="300"/>
</div>

## Example

For a full example, check out the [example page](https://pub.dev/packages/stacked_trio_carousel/example).
