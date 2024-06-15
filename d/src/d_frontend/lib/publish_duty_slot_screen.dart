import 'package:d_frontend/counter_store.dart';
import 'package:d_frontend/publish_duty_slot_store.dart';
import 'package:d_frontend/specialty_dropdown_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:provider/provider.dart';

class PublishDutySlotScreen extends StatefulWidget {
  @override
  _PublishDutySlotScreenState createState() => _PublishDutySlotScreenState();
}

class _PublishDutySlotScreenState extends State<PublishDutySlotScreen> {

  final publishDutySlotStore = PublishDutySlotStore();

  @override
  void initState() {
    print('_PublishDutySlotScreenState initState');
    super.initState();

    reaction((_) => publishDutySlotStore.startDate, (DateTime date) {
      print('Entering reaction');
      final f = DateFormat('yyyy-MM-dd');
      final dayOfWeek = date.weekday; // 1 (Monday) to 7 (Sunday)

      if (dayOfWeek == DateTime.saturday || dayOfWeek == DateTime.sunday) {
        publishDutySlotStore.setStartTime(TimeOfDay(hour: 8, minute: 0));
      } else {
        publishDutySlotStore.setStartTime(TimeOfDay(hour: 16, minute: 0));
      }

      final nextDay = date.add(Duration(days: 1));
      publishDutySlotStore.setEndDate(nextDay);
      publishDutySlotStore.setEndTime(TimeOfDay(hour: 8, minute: 0));
    });
  }

  @override
  Widget build(BuildContext context) {
    final counterStore = Provider.of<CounterStore>(context);
    return Form(
      child: Observer(
          builder: (_) => Column(
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
                      convertTimeOfDayToDateTime(publishDutySlotStore.startTime),
                      publishDutySlotStore.setStartDate,
                      publishDutySlotStore.setStartTime),
                  DateTimeInputField(
                      'End',
                      publishDutySlotStore.endDate,
                      convertTimeOfDayToDateTime(publishDutySlotStore.endTime),
                      publishDutySlotStore.setEndDate,
                      publishDutySlotStore.setEndTime),
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
              )
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
  final ValueChanged<TimeOfDay> onTimeChanged;

  DateTimeInputField(this.label, this.initialDate, this.initialTime,
      this.onDateChanged, this.onTimeChanged);

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
                    initialDate: DateTime.parse(dateController.text),
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
                  initialDate: DateTime.parse(dateController.text),
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
                    initialTime: parseTimeOfDay(timeController.text),
                  );
                  if (time != null) {
                    timeController.text = formatTimeOfDay(time);
                    widget.onTimeChanged(time);
                  }
                },
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: parseTimeOfDay(timeController.text),
                );
                if (time != null) {
                  timeController.text = formatTimeOfDay(time);
                  widget.onTimeChanged(time);
                }
              },
              child: Text('Select ${widget.label} Time'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void didUpdateWidget(DateTimeInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != oldWidget.initialDate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        dateController.text =
            DateFormat('yyyy-MM-dd').format(widget.initialDate);
      });
    }
    if(widget.initialTime != oldWidget.initialTime) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('Changing timeController.text from ${timeController.text} to ${formatTimeOfDay(TimeOfDay.fromDateTime(widget.initialTime))}');
        print('Which is actually ${widget.initialTime}');
        timeController.text = formatTimeOfDay(TimeOfDay.fromDateTime(widget.initialTime));
      });
    }
  }

  String formatTimeOfDay(TimeOfDay timeOfDay) {
    final now = DateTime.now();
    final dt = DateTime(
        now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
    return DateFormat('HH:mm').format(dt);
  }
}

TimeOfDay parseTimeOfDay(String time) {
  final format = DateFormat('HH:mm'); // Use 24-hour format
  final dt = format.parse(time);

  final tod = TimeOfDay.fromDateTime(dt);
  return tod;
}

DateTime convertTimeOfDayToDateTime(TimeOfDay time) {
  DateTime now = DateTime.now();
  return DateTime(now.year, now.month, now.day, time.hour, time.minute);
}