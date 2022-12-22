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
// make functions smaller and more readable => part done

class MelodizrTextEditor extends StatefulWidget {
  const MelodizrTextEditor(
    this.style,
    this.hovercolor, {
    super.key,
    required this.path,
    required this.toolbar,
    required this.regexMap,
    required this.placeholder,
    required this.feedback,
  });
  // toolbar to add widget to the text
  final Widget toolbar;

  // map with regex an the widget it should return
  final Map<RegExp, InlineSpan> regexMap;

  // default text style
  final TextStyle? style;
  final Widget placeholder;

  // widget while the user is dragging
  final Widget feedback;

  // path inside the widegt => e.g. an url
  final String path;

  // color of line under the currently hovered text line
  final Color? hovercolor;

  @override
  State<MelodizrTextEditor> createState() => _MelodizrTextEditorState();
}

class _MelodizrTextEditorState extends State<MelodizrTextEditor> {
  final _textkey = GlobalKey<EditableTextState>();
  final _fieldKey = GlobalKey();

  // rectangle of the currently hovered renderbox
  Rect? _currentRect;

  // controller to handle auto scroll
  late ScrollController _scrollController;

  // custom TextEdititingController
  late MelodizrController _controller;

  // very ugly solution => we store the last text value to check if the user changed the text
  // there is no implimentation inside flutter to track soft keyboard input since it comes in event
  // which are triggered in a different way than a hardware keyboard
  String lastTextValue = '';

  // holds the textline position inside the text where the user started to drag the widget
  int? dragStartIndex;

  @override
  void initState() {
    super.initState();
    _controller = MelodizrController(
      widget.style ??
          const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              decorationThickness: 0.001,
              height: 1.2),
      widget: _customDraggble(),
      regexMap: widget.regexMap,
    );

