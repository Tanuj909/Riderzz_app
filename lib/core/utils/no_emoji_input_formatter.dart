import 'package:flutter/services.dart';
export 'package:flutter/services.dart';

/// Formatter that denies/blocks all emojis, symbols, and pictographs
/// from being entered or pasted into text input fields.
class NoEmojiInputFormatter extends FilteringTextInputFormatter {
  NoEmojiInputFormatter()
      : super.deny(
          RegExp(
            r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}\u{1F900}-\u{1F9FF}\u{1FA70}-\u{1FAFF}\u{1F7E0}-\u{1F7EB}\u{1F004}-\u{1F0CF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{231A}-\u{231B}\u{23E9}-\u{23EC}\u{23F0}-\u{23F3}\u{FE00}-\u{FE0F}\u{200D}]',
            unicode: true,
          ),
        );
}

