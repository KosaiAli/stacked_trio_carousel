# Stacked Trio Carousel

**Stacked Trio Carousel** is a Flutter package that provides a visually engaging widget carousel with a stacked layout of three layered widgets.

## Features

The carousel features one prominent widget in the foreground and two widgets in the background, making it perfect for showcasing content in a layered and dynamic way. With built-in animations and customizable properties, users can swipe through the widgets or enable automatic transitions for a smooth and interactive experience.

<div style="display: flex; justify-content: space-around;">
<img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/default.gif" width="300"/>
</div>

## 🆕 What's New

### ✨ New

- Added the Reveal Back Widgets feature for a more user-friendly experience
- Introduced `SwipingDirection` to support RTL and LTR animations

### 🛠 Improvements

- Improved user-driven animation to support both forward and backward motion
- Improved animation smoothness
- Reduced rebuilds for better performance
- Added support for vertical padding

## Getting Started

To use this package, add `stacked_trio_carousel` as a dependency in your `pubspec.yaml` file. For example:

```yaml
dependencies:
  stacked_trio_carousel: ^1.2.0
```

## Usage

Specify the background widget, and set the width and height of the widgets.

Make sure to specify the height and width of the carousel so it behaves properly when used inside a `Column`, `Row`, or `ListView`.

```dart
@override
Widget build(BuildContext context) {
  final List _color = [Colors.red, Colors.green, Colors.blue];
  return Scaffold(
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
          params: StackedTrioCarouselParams(widgetHeight: 200, widgetWidth: 200),
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
            _carouselController.autoPlay ? "Stop Auto Play" : "Start Auto Play",
          ),
        ),
      ],
    ),
  );
}
```

### Change the Width and Height

You can modify the dimensions of the widgets by changing the `widgetHeight` and `widgetWidth` properties.

```dart
StackedTrioCarouselParams(
  widgetHeight: 150,
  widgetWidth: 150,
)
```

<div style="display: flex; justify-content: space-around;">
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/default.gif" width="300"/>
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/change_size.gif" width="300"/>
</div>

### Add Padding

To apply padding to the background widgets, use the `firstWidgetPadding` and `secondWidgetPadding` properties.
Each property controls the padding of its corresponding background widget independently.

#### Padding from outside

```dart
StackedTrioCarouselParams(
  widgetHeight: 150,
  widgetWidth: 150,
  firstWidgetPadding: const EdgeInsets.only(left: 10),
  secondWidgetPadding: const EdgeInsets.only(right: 10),
)
```

<div style="display: flex; justify-content: space-around;">
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/change_size.gif" width="300"/>
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/padding_1.gif" width="300"/>
  
</div>

#### Padding from inside

```dart
StackedTrioCarouselParams(
  widgetHeight: 150,
  widgetWidth: 150,
  firstWidgetPadding: const EdgeInsets.only(right: 10),
  secondWidgetPadding: const EdgeInsets.only(left: 10),
)
```

<div style="display: flex; justify-content: space-around;">
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/change_size.gif" width="300"/>
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/padding_2.gif" width="300"/>
</div>

### Change Scale and Minimum Opacity

The `scaleRatio` and `minimumOpacity` properties affect the background widgets only.

```dart
StackedTrioCarouselParams(
  widgetHeight: 150,
  widgetWidth: 150,
  firstWidgetPadding: const EdgeInsets.only(right: 10),
  secondWidgetPadding: const EdgeInsets.only(left: 10),
  scaleRatio: 0.5,
  minimumOpacity: 0.3,
)
```

<div style="display: flex; justify-content: space-around;">
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/padding_2.gif" width="300"/>
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/scale_and_opacity.gif" width="300"/>
</div>

### Dynamic Angle

The `angle` property allows you to control the rotation angle of the widgets.

#### 45° Example

```dart
StackedTrioCarouselParams(
  widgetHeight: 200,
  widgetWidth: 200,
  angle: pi / 4,
),
```

<div style="display: flex; justify-content: space-around;">
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/default.gif" width="300"/>
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/45_degree.gif" width="300"/>
</div>

#### 90° Example

```dart
StackedTrioCarouselParams(
  widgetHeight: 200,
  widgetWidth: 200,
  angle: pi / 2,
),
```

<div style="display: flex; justify-content: space-around;">
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/default.gif" width="300"/>
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/90_degree.gif" width="300"/>
</div>

### Add a Controller