    // A Textfield has a method called 'onChanged' but this method gets only called if the text changes
    // but we want to be notified if the value inside the controller changes
    _controller.addListener(_valueChanged);
    _scrollController = ScrollController();
  }

  // TODO currently a normal Draggable => we should use a LongPress... but the long press collides with the startIndex finding.
  // TODO because the User can movehis finger before a LongPress.. captures the position
  Widget _customDraggble() {
    return Draggable(
        data: '',
        axis: Axis.vertical,
        affinity: Axis.vertical,
        maxSimultaneousDrags: 1,
        onDragEnd: ((details) => _dragEnd(details)),
        onDragUpdate: ((details) => _dragUpdate(details)),
        feedback: widget.feedback,
        childWhenDragging: const SizedBox.shrink(),
        child: widget.placeholder //_buildAudio('sds', 0.3, 40),
        );
  }

  bool _checkIfUserIsInsideTheWidget(int cursorPos) {
    // since we add an audio widget the selection sytsem of flutter counts it as selectble
    // if the user clicks on it he is inside the identifier and can change the path
    // to prevent this we check if he is inside and if its true we move him out before he can do anything

    // The text is empty => the user cant be inside the widget
    if (_controller.value.text.isEmpty) {
      return false;
    }
    //
    if (cursorPos == _controller.value.text.length) {
      return false;
    }
    String textAfterCursor =
        _controller.value.text.substring(cursorPos, cursorPos + 1);
    if (textAfterCursor == '文') {
      // the user is inside the widget
      return true;
    }
    return false;
  }

  void _moveUserOutofWidget(int cursorPos) {
    // moves currently only the cursor but you hae to manually click again
    // not the best solution but it works for now
    TextSelection newSelection = TextSelection(
      baseOffset: cursorPos - 1,
      extentOffset: cursorPos - 1,
    );
    _controller.value = TextEditingValue(
      selection: newSelection,
      text: _controller.value.text,
      composing: _controller.value.composing,
    );
  }

  void _deleteIdentifierWithPath(int cursorPos) {
    String suffixText = _controller.text.substring(cursorPos);

    // text berfore the cursor pos minus the path
    String prefixText =
        _controller.text.substring(0, cursorPos - (widget.path.length + 1));

    String newText = prefixText + suffixText;

    // new selection => cursor to the end
    TextSelection newSelection = TextSelection(
      baseOffset: prefixText.length,
      extentOffset: prefixText.length,
    );

    // needs to be updated here, otherwise the funciton is recursive
    lastTextValue = newText;

    setState(
      () {
        _controller.value = TextEditingValue(
            text: newText,
            selection: newSelection,
            composing: const TextRange.collapsed(0));
      },
    );
  }

  // TextValue changed
  void _valueChanged() {
    int cursorPos = _controller.selection.base.offset;

    if (_checkIfUserIsInsideTheWidget(cursorPos)) {
      _moveUserOutofWidget(cursorPos);
    }

    // user deleted text
    if (lastTextValue.length > _controller.text.length) {
      // user deleted identifier
      if (lastTextValue.substring(cursorPos, cursorPos + 1) == '文') {
        // text after the cursor position
        _deleteIdentifierWithPath(cursorPos);
        return;
      }
    }
    lastTextValue = _controller.text;
  }

  _handleAutoScroll(DragUpdateDetails details) {
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
  }

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

    _handleAutoScroll(details);

    for (final rect in allTextRects) {
      //
      RenderBox? box = context.findRenderObject() as RenderBox;
      var hoverPos = box.globalToLocal(details.globalPosition);

      if (dragStartIndex == null) {
        final hoverTestBaseOffset =
            _renderer.getPositionForPoint(details.globalPosition);
        final currentLine = _renderer.getLineAtOffset(hoverTestBaseOffset);
        dragStartIndex = currentLine.base.offset;
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
        try {
          final hoverTestBaseOffset =
              _renderer.getPositionForPoint(details.offset);
          final currentLine = _renderer.getLineAtOffset(hoverTestBaseOffset);

          // print(
          //     'Range: ${_controller.value.text.substring(startIndex! - (1 + widget.path.length), (startIndex! + 1))}');
          _controller.value = _controller.value.replaced(
              TextRange(
                start: dragStartIndex! - (1 + widget.path.length),
                end: (dragStartIndex! + 1),
              ),
              '');

          var currentPos = currentLine.extent.offset;

          // Add new text on cursor position
          String specialChars = '字${widget.path}文';
          int length = specialChars.length;

          if (currentPos > _controller.text.length) {
            _controller.text = _controller.text + specialChars;
            _controller.selection = TextSelection(
              baseOffset: _controller.text.length + length,
              extentOffset: _controller.text.length + length,
            );
          } else {
            _insertIdentifier(currentPos);
          }
        } catch (e) {
          print(e);
        }
        setState(() {
          dragStartIndex = null;
        });
      }
    }
  }

  void _insertIdentifier(int pos) {
    // text after pos
    String suffixText = _controller.text.substring(pos);

    // identfier for the Widget => is a random chinese sign to prevent the user from using it
    // TODO find a save alternitive
    String identifier = '字${widget.path}文';

    int length = identifier.length;

    // text before the pos
    String prefixText = _controller.text.substring(0, pos);

    String newText = prefixText + identifier + suffixText;

    //new selection
    TextSelection selection = TextSelection(
      baseOffset: pos + length,
      extentOffset: pos + length,
    );

    // Cursor move to end of added text
    _controller.value = TextEditingValue(
        text: newText,
        selection: selection,
        composing: const TextRange.collapsed(-1));
  }

  // gets the RenderObject of the EditableTextWidget => the EditableTextWidget is by default instantiated by the TextField
  RenderEditable get _renderer => _textkey.currentState!.renderEditable;

  // RenderObject of the Textfield => needed for the auto-scroller
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
              color: widget.hovercolor ?? Colors.red.withOpacity(0.7),
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
              int cursorPos = _controller.selection.base.offset;
              _insertIdentifier(cursorPos);
            },
            child: widget.toolbar,
          )),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: _buildTextField());
  }
}
