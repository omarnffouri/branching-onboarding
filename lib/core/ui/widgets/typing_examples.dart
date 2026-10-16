import 'dart:async';

import 'package:flutter/material.dart';

/// Types an example, pauses, erases it, and moves to the next.
/// Still (just the first example) under reduced motion.
class TypingExamples extends StatefulWidget {
  const TypingExamples({
    required this.examples,
    required this.style,
    super.key,
  });

  final List<String> examples;
  final TextStyle style;

  @override
  State<TypingExamples> createState() => _TypingExamplesState();
}

class _TypingExamplesState extends State<TypingExamples> {
  Timer? _timer;
  var _example = 0;
  var _shown = 0;
  var _erasing = false;

  /// The text on screen; only the hint redraws as it types.
  final ValueNotifier<String> _text = ValueNotifier('');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _timer?.cancel();
      _timer = null;
    } else if (_timer == null) {
      _schedule(const Duration(milliseconds: 500));
    }
  }

  void _schedule(Duration delay) => _timer = Timer(delay, _tick);

  void _tick() {
    if (!mounted) return;
    final length = widget.examples[_example].characters.length;
    if (!_erasing && _shown < length) {
      _shown++;
    } else if (!_erasing) {
      _erasing = true;
    } else if (_shown > 0) {
      _shown--;
    } else {
      _erasing = false;
      _example = (_example + 1) % widget.examples.length;
    }
    _text.value = widget.examples[_example].characters.take(_shown).toString();
    _schedule(switch ((_erasing, _shown)) {
      (false, final shown) when shown == length => const Duration(
        milliseconds: 1400,
      ),
      (false, _) => const Duration(milliseconds: 110),
      (true, 0) => const Duration(milliseconds: 350),
      (true, _) => const Duration(milliseconds: 45),
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MediaQuery.disableAnimationsOf(context)
      ? Text(widget.examples[_example], style: widget.style, maxLines: 1)
      : _TypedText(text: _text, style: widget.style);
}

/// The hint as typed so far, redrawn whenever it changes.
class _TypedText extends AnimatedWidget {
  const _TypedText({required ValueNotifier<String> text, required this.style})
    : super(listenable: text);

  final TextStyle style;

  @override
  Widget build(BuildContext context) => Text(
    (listenable as ValueNotifier<String>).value,
    style: style,
    maxLines: 1,
  );
}
