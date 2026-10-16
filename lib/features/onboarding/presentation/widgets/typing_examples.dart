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
  var _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.disableAnimationsOf(context);
    if (!_still && _timer == null) _schedule(const Duration(milliseconds: 500));
  }

  void _schedule(Duration delay) => _timer = Timer(delay, _tick);

  void _tick() {
    if (!mounted) return;
    final length = widget.examples[_example].characters.length;
    setState(() {
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
    });
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final example = widget.examples[_example].characters;
    return Text(
      _still ? example.toString() : example.take(_shown).toString(),
      style: widget.style,
      maxLines: 1,
    );
  }
}
