import 'package:flutter/material.dart';

class SelectField extends FormField<String> {
  SelectField({
    super.key,
    required List<String> options,
    required String? value,
    required ValueChanged<String?> onChanged,
    super.validator,
    String hint = 'Select',
  }) : super(
         initialValue: value,
         builder: (state) {
           return _SelectFieldBody(
             state: state,
             options: options,
             hint: hint,
             onChanged: onChanged,
           );
         },
       );
}

class _SelectFieldBody extends StatefulWidget {
  final FormFieldState<String> state;
  final List<String> options;
  final String hint;
  final ValueChanged<String?> onChanged;

  const _SelectFieldBody({
    required this.state,
    required this.options,
    required this.hint,
    required this.onChanged,
  });

  @override
  State<_SelectFieldBody> createState() => _SelectFieldBodyState();
}

class _SelectFieldBodyState extends State<_SelectFieldBody> {
  static const _blue = Color(0xFF227BFF);
  static const _navy = Color(0xFF1A2A4A);

  bool _open = false;

  Future<void> _showMenu() async {
    final box = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final topLeft = box.localToGlobal(
      Offset(0, box.size.height + 6),
      ancestor: overlay,
    );
    final position = RelativeRect.fromRect(
      Rect.fromLTWH(topLeft.dx, topLeft.dy, box.size.width, 0),
      Offset.zero & overlay.size,
    );

    final current = widget.state.value;
    setState(() => _open = true);

    final picked = await showMenu<String>(
      context: context,
      position: position,
      constraints: BoxConstraints.tightFor(width: box.size.width),
      color: Colors.white,
      elevation: 10,
      shadowColor: Colors.black38,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      items:
          widget.options.map((e) {
            final selected = e == current;
            return PopupMenuItem<String>(
              value: e,
              height: 76,
              padding: EdgeInsets.zero,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                color: selected ? const Color(0xFFEAF2FF) : Colors.transparent,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? _blue : _navy,
                        ),
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_rounded, color: _blue, size: 36),
                  ],
                ),
              ),
            );
          }).toList(),
    );

    if (!mounted) return;
    setState(() => _open = false);

    if (picked != null) {
      widget.state.didChange(picked);
      widget.onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.state.value;
    final hasError = widget.state.hasError;
    final borderColor =
        hasError
            ? Colors.red.shade700
            : (_open ? _blue : Colors.black.withAlpha(30));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _showMenu,
            child: Container(
              height: 76,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: _open ? 2 : 1.2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value ?? widget.hint,
                      style: TextStyle(
                        fontSize: value == null ? 26 : 34,
                        fontWeight:
                            value == null ? FontWeight.w400 : FontWeight.w600,
                        color: value == null ? Colors.black45 : _navy,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 40,
                      color: _open ? _blue : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 6),
            child: Text(
              widget.state.errorText ?? '',
              style: TextStyle(fontSize: 16, color: Colors.red.shade700),
            ),
          ),
      ],
    );
  }
}
