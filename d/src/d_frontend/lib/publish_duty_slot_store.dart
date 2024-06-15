
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

part 'publish_duty_slot_store.g.dart';

class PublishDutySlotStore = _PublishDutySlotStore with _$PublishDutySlotStore;

abstract class _PublishDutySlotStore with Store {
  @observable
  String selectedSpecialty = '';

  @observable
  String priceFrom = '';

  @observable
  String priceTo = '';

  @observable
  String currency = 'PLN';

  @observable
  DateTime startDate = DateTime.now().add(Duration(days: 1));

  @observable
  DateTime endDate = DateTime.now().add(Duration(days: 2));

  @observable
  TimeOfDay startTime = TimeOfDay(hour: 16, minute: 0);

  @observable
  TimeOfDay endTime = TimeOfDay(hour: 8, minute: 0);

  @action
  void setSelectedSpecialty(String value) {
    selectedSpecialty = value;
  }

  @action
  void setPriceFrom(String value) {
    priceFrom = value;
  }

  @action
  void setPriceTo(String value) {
    priceTo = value;
  }

  @action
  void setCurrency(String value) {
    currency = value;
  }

  @action
  void setStartDate(DateTime value) {
    startDate = value;
  }

  @action
  void setEndDate(DateTime value) {
    endDate = value;
  }

  @action
  void setStartTime(TimeOfDay value) {
    startTime = value;
  }

  @action
  void setEndTime(TimeOfDay value) {
    endTime = value;
  }

  @computed
  bool get isFormValid {
    return validateSpecialty() == null &&
           validatePriceFrom() == null &&
           validatePriceTo() == null;
  }

  String? validateSpecialty() {
    if (selectedSpecialty.isEmpty) {
      return 'Please select a specialty';
    }
    return null;
  }

  String? validatePriceFrom() {
    if (priceFrom.isEmpty) {
      return 'Please enter a price';
    }
    return null;
  }

  String? validatePriceTo() {
    if (priceTo.isEmpty) {
      return 'Please enter a price';
    }
    return null;
  }

  @override
    String toString() {
      return '''PublishDutySlotStore:{
selectedSpecialty: ${selectedSpecialty},
priceFrom: ${priceFrom},
priceTo: ${priceTo},
currency: ${currency},
startDate: ${startDate},
endDate: ${endDate},
startTime: ${startTime},
endTime: ${endTime},
isFormValid: ${isFormValid}
      }''';

  }
}