Adding a controller will give you more settings to tweak.

```dart
late StackedTrioCarouselController _carouselController;

@override
void initState() {
  _carouselController = StackedTrioCarouselController(tickerProvider: this);
  super.initState();
}
```

```dart
controller: _carouselController,
```

#### Add Curves

You can customize how the animation accelerates and decelerates by using the `animationCurve` property.  
This allows you to control the feel of the animation, whether it’s smooth, sharp, or more elastic.

> **Note:** Use a single-direction curve, symmetry is handled automatically.

```dart
_carouselController = StackedTrioCarouselController(
  tickerProvider: this,
  animationCurve: Easing.legacy,
);
```

<div style="display: flex; justify-content: space-around;">
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/default.gif" width="300"/>
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/curves.gif" width="300"/>
</div>

#### Change Swap Confirmation Distance

The `swapConfirmationDistance` defines the minimum swipe progress required to confirm a card swap.

```dart
_carouselController = StackedTrioCarouselController(
    tickerProvider: this,
    animationCurve: Easing.legacy,
    swapConfirmationDistance: 0.2,
);
```

<div style="display: flex; justify-content: space-around;">
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/curves.gif" width="300"/>
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/swipe_confirmation_distance.gif" width="300"/>
</div>

#### Change Animation speed

You can modify the animation speed and the delay between animations.

```dart
_carouselController = StackedTrioCarouselController(
    tickerProvider: this,
    animationDuration: const Duration(milliseconds: 1000),
    autoPlayInterval: const Duration(seconds: 1),
);
```

<div style="display: flex; justify-content: space-around;">
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/default.gif" width="300"/>
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/animation_duration.gif" width="300"/>
</div>

#### Stop Automatic Animation

To stop the automatic animation, set `autoPlay` to `false`.

```dart
_carouselController = StackedTrioCarouselController(
    tickerProvider: this,
    animationDuration: const Duration(milliseconds: 1000),
    autoPlayInterval: const Duration(seconds: 1),
    autoPlay: false
);
```

You can also use the `startAutoPlay` and `stopAutoPlay` functions

```dart
ElevatedButton(
    onPressed: () {
        _carouselController.autoPlay ? _carouselController.stopAutoPlay() : _carouselController.startAutoPlay();
        setState(() {});
    },
    child: Text(
        _carouselController.autoPlay ? "Stop Auto Play" : "Start Auto Play",
        style: const TextStyle(color: Colors.black),
    ),
)
```

#### Change Animation Direction

You can use the `swipingDirection` parameter in the `StackedTrioCarouselController` constructor to change the animation direction.

- `SwipingDirection.rtl` for right-to-left
- `SwipingDirection.ltr` for left-to-right

```dart
_carouselController = StackedTrioCarouselController(
    tickerProvider: this,
    animationDuration: const Duration(milliseconds: 1000),
    autoPlayInterval: const Duration(seconds: 1),
    swipingDirection: .ltr,
);
```

<div style="display: flex; justify-content: space-around;">
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/animation_duration.gif" width="300"/>
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/ltr.gif" width="300"/>
</div>

### Manual Swiping

Manual swiping is supported:

<div style="display: flex; justify-content: space-around;">
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/user_driven.gif" width="300"/>
</div>

### Reveal Back Layer Widgets

You can interact with the back layer widgets by tapping on them to bring them to the front.

> **Note:** The `onTap` parameter is only triggered when tapping the front widget.

<div style="display: flex; justify-content: space-around;">
  <img src="https://raw.githubusercontent.com/KosaiAli/stacked_trio_carousel/refs/heads/main/doc/press_back_card.gif" width="300"/>
</div>

## **Contributors**

[![GitHub Profile](https://img.shields.io/badge/GitHub-GhassanJar3850-blue?style=for-the-badge&logo=github&logoColor=white)](https://github.com/GhassanJar3850)

## **Examples**

- For a full example, check out the [example page](https://pub.dev/packages/stacked_trio_carousel/example).

- For more advanced and visually rich animation examples, check out the [Gift Cards Example](https://github.com/KosaiAli/stacked_trio_carousel/tree/main/example/lib/gift_cards_example.dart) and the [Yu Gi Oh Cards Example](https://github.com/KosaiAli/stacked_trio_carousel/tree/main/example/lib/yu_gi_oh_cards_example.dart) on [Github](https://github.com/KosaiAli/stacked_trio_carousel)
