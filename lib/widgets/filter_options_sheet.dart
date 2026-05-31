import 'package:flutter/material.dart';

class FilterResults {
  final String sortBy;
  final RangeValues priceRange;
  final Set<String> dietary;

  FilterResults({required this.sortBy, required this.priceRange, required this.dietary});
}

class FilterOptionsSheet extends StatefulWidget {
  final FilterResults? initialFilters;
  const FilterOptionsSheet({super.key, this.initialFilters});

  @override
  State<FilterOptionsSheet> createState() => _FilterOptionsSheetState();
}

class _FilterOptionsSheetState extends State<FilterOptionsSheet> {
  late String _selectedSortBy;
  late RangeValues _priceRange;
  late Set<String> _dietaryOptions;

  @override
  void initState() {
    super.initState();
    _selectedSortBy = widget.initialFilters?.sortBy ?? 'Popularity';
    _priceRange = widget.initialFilters?.priceRange ?? const RangeValues(500, 5000);
    _dietaryOptions = Set.from(widget.initialFilters?.dietary ?? {'Veg'});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _buildHeader(context, primary),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildSectionTitle(context, 'SORT BY'),
                    const SizedBox(height: 12),
                    _buildSortByOptions(context, primary),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'PRICE RANGE'),
                    const SizedBox(height: 12),
                    _buildPriceRangeSlider(context, primary),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'DIETARY'),
                    const SizedBox(height: 12),
                    _buildDietaryOptions(context, primary),
                  ],
                ),
              ),
              _buildFooter(context, primary),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Color primary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Filter Options', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedSortBy = 'Popularity';
                _priceRange = const RangeValues(500, 5000);
                _dietaryOptions.clear();
              });
            },
            child: Text('Reset', style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade500, fontSize: 12, letterSpacing: 1));
  }

  Widget _buildSortByOptions(BuildContext context, Color primary) {
    final options = ['Popularity', 'Rating', 'Delivery Time'];
    return Wrap(
      spacing: 10,
      children: options.map((opt) => ChoiceChip(
        label: Text(opt),
        selected: _selectedSortBy == opt,
        onSelected: (selected) {
          if (selected) setState(() => _selectedSortBy = opt);
        },
        selectedColor: primary,
        labelStyle: TextStyle(
          color: _selectedSortBy == opt ? Colors.white : Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: Colors.grey.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
        showCheckmark: false,
      )).toList(),
    );
  }

  Widget _buildPriceRangeSlider(BuildContext context, Color primary) {
    return Column(
      children: [
        RangeSlider(
          values: _priceRange,
          min: 0,
          max: 10000,
          divisions: 20,
          activeColor: primary,
          inactiveColor: primary.withValues(alpha: 0.1),
          onChanged: (values) => setState(() => _priceRange = values),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rs. ${_priceRange.start.round()}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Rs. ${_priceRange.end.round()}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDietaryOptions(BuildContext context, Color primary) {
    final options = {'Veg': Icons.eco, 'Non-Veg': Icons.lunch_dining};
    return Wrap(
      spacing: 10,
      children: options.keys.map((opt) => FilterChip(
        label: Text(opt),
        avatar: Icon(options[opt], size: 16, color: _dietaryOptions.contains(opt) ? Colors.white : Colors.grey),
        selected: _dietaryOptions.contains(opt),
        onSelected: (selected) {
          setState(() {
            if (selected) {
              _dietaryOptions.add(opt);
            } else {
              _dietaryOptions.remove(opt);
            }
          });
        },
        selectedColor: primary,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: _dietaryOptions.contains(opt) ? Colors.white : Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: Colors.grey.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
        showCheckmark: false,
      )).toList(),
    );
  }

  Widget _buildFooter(BuildContext context, Color primary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context, FilterResults(
              sortBy: _selectedSortBy,
              priceRange: _priceRange,
              dietary: _dietaryOptions,
            ));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: const Text('Apply Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
