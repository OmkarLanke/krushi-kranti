import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class CustomDropdownField<T> extends StatelessWidget {
  final List<T> items;
  final T? value;
  final void Function(T?)? onChanged;
  final String hint;
  final String? label;
  final IconData? prefixIcon;
  final String Function(T) itemLabelBuilder;
  final bool enabled;

  const CustomDropdownField({
    super.key,
    required this.items,
    this.value,
    required this.onChanged,
    required this.hint,
    this.label,
    this.prefixIcon,
    required this.itemLabelBuilder,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              label!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
                letterSpacing: 0.2,
              ),
            ),
          ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: prefixIcon == null ? 16 : 0),
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey.shade100,
            border: Border.all(
              color: enabled ? Colors.grey.shade300 : Colors.grey.shade300,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              if (prefixIcon != null) ...[
                Container(
                  margin: const EdgeInsets.only(left: 16, right: 10, top: 8, bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: enabled
                        ? AppColors.brandGreen.withOpacity(0.1)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    prefixIcon,
                    size: 18,
                    color: enabled ? AppColors.brandGreen : Colors.grey.shade500,
                  ),
                ),
              ],
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: value,
                    hint: Text(
                      hint,
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                    isExpanded: true,
                    icon: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Icon(
                        Icons.arrow_drop_down_rounded,
                        color: enabled ? AppColors.brandGreen : Colors.grey.shade500,
                      ),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: enabled ? Colors.black87 : Colors.grey.shade600,
                    ),
                    dropdownColor: Colors.white,
                    items: items.map((T item) {
                      return DropdownMenuItem<T>(
                        value: item,
                        child: Text(
                          itemLabelBuilder(item),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                    selectedItemBuilder: (BuildContext context) {
                      return items.map((T item) {
                        return Padding(
                          padding: EdgeInsets.only(left: prefixIcon == null ? 0 : 6),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              itemLabelBuilder(item),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: enabled ? Colors.black87 : Colors.grey.shade600,
                                fontWeight: FontWeight.lerp(
                                    FontWeight.w400, FontWeight.w500, 0.5),
                              ),
                            ),
                          ),
                        );
                      }).toList();
                    },
                    onChanged: enabled ? onChanged : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
