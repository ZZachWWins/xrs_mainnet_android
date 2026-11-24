import 'package:flutter/foundation.dart';

/// Closing an inactive tab must preserve the identity of the active page.
/// The close callback invalidates its native bridge before the view is removed.
int closeTabAndPreserveActive<T>({
  required List<T> tabs,
  required int activeIndex,
  required int closingIndex,
  required void Function(T tab) close,
}) {
  RangeError.checkValidIndex(activeIndex, tabs);
  RangeError.checkValidIndex(closingIndex, tabs);
  if (tabs.length <= 1) return activeIndex;
  close(tabs[closingIndex]);
  tabs.removeAt(closingIndex);
  if (closingIndex < activeIndex) return activeIndex - 1;
  return activeIndex < tabs.length ? activeIndex : tabs.length - 1;
}

/// A title result belongs only to its original mounted tab and controller.
Future<void> applyCurrentTabTitle({
  required bool Function() isCurrent,
  required Future<String?> Function() readTitle,
  required void Function(String? title) apply,
}) async {
  if (!isCurrent()) return;
  final String? title;
  try {
    title = await readTitle();
  } catch (_) {
    return; // Optional page metadata must not revive a disposed view.
  }
  if (isCurrent()) apply(title);
}

/// Parent navigation selection is synchronous; pixel-visibility callbacks are
/// too late to authorize an already-pending native wallet request.
class BrowserPageActivity {
  ValueListenable<bool>? _selected;
  final void Function() onHidden;
  BrowserPageActivity(
      {ValueListenable<bool>? selected, required this.onHidden}) {
    bind(selected);
  }
  bool get isSelected => _selected?.value ?? true;
  void _changed() {
    if (!isSelected) onHidden();
  }

  void bind(ValueListenable<bool>? selected) {
    _selected?.removeListener(_changed);
    _selected = selected;
    _selected?.addListener(_changed);
    _changed();
  }

  void dispose() => _selected?.removeListener(_changed);
}
