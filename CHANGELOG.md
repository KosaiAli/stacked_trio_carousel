## 0.0.1

- Initial release.

## 0.0.2

- Update README.md

## 0.0.3

- ADD repository

## 0.0.4

- ADD stacked trio carousel controller 

## 0.0.5

- Fix Bugs

## 1.0.0

- Animation Logic Moved to Controller

## 1.0.1

- Update README.md

## 1.0.2 

- Fix analysis warnings and align code with Flutter/Dart linting rules

## 1.0.3 

- Add customizable orientation for items in the carousel

## 1.0.4

- Update README.md

## 1.0.5

- Resolve Dart formatting issues
- Add vertical padding 

## 1.1.0

- Added the Reveal Back Cards feature for a more user-friendly experience
- Introduced `SwipingDirection` to support RTL and LTR animations
- Improved user-driven animation to support both forward and backward motion
- Improved animation smoothness
- Reduced rebuilds for better performance
- Added support for vertical padding

## 1.1.1

- Fixed “failed to insert entry” error by deferring layout logic using a post-frame callback
- Prevented swiping gestures on back-layer cards
- Disabled `onTap` execution unless the animation value is at `0.5`
- Restored auto-play (timer-based) animation after tapping a back-layer card
- Corrected initial size calculation to properly use the card’s width and height
- Ensured parameter changes take effect correctly during hot reload
