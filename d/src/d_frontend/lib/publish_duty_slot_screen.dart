import 'package:d_frontend/counter_store.dart';
import 'package:d_frontend/date_time_input_field.dart';
import 'package:d_frontend/publish_duty_slot_store.dart';
import 'package:d_frontend/specialty_dropdown_menu.dart';
import 'package:d_frontend/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:provider/provider.dart';

class PublishDutySlotScreen extends StatefulWidget {
  final VoidCallback onTap;

  // ignore: use_super_parameters
  PublishDutySlotScreen({
    Key? key,
    required this.onTap,
  }) : super(key: key);

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
    return SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Form(
          child: Observer(
              builder: (_) => Column(
                    children: <Widget>[
                      // Replace this with your SpecialtyDropdownMenu
                      SpecialtyDropdownMenu(
                          key: const Key('specialtyDropdownInPublishDutySlot'),
                          specialties: counterStore.specialties,
                          onSelected:
                              publishDutySlotStore.setSelectedSpecialty),
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
                          convertTimeOfDayToDateTime(
                              publishDutySlotStore.startTime),
                          publishDutySlotStore.setStartDate,
                          publishDutySlotStore.setStartTime),
                      DateTimeInputField(
                          'End',
                          publishDutySlotStore.endDate,
                          convertTimeOfDayToDateTime(
                              publishDutySlotStore.endTime),
                          publishDutySlotStore.setEndDate,
                          publishDutySlotStore.setEndTime),
                      ElevatedButton(
                        key: const Key('publishDutySlotButton'),
                        onPressed: () => onPressed(context, counterStore,
                            publishDutySlotStore, widget.onTap),
                        child: const Text('Publish Duty Slot'),
                        style: ButtonStyle(
                          shape:
                              WidgetStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      side: BorderSide(color: Colors.red))),
                        ),
                      )
                    ],
                  )),
        ));
  }
}

void onPressed(BuildContext context, CounterStore counterStore,
    PublishDutySlotStore publishDutySlotStore, VoidCallback onTap) {
  if (publishDutySlotStore.selectedSpecialty == null ||
      publishDutySlotStore.selectedSpecialty!.isEmpty) {
    showSnackBar(context, "Specialty is mandatory");
  } else if (publishDutySlotStore.priceFrom.isEmpty ||
      publishDutySlotStore.priceTo.isEmpty) {
    showSnackBar(context, "Price range is mandatory");
  } else if (publishDutySlotStore.currency == null) {
    showSnackBar(context, "Currency has to be set");
  } else {
    performPublishDutySlot(context, counterStore, publishDutySlotStore, onTap);
  }
}

Future<void> performPublishDutySlot(
  BuildContext context,
  CounterStore counterStore,
  PublishDutySlotStore publishDutySlotStore,
  VoidCallback onTap,
) async {
  Status status = await counterStore.publishDutySlot(
    specialty: publishDutySlotStore.selectedSpecialty!,
    priceFrom: int.parse(publishDutySlotStore.priceFrom),
    priceTo: int.parse(publishDutySlotStore.priceTo),
    currency: publishDutySlotStore.currency,
    startDate: publishDutySlotStore.startDate,
    startTime: publishDutySlotStore.startTime,
    endDate: publishDutySlotStore.endDate,
    endTime: publishDutySlotStore.endTime,
  );
  if (status.is_success()) {
    onTap();
  }
}

void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
