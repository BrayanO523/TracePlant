import 'package:flutter/material.dart';
import '../../../../../../app/theme/app_colors.dart';

class SearchableFilterSheet extends StatefulWidget {
  final String title;
  final List<String> options;
  final Function(String?) onSelected;
  final String? selectedValue;

  const SearchableFilterSheet({
    super.key,
    required this.title,
    required this.options,
    required this.onSelected,
    this.selectedValue,
  });

  @override
  State<SearchableFilterSheet> createState() => _SearchableFilterSheetState();
}

class _SearchableFilterSheetState extends State<SearchableFilterSheet> {
  late List<String> _filteredOptions;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredOptions = widget.options;
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _controller.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredOptions = widget.options;
      } else {
        _filteredOptions = widget.options
            .where((opt) => opt.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                Text(
                  'Seleccionar ${widget.title}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Buscar ${widget.title.toLowerCase()}...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          const Divider(height: 1),

          // Options List
          Flexible(
            child: ListView.builder(
              shrinkWrap:
                  true, // Allow content to determine height (up to max constraint)
              // But strictly speaking inside a modal bottom sheet, we usually want expanded
              // However, since it's draggable, let's just make it reasonably sized or expanded
              // Let's rely on parent constraints.
              // We'll return Expanded if parent allows, or Flexible.
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _filteredOptions.length + 1, // +1 for "Todos" option
              itemBuilder: (context, index) {
                if (index == 0) {
                  // "Todos" option
                  final isSelected = widget.selectedValue == null;
                  return ListTile(
                    leading: null,
                    title: Text(
                      'Todas las equivalencias',
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check,
                            color: AppColors.accent,
                            size: 20,
                          )
                        : null,
                    onTap: () {
                      widget.onSelected(null);
                      Navigator.pop(context);
                    },
                  );
                }

                final option = _filteredOptions[index - 1];
                final isSelected = widget.selectedValue == option;

                return ListTile(
                  title: Text(
                    option,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.textPrimary,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check,
                          color: AppColors.accent,
                          size: 20,
                        )
                      : null,
                  onTap: () {
                    widget.onSelected(option);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
