import 'package:flutter/material.dart';

class SpecialtyDropdownMenu extends StatefulWidget {
  final List<String> specialties;
  final ValueChanged<String> onSelected;

  SpecialtyDropdownMenu({required this.specialties, required this.onSelected});

  @override
  _SpecialtyDropdownMenuState createState() => _SpecialtyDropdownMenuState();
}

class _SpecialtyDropdownMenuState extends State<SpecialtyDropdownMenu> {
  String? _selectedSpecialty;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      isExpanded: true,
      value: _selectedSpecialty,
      hint: const Text('Enter specialty'),
      items: widget.specialties.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedSpecialty = newValue;
        });
        widget.onSelected(newValue ?? '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Selected Specialty: $newValue ?? ''")),
        );
      },
    );
  }
}