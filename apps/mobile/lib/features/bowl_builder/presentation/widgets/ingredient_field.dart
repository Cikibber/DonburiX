import 'package:flutter/material.dart';

import '../../domain/bowl_models.dart';
import '../../domain/bowl_validation.dart';

class IngredientField extends StatelessWidget {
  const IngredientField({
    super.key,
    required this.category,
    required this.ingredients,
    required this.selectedId,
    required this.quantity,
    required this.enabled,
    required this.onSelected,
  });

  final IngredientCategory category;
  final List<Ingredient> ingredients;
  final String? selectedId;
  final int quantity;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = ingredients
        .where((item) => item.category == category)
        .toList();
    final selected = options.where((item) => item.id == selectedId).firstOrNull;
    return FormField<String>(
      key: Key('field-${category.name}'),
      initialValue: selectedId,
      validator: (_) => BowlValidation.ingredient(selected, category, quantity),
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.label,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(category.hint, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((item) {
              final unavailable = item.availableStock == 0;
              return ChoiceChip(
                key: Key('ingredient-${item.id}'),
                selected: selectedId == item.id,
                label: Text(
                  '${item.name} · ${unavailable ? 'Habis' : formatRupiah(item.price)}',
                ),
                onSelected: enabled && !unavailable
                    ? (_) {
                        field.didChange(item.id);
                        onSelected(item.id);
                      }
                    : null,
              );
            }).toList(),
          ),
          if (field.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                field.errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}
