import 'package:d_frontend/counter_store.dart';
import 'package:d_frontend/publish_duty_slot_store.dart';
import 'package:d_frontend/specialty_dropdown_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PublishDutySlotScreen extends StatefulWidget {
  @override
  _PublishDutySlotScreenState createState() => _PublishDutySlotScreenState();
}

class _PublishDutySlotScreenState extends State<PublishDutySlotScreen> {
  void _updateTimes() {}

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
    final counterStore = Provider.of<CounterStore>(context);
    return Form(
      child: Column(
        children: <Widget>[
          // Replace this with your SpecialtyDropdownMenu
          SpecialtyDropdownMenu(
              specialties: counterStore.specialties,
              onSelected: publishDutySlotStore.setSelectedSpecialty),
          TextFormField(
            initialValue: publishDutySlotStore.priceFrom,
            decoration: const InputDecoration(
              labelText: 'Price From',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly
            ],
            onChanged: (value) {
              publishDutySlotStore.setPriceFrom(value);
            },
          ),
          TextFormField(
            initialValue: publishDutySlotStore.priceTo,
            decoration: const InputDecoration(
              labelText: 'Price To',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly
            ],
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
          DateTimeInputField(
              'Start',
              publishDutySlotStore.startDate,
              publishDutySlotStore.startDate,
              publishDutySlotStore.setStartDate),
          DateTimeInputField('End',
              publishDutySlotStore.endDate,
              publishDutySlotStore.endDate,
              publishDutySlotStore.setEndDate),
          ElevatedButton(
            onPressed: () {
              if (publishDutySlotStore.isFormValid) {
                _submitForm();
              } else {
                print(publishDutySlotStore);
              }
            },
            child: const Text('Publish Duty Slot'),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    // Implement your form submission logic here
    print(publishDutySlotStore);
  }
}

class DateTimeInputField extends StatefulWidget {
  final String label;
  final DateTime initialDate;
  final DateTime initialTime;
  final ValueChanged<DateTime> onDateChanged;

  DateTimeInputField(
      this.label, this.initialDate, this.initialTime, this.onDateChanged);

  @override
  _DateTimeInputFieldState createState() => _DateTimeInputFieldState();
}

class _DateTimeInputFieldState extends State<DateTimeInputField> {
  late TextEditingController dateController;
  late TextEditingController timeController;

  @override
  void initState() {
    super.initState();
    dateController = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(widget.initialDate));
    timeController = TextEditingController(
        text: formatTimeOfDay(TimeOfDay.fromDateTime(widget.initialTime)));
  }

  @override
  void dispose() {
    dateController.dispose();
    timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: TextFormField(
                controller: dateController,
                decoration: InputDecoration(labelText: '${widget.label} Date'),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: widget.initialDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  if (date != null) {
                    dateController.text = DateFormat('yyyy-MM-dd').format(date);
                    widget.onDateChanged(date);
                  }
                },
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: widget.initialDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                );
                if (date != null) {
                  dateController.text = DateFormat('yyyy-MM-dd').format(date);
                  widget.onDateChanged(date);
                }
              },
              child: Text('Select ${widget.label} Date'),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: TextFormField(
                controller: timeController,
                decoration: InputDecoration(labelText: '${widget.label} Time'),
                readOnly: true,
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(widget.initialTime),
                  );
                  if (time != null) {
                    timeController.text = formatTimeOfDay(time);
                  }
                },
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(widget.initialTime),
                );
                if (time != null) {
                  timeController.text = formatTimeOfDay(time);
                }
              },
              child: Text('Select ${widget.label} Time'),
            ),
          ],
        ),
      ],
    );
  }

  String formatTimeOfDay(TimeOfDay timeOfDay) {
    final now = DateTime.now();
    final dt = DateTime(
        now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
    return DateFormat('HH:mm').format(dt);
  }
}
