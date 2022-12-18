import 'package:flutter/material.dart';

class MelodizrController extends TextEditingController {
  MelodizrController({
    String? text,
    required this.widget,
  });
  String _lastValue = "";

  // widge will be the draggable
  Widget widget;

  @override
  TextSpan buildTextSpan(
      {required BuildContext context,
      TextStyle? style,
      required bool withComposing}) {
    // add more checks
    List<String> regex = [];
    List<InlineSpan> children = [];

    text.splitMapJoin(
      //RegExp(r'\{{@[a-zA-Z0-9]+\b'),
      //RegExp(r'#(.*?)+\b'),
      RegExp(r'字'),
      onNonMatch: (String span) {
        children.add(TextSpan(
          text: span,
          style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              decorationThickness: 0.001,
              height: 1.2),
        ));
        return span.toString();
      },
      onMatch: (
        Match m,
      ) {
        children.add(
          TextSpan(
            children: [
              WidgetSpan(
                child: widget,
              ),
            ],
          ),
        );

        return '${m[0]}'.toString();
      },
    );
    _lastValue = text;
    return TextSpan(children: children);
  }
}
