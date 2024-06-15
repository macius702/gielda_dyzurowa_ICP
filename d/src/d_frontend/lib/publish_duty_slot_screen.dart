import 'package:d_frontend/publish_duty_slot_store.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class PublishDutySlotScreen extends StatefulWidget {
  @override
  _PublishDutySlotScreenState createState() => _PublishDutySlotScreenState();
}

class _PublishDutySlotScreenState extends State<PublishDutySlotScreen> {

  void _updateTimes() {
  }

  // void _updateTimes() {
  //   final dayOfWeek = _startDate.weekday;
  //   if (dayOfWeek == DateTime.saturday || dayOfWeek == DateTime.sunday) {
  //     _startTime = TimeOfDay(hour: 8, minute: 0);
  //   } else {
  //     _startTime = TimeOfDay(hour: 16, minute: 0);
  //   }
  //   _endTime = TimeOfDay(hour: 8, minute: 0);
  // }
  final publishDutySlotStore = PublishDutySlotStore();

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        children: <Widget>[
          // Replace this with your SpecialtyDropdownMenu
          DropdownButtonFormField(
            value: publishDutySlotStore.selectedSpecialty,
            items: ['Specialty 1', 'Specialty 2', 'Specialty 3', '']
                .map((label) => DropdownMenuItem(
                      value: label,
                      child: Text(label.toString()),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                if (['Specialty 1', 'Specialty 2', 'Specialty 3'].contains(value)) {
                  publishDutySlotStore.setSelectedSpecialty(value ?? '');
              }});
            },
          ),
          TextFormField(
            initialValue: publishDutySlotStore.priceFrom,
            decoration: const InputDecoration(
              labelText: 'Price From',
            ),
            onChanged: (value) {
              publishDutySlotStore.setPriceFrom(value);
            },
          ),
          TextFormField(
            initialValue: publishDutySlotStore.priceTo,
            decoration: const InputDecoration(
              labelText: 'Price To',
            ),
            onChanged: (value) {
              publishDutySlotStore.setPriceTo(value);
            },
          ),
          // Replace this with your ExposedDropdownMenuBox for currency
          DropdownButtonFormField(
            value: publishDutySlotStore.currency, 
            items: ['USD', 'EUR', 'PLN']
                .map((label) => DropdownMenuItem(
                      value: label,
                      child: Text(label.toString()),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                publishDutySlotStore.setCurrency(value ?? 'PLN');
              });
            },
          ),
          // Replace these with your DateTimeInputField
          TextButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: publishDutySlotStore.startDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(Duration(days: 365)),
              );
              if (date != null) {
                setState(() {
                  publishDutySlotStore.setStartDate(date);
                  _updateTimes();
                });
              }
            },
            child: Text(DateFormat('yyyy-MM-dd').format(publishDutySlotStore.startDate)),
          ),
          TextButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: publishDutySlotStore.endDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(Duration(days: 365)),
              );
              if (date != null) {
                setState(() {
                  publishDutySlotStore.setEndDate(date);
                });
              }
            },
            child: Text(DateFormat('yyyy-MM-dd').format(publishDutySlotStore.endDate)),
          ),
          ElevatedButton(
            onPressed: publishDutySlotStore.isFormValid ? _submitForm : null,
            child: const Text('Publish Duty Slot'),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    // Implement your form submission logic here
  }
}