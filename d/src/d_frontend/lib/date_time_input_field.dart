
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    return Row(
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
    SizedBox(width: 10), // You can adjust this value as needed
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
  ],
);  }

  @override
  void didUpdateWidget(DateTimeInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != oldWidget.initialDate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        dateController.text =
            DateFormat('yyyy-MM-dd').format(widget.initialDate);
      });
    }
    if (widget.initialTime != oldWidget.initialTime) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print(
            'Changing timeController.text from ${timeController.text} to ${formatTimeOfDay(TimeOfDay.fromDateTime(widget.initialTime))}');
        print('Which is actually ${widget.initialTime}');
        timeController.text =
            formatTimeOfDay(TimeOfDay.fromDateTime(widget.initialTime));
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
