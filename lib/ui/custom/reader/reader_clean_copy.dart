// app-owned: novel reader text
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:freepiv/ui/custom/reader/reader_line_text.dart';

/// Makes the text selected below it copy without the word joiners the reader
/// adds to Korean lines ([readerCopiedText]). The selection itself is
/// untouched; only the content it reports is cleaned.
class ReaderCleanCopy extends StatefulWidget {
  const ReaderCleanCopy({required this.child, super.key});

  final Widget child;

  @override
  State<ReaderCleanCopy> createState() => _ReaderCleanCopyState();
}

class _ReaderCleanCopyState extends State<ReaderCleanCopy> {
  _CleaningRegistrar? _registrar;
  SelectionRegistrar? _outer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final outer = SelectionContainer.maybeOf(context);
    if (_registrar == null || !identical(outer, _outer)) {
      _outer = outer;
      _registrar = outer == null ? null : _CleaningRegistrar(outer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final registrar = _registrar;
    if (registrar == null) return widget.child;
    return SelectionRegistrarScope(registrar: registrar, child: widget.child);
  }
}

class _CleaningRegistrar implements SelectionRegistrar {
  _CleaningRegistrar(this.outer);

  final SelectionRegistrar outer;
  final _wrapped = <Selectable, _CleanSelectable>{};

  @override
  void add(Selectable selectable) {
    final wrapper = _wrapped[selectable] ??= _CleanSelectable(selectable);
    outer.add(wrapper);
  }

  @override
  void remove(Selectable selectable) {
    final wrapper = _wrapped.remove(selectable);
    if (wrapper != null) outer.remove(wrapper);
  }
}

/// A selectable that is [inner] in everything but the plain text of its
/// selected content.
class _CleanSelectable with Selectable, ChangeNotifier {
  _CleanSelectable(this.inner) {
    inner.addListener(notifyListeners);
  }

  final Selectable inner;

  @override
  SelectionGeometry get value => inner.value;

  @override
  Matrix4 getTransformTo(RenderObject? ancestor) => inner.getTransformTo(ancestor);

  @override
  Size get size => inner.size;

  @override
  List<Rect> get boundingBoxes => inner.boundingBoxes;

  @override
  void pushHandleLayers(LayerLink? startHandle, LayerLink? endHandle) => inner.pushHandleLayers(startHandle, endHandle);

  @override
  SelectedContent? getSelectedContent() {
    final content = inner.getSelectedContent();
    return content == null ? null : SelectedContent(plainText: readerCopiedText(content.plainText));
  }

  @override
  SelectedContentRange? getSelection() => inner.getSelection();

  @override
  SelectionResult dispatchSelectionEvent(SelectionEvent event) => inner.dispatchSelectionEvent(event);

  @override
  int get contentLength => inner.contentLength;

  @override
  void dispose() {
    inner.removeListener(notifyListeners);
    super.dispose();
  }
}
