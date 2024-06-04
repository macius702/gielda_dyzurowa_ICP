import 'package:flutter/material.dart';

class SpecialtyDropdownMenu extends StatefulWidget {
  final List<String> specialties;

  SpecialtyDropdownMenu({required this.specialties});

  @override
  _SpecialtyDropdownMenuState createState() => _SpecialtyDropdownMenuState();
}

class _SpecialtyDropdownMenuState extends State<SpecialtyDropdownMenu> {
  String _selectedSpecialty = '';

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _selectedSpecialty.isEmpty ? null : _selectedSpecialty,
      hint: const Text('Enter specialty'),
      items: widget.specialties.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedSpecialty = newValue!;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected Specialty: $_selectedSpecialty')),
        );
      },
    );
  }
}