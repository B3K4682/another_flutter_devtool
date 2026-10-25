import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../keys.dart';
import '../theme/devtool_theme.dart';

/// A small floating button that can be dragged anywhere inside the safe area.
class DraggableLauncher extends StatefulWidget {
  const DraggableLauncher({
    super.key,
    required this.offset,
    required this.onMoved,
    required this.onTap,
    this.versionLabel,
  });

  static const double size = 36;
  static const double borderRadius = 8;
  static const double initialMargin = 16;

  /// Top-left position of the launcher; null places it at the top-left.
  final Offset? offset;
  final ValueChanged<Offset> onMoved;
  final VoidCallback onTap;

  /// Shown below the button when the App Information toggle is on.
  final String? versionLabel;

  @override
  State<DraggableLauncher> createState() => _DraggableLauncherState();
}

class _DraggableLauncherState extends State<DraggableLauncher> {
  Offset _dragStartPointer = Offset.zero;
  Offset _dragStartPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final bounds = _bounds(context);
    final position = _clamp(
      widget.offset ??
          Offset(bounds.left + DraggableLauncher.initialMargin, bounds.top + DraggableLauncher.initialMargin),
      bounds,
    );
    final versionLabel = widget.versionLabel;

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        key: DevtoolKeys.launcher,
        onTap: widget.onTap,
        dragStartBehavior: DragStartBehavior.down,
        onPanStart: (details) {
          _dragStartPointer = details.globalPosition;
          _dragStartPosition = position;
        },
        onPanUpdate: (details) =>
            widget.onMoved(_clamp(_dragStartPosition + details.globalPosition - _dragStartPointer, bounds)),
        child: SizedBox(
          width: DraggableLauncher.size,
          height: DraggableLauncher.size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: DraggableLauncher.size,
                height: DraggableLauncher.size,
                decoration: BoxDecoration(
                  color: DevtoolColors.primary,
                  borderRadius: BorderRadius.circular(DraggableLauncher.borderRadius),
                  boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: const Icon(Icons.code_rounded, size: 20, color: Colors.white),
              ),
              if (versionLabel != null)
                Positioned(
                  top: DraggableLauncher.size + 4,
                  left: DraggableLauncher.size / 2,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, 0),
                    child: _VersionBadge(label: versionLabel),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Rect _bounds(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final left = padding.left;
    final top = padding.top;
    final right = (screen.width - padding.right - DraggableLauncher.size).clamp(left, double.infinity);
    final bottom = (screen.height - padding.bottom - DraggableLauncher.size).clamp(top, double.infinity);
    return Rect.fromLTRB(left, top, right, bottom);
  }

  Offset _clamp(Offset value, Rect bounds) =>
      Offset(value.dx.clamp(bounds.left, bounds.right), value.dy.clamp(bounds.top, bounds.bottom));
}

class _VersionBadge extends StatelessWidget {
  const _VersionBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: DevtoolKeys.versionBadge,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: DevtoolColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: DevtoolColors.border),
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        style: const TextStyle(
          fontFamily: DevtoolTheme.fontFamily,
          fontSize: 10,
          height: 1.2,
          fontWeight: FontWeight.w500,
          color: DevtoolColors.textSecondary,
        ),
      ),
    );
  }
}
