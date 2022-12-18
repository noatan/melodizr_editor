import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui show BoxHeightStyle, BoxWidthStyle;

import 'package:melodizr_editor/src/controller.dart';
import 'package:melodizr_editor/src/painter.dart';
import 'package:melodizr_editor/src/text_field.dart';

// TODO
// auto scrolling => done
// WidgetSpan instead of hardcoded Draggable => done
// last line bug => done

// selection ignore widget

class MelodizrTextEditor extends StatefulWidget {
  const MelodizrTextEditor({
    super.key,
    required this.controller,
  });

  final MelodizrController controller;
  final TextStyle style = const TextStyle(
      color: Colors.black,
      fontSize: 20,
      fontWeight: FontWeight.w500,
      decorationThickness: 0.001,
      height: 1.6);
  @override
  State<MelodizrTextEditor> createState() => _MelodizrTextEditorState();
}

class _MelodizrTextEditorState extends State<MelodizrTextEditor> {
  final _textkey = GlobalKey<EditableTextState>();
  final _fieldKey = GlobalKey();

  final List<Rect> _textRects = [];
  Rect? _currentRect;

  late ScrollController _scrollController;

  late MelodizrController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MelodizrController(widget: _customDraggble());
    _scrollController = ScrollController();
  }

  // TODO currently a normal Draggable => we should use a LongPress... but the long press collides with the startIndex finding.
  // TODO because the User can movehis finger before a LongPress.. captures the position
  Widget _customDraggble() {
    return Draggable(
      axis: Axis.vertical,
      affinity: Axis.vertical,
      maxSimultaneousDrags: 1,
      onDragEnd: ((details) => _dragEnd(details)),
      onDragUpdate: ((details) => _dragUpdate(details)),
      feedback: _buildAudio(
        'sd',
        0.2,
        35,
        width: 200,
      ),
      childWhenDragging: const SizedBox.shrink(),
      child: _buildAudio('sds', 0.3, 40),
    );
  }

  Widget _buildAudio(
    String text,
    double opacity,
    double height, {
    double? width,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(
            Radius.circular(5),
          ),
          color: Colors.red.withOpacity(opacity),
        ),
        child: Center(
          child: Row(
            children: [],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  int? startIndex;

  void _dragUpdate(DragUpdateDetails details) {
    if (_renderer == null) {
      return;
    }
    final allTextRects = _getRectsForHoverUnderline(
      TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.characters.length,
      ),
    );

    // Auto-Scroll start

    // TODO you have to move the item to keep scrolling => should scroll while keeping the position
    const moveDistance = 3;
    Offset pos = fieldBox.localToGlobal(Offset.zero);

    const range = 100;
    if (details.globalPosition.dy < pos.dy + range) {
      double newpos = _scrollController.offset - moveDistance;
      newpos = (newpos < 0) ? 0 : newpos;

      _scrollController.jumpTo(newpos);
    }
    if (details.globalPosition.dy > (pos.dy + fieldBox.size.height) - range) {
      _scrollController.jumpTo(_scrollController.offset + moveDistance);
    }
    // Auto-Scroll end

    for (final rect in allTextRects) {
      //
      RenderBox? box = context.findRenderObject() as RenderBox;
      var hoverPos = box.globalToLocal(details.globalPosition);

      if (startIndex == null) {
        final hoverTestBaseOffset =
            _renderer.getPositionForPoint(details.globalPosition);
        final currentLine = _renderer.getLineAtOffset(hoverTestBaseOffset);
        startIndex = currentLine.base.offset;
      }
      if (rect.contains(hoverPos)) {
        // only called if startIndex is null to set an initial index

        setState(() {
          _currentRect = rect;
        });
      }
    }
  }

  void _dragEnd(
    DraggableDetails details,
  ) {
    _currentRect = null;
    if (_renderer == null) {
      return;
    }
    final allTextRects = _getRectsForHoverUnderline(
      TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.characters.length,
      ),
    );

    for (final rect in allTextRects) {
      // ? maybe we can hold the hpver position in an external value,
      // ? so we avoid duplictation
      RenderBox? box = context.findRenderObject() as RenderBox;
      var hoverPos = box.globalToLocal(details.offset);

      // only called, if we hover over a textWidget
      if (rect.contains(hoverPos)) {
        _currentRect = rect;
        try {
          final hoverTestBaseOffset =
              _renderer.getPositionForPoint(details.offset);
          final currentLine = _renderer.getLineAtOffset(hoverTestBaseOffset);

          currentLine.base.offset;

          _controller.value = _controller.value.replaced(
              TextRange(start: startIndex!, end: startIndex! + 1), '');
          //_editableState.performAction(TextInputAction.newline);

          var currentPos = currentLine.extent.offset;

          // Add new text on cursor position
          String specialChars = '字';
          int length = specialChars.length;

          if (currentPos > _controller.text.length) {
            _controller.text = _controller.text + specialChars;
            _controller.selection = TextSelection(
              baseOffset: _controller.text.length + length,
              extentOffset: _controller.text.length + length,
            );
          } else {
            // Right text of cursor position
            String suffixText = _controller.text.substring(currentPos);

            // Get the left text of cursor
            String prefixText = _controller.text.substring(0, currentPos);

            _controller.text = prefixText + specialChars + suffixText;

            // Cursor move to end of added text
            _controller.selection = TextSelection(
              baseOffset: currentPos + length,
              extentOffset: currentPos + length,
            );
          }
        } catch (e) {
          print(e);
        }

        setState(() {
          startIndex = null;
        });
      }
    }
  }

  EditableTextState get _editableState => _textkey.currentState
      as EditableTextState; //_textkey.currentState as EditableTextState;

  RenderEditable get _secondRenderer => _editableState.renderEditable;

  RenderEditable get _renderer =>
      _textkey.currentState!.renderEditable; //_editableState.renderEditable;

  RenderBox get fieldBox =>
      _fieldKey.currentContext?.findRenderObject() as RenderBox;

  List<Rect> _getRectsForHoverUnderline(TextSelection textSelection) {
    if (_renderer == null) {
      return [];
    }

    final textBoxes = _renderer.getBoxesForSelection(textSelection);

    return textBoxes.map((box) => box).toList();
  }

  List<Widget> _buildTextField() {
    return [
      Builder(builder: (context) {
        if (_currentRect == null) {
          return const SizedBox();
        } else {
          return CustomPaint(
            painter: HoverLinePainter(
              color: Colors.red,
              rects: _currentRect,
              fill: false,
            ),
          );
        }
      }),
      MeloTextField(
        key: _fieldKey,
        editingKey: _textkey,
        selectionHeightStyle: ui.BoxHeightStyle.tight,
        selectionWidthStyle: ui.BoxWidthStyle.tight,
        scrollController: _scrollController,
        autofocus: true,
        keyboardType: TextInputType.multiline,
        maxLines: 99999,
        //key: _textkey,
        controller: _controller,
        focusNode: FocusNode(),
        //style: widget.style,
        cursorColor: Colors.red,
        //backgroundCursorColor: Colors.white,
        toolbarOptions: const ToolbarOptions(
          copy: true,
          cut: true,
          selectAll: true,
          paste: true,
        ),
      ),
      Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {
              var cursorPos = _controller.selection.base.offset;

              String suffixText = _controller.text.substring(cursorPos);

              var path = 'https://dfgkdfgndnf';

              String specialChar = '字';
              int length = specialChar.length;

              String prefixText = _controller.text.substring(0, cursorPos);

              _controller.text = prefixText + specialChar + suffixText;

              // Cursor move to end of added text
              _controller.selection = TextSelection(
                baseOffset: cursorPos + length,
                extentOffset: cursorPos + length,
              );
            },
            child: Container(
              color: Colors.red,
              height: 30,
            ),
          ))
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: _buildTextField());
  }
}

/*Map<RegExp, TextStyle> patternUser = {
    RegExp(r"\B@[a-zA-Z0-9]+\b"):
        const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)
  };*/
