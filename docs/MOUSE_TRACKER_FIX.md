# Mouse Tracker Assertion Fix

## Problem
The app was crashing with the error:
```
'package:flutter/src/rendering/mouse_tracker.dart': Failed assertion: 
line 199 pos 12: '!_debugDuringDeviceUpdate': is not true.
```

This occurs when `setState` is called during mouse pointer event handling, which violates Flutter's mouse tracking invariants.

## Root Cause
The `TactileBentoCard` widget was calling `setState` in the `onHover` callback, which fires very frequently (potentially hundreds of times per second) as the mouse moves. Even with `addPostFrameCallback`, this can cause assertion failures when many widgets are updating simultaneously.

## Solution
Replaced `setState` with `ValueNotifier` pattern and added throttling:

### Before (Problematic):
```dart
onHover: (e) => WidgetsBinding.instance.addPostFrameCallback((_) {
  if (mounted) setState(() => _hoverOffset = e.localPosition);
}),
```

### After (Fixed):
```dart
// Use ValueNotifier instead of setState
final ValueNotifier<Offset> _hoverOffsetNotifier = ValueNotifier<Offset>(Offset.zero);

// Throttle updates to max 30fps
void _handleHoverMove(Offset localPosition) {
  _pendingHoverOffset = localPosition;
  
  if (_hoverThrottleTimer?.isActive ?? false) {
    return; // Already scheduled
  }
  
  _hoverThrottleTimer = Timer(const Duration(milliseconds: 33), () {
    if (_pendingHoverOffset != null) {
      _hoverOffsetNotifier.value = _pendingHoverOffset!;
      _pendingHoverOffset = null;
    }
  });
}

// Use ValueListenableBuilder in build method
ValueListenableBuilder<Offset>(
  valueListenable: _hoverOffsetNotifier,
  builder: (context, hoverOffset, _) {
    // Build widget using hoverOffset
  },
)
```

## Key Improvements

1. **No setState during mouse tracking** - ValueNotifier updates don't trigger the assertion
2. **Throttling** - Limits updates to 30fps (every 33ms) instead of potentially hundreds per second
3. **Proper cleanup** - Timer is cancelled in dispose()
4. **Performance** - Reduces unnecessary rebuilds

## Best Practices

### ✅ DO:
- Use `ValueNotifier` for hover state that changes frequently
- Throttle/debounce frequent updates (hover, scroll, etc.)
- Use `ValueListenableBuilder` to rebuild only the parts that need updating
- Cancel timers in `dispose()`

### ❌ DON'T:
- Call `setState` in `onHover` callbacks
- Update state synchronously during pointer events
- Update state without throttling for frequent events

## Files Fixed
- `lib/widgets/tactile_bento_card.dart` - Main fix with throttled hover updates

## Testing
After this fix:
- ✅ No more mouse tracker assertion errors
- ✅ Smooth hover animations
- ✅ Better performance with many cards
- ✅ Proper cleanup on widget disposal

---

*Fixed: 2026-01-28*
