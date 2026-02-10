import 'package:flutter/material.dart';
import '../../../../core/constants/role_constants.dart';

class RoleToggle extends StatelessWidget {
  final UserRole selectedRole;
  final ValueChanged<UserRole> onRoleChanged;

  const RoleToggle({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<UserRole>(
      segments: const [
        ButtonSegment(value: UserRole.productora, label: Text('Productora 🏭')),
        ButtonSegment(value: UserRole.empacadora, label: Text('Empacadora 📦')),
      ],
      selected: {selectedRole},
      onSelectionChanged: (Set<UserRole> newSelection) {
        onRoleChanged(newSelection.first);
      },
      showSelectedIcon: false,
      style: ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
