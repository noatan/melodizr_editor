import 'package:flutter/material.dart';

class MelodizrController extends TextEditingController {
  MelodizrController(
    this.style, {
    required this.widget,
    required this.regexMap,
  });

  final Map<RegExp, InlineSpan> regexMap;
  final TextStyle style;
  final Widget widget;

  List<WidgetSpan> _getPlaceholders(String path) {
    // this is actually a really really ugly solution.
    // The value.text has to hold the path, so we the text looks for example like this:
    // 'some text... 字https//:mypath文 ... some more text
    // In the case the path has about 14 characters. To prevent the path from being shown on the screen
    // we use a regex to filter it out an replace it with a WidgetSpan which holds our Widget (e.g AudioWidget)
    // the problem is now, that the selction system expects a item on the screen for each character in value.text.
    // This leads to the problem that if we just replace the path with a WidgetSpan the Selction System is of by the path length minus the one WidgetSpan we added.
    // I tried to update the Selection sytem according to the total amount of audio widget * path before the cursor position.
    // this actually updated the selction but not the cursor position, what is weird because if you want to change the cursor pos you update the selection,
    // so one would think they are synced.
    // The current solution until someone (including me) can find a better one it to add empty boxes according to the path.length.
    // In this case the selection system gets the right amount of item which are not selectable.
    // If you would add empty Strings the user is apperantly able to use them.
    List<WidgetSpan> placholders = [];
    for (int letterCount = 0; letterCount < path.length - 1; letterCount++) {
      placholders.add(
        const WidgetSpan(
          child: SizedBox.shrink(),
        ),
      );
    }

    placholders.add(WidgetSpan(
      child: widget,
    ));
    return placholders;
  }

  @override
  TextSpan buildTextSpan(
      {required BuildContext context,
      TextStyle? style,
      required bool withComposing}) {
    List<InlineSpan> children = [];

    text.splitMapJoin(
      RegExp(regexMap.keys.map((e) => e.pattern).join('|')),
      onNonMatch: (String span) {
        children.add(TextSpan(text: span, style: this.style));
        return span.toString();
      },
      onMatch: (
        Match m,
      ) {
        final RegExp key = regexMap.entries.firstWhere((element) {
          return element.key.allMatches(m[0]!).isNotEmpty;
        }).key;

        if (key == RegExp(r'\字(.*?)\文')) {
          children.add(
            TextSpan(
              children: _getPlaceholders(
                m[0].toString(),
              ),
            ),
          );
        } else {
          children.add(
            TextSpan(
              text: m[0],
              style: regexMap[key]!.style!,
            ),
          );
        }
        return m[0].toString();

        //return '${m[0]}'.toString();
      },
    );

    return TextSpan(children: children);
  }

  // @override
  // set selection(TextSelection newSelection) {
  //   print('helo');
  //   if (!isSelectionWithinTextBounds(newSelection)) {
  //     throw FlutterError('invalid text selection: $newSelection');
  //   }
  //   final TextRange newComposing = newSelection.isCollapsed &&
  //           _isSelectionWithinComposingRange(newSelection)
  //       ? value.composing
  //       : TextRange.empty;

  //   int cursorPos = newSelection.base.offset;

  //   String textToCheck = text.substring(0, cursorPos);

  //   int count =
  //       textToCheck.length - textToCheck.replaceAll(RegExp(r'字'), '').length;

  //   int spacesToMoveCursor = count * 6;

  //   TextSelection adaptedSelection = TextSelection(
  //       baseOffset: newSelection.baseOffset + spacesToMoveCursor,
  //       extentOffset: newSelection.extentOffset + spacesToMoveCursor);

  //   value =
  //       value.copyWith(selection: adaptedSelection, composing: newComposing);
  // }

  // _overrideSelection(TextSelection newSelection) {}

  // bool _isSelectionWithinComposingRange(TextSelection selection) {
  //   return selection.start >= value.composing.start &&
  //       selection.end <= value.composing.end;
  // }

  //String get realText => super.value.text;
/*
  @override
  set value(TextEditingValue newValue) {
    assert(
      !newValue.composing.isValid || newValue.isComposingRangeValid,
      'New TextEditingValue $newValue has an invalid non-empty composing range '
      '${newValue.composing}. It is recommended to use a valid composing range, '
      'even for readonly text fields',
    );
    // User is currently editing the text
    if (newValue.text != super.value.text) {
      // count of all audios inside the node
      int count = textWithIdentifiers.length -
          textWithIdentifiers.replaceAll(RegExp(r'字'), "").length;

      // User is typing at the end of the text
      if (newValue.selection.baseOffset >= super.value.text.length) {
        print('User types at the end');

        final addedString = newValue.text.substring(
            newValue.selection.baseOffset - 1, newValue.selection.extentOffset);
        print(addedString);
        textWithIdentifiers += addedString;
      }
      // User is typing inside the text
      else {
        final addedString = newValue.text.substring(
            newValue.selection.baseOffset - 1, newValue.selection.extentOffset);
      }

      // User added an audio
      if (newValue.text.contains(RegExp(r'字'))) {
        print('Audio added');
        textWithIdentifiers += '字';
      }
    }

    TextEditingValue neeewValue = TextEditingValue(
        composing: newValue.composing,
        selection: newValue.selection,
        text: newValue.text.replaceAll(RegExp(r'字'), ''));

    super.value = neeewValue;
  }*/

}
