// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '_json_serializable_test_input.dart';

@ShouldGenerate(r'''
NestedFields _$NestedFieldsFromJson(Map<String, dynamic> json) => NestedFields(
      json['name']['firstName'] as String,
      json['name']['lastName'] as String,
      json['age'] as int,
      json['name']['family']['firstName'] as String,
      json['name']['family']['lastName'] as String,
      (json['location']['rating'] as num).toDouble(),
      locationName: json['location']['name'] as String,
      travelTime:
          Duration(microseconds: json['location']['travelTime'] as int) ??
              const Duration(days: 1),
    );

Map<String, dynamic> _$NestedFieldsToJson(NestedFields instance) =>
    <String, dynamic>{
      'name': {
        'firstName': instance.firstName,
        'lastName': instance.lastName,
        'family': {
          'firstName': instance.familyFirstName,
          'lastName': instance.familyLastName,
        },
      },
      'age': instance.age,
      'location': {
        'name': instance.locationName,
        'rating': instance.rating,
        'travelTime': instance.travelTime.inMicroseconds,
      },
    };
''')
@JsonSerializable()
class NestedFields {
  @JsonKey(path: 'name.firstName')
  final String firstName;

  @JsonKey(path: 'name.lastName')
  final String lastName;

  @JsonKey(path: 'age')
  final int age;

  @JsonKey(path: 'name.family.firstName')
  final String familyFirstName;

  @JsonKey(path: 'name.family.lastName')
  final String familyLastName;

  @JsonKey(path: 'location.name')
  final String locationName;

  @JsonKey(path: 'location.rating')
  final double rating;

  @JsonKey(path: 'location.travelTime')
  final Duration travelTime;

  NestedFields(
    this.firstName,
    this.lastName,
    this.age,
    this.familyFirstName,
    this.familyLastName,
    this.rating, {
    required this.locationName,
    this.travelTime = const Duration(days: 1),
  });
}

@ShouldGenerate(r'''
GeneralTestClass3 _$GeneralTestClass3FromJson(Map<String, dynamic> json) =>
    GeneralTestClass3()
      ..firstName = json['name']['firstName'] as String?
      ..lastName = json['name']['lastName'] as String?
      ..age = json['age'] as int?;

Map<String, dynamic> _$GeneralTestClass3ToJson(GeneralTestClass3 instance) =>
    <String, dynamic>{
      'name': {
        'firstName': instance.firstName,
        'lastName': instance.lastName,
      },
      'age': instance.age,
    };
''')
@JsonSerializable()
class GeneralTestClass3 {
  @JsonKey(path: 'name.firstName')
  String? firstName;

  @JsonKey(path: 'name.lastName')
  String? lastName;

  @JsonKey(path: 'age')
  int? age;
}

@ShouldGenerate(r'''
NestedFieldsWithChecked<T> _$NestedFieldsWithCheckedFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) =>
    $checkedCreate(
      'NestedFieldsWithChecked',
      json,
      ($checkedConvert) {
        final val = NestedFieldsWithChecked<T>(
          $checkedConvert('name.firstName', (v) => v as String),
          $checkedConvert('name.lastName', (v) => v as String),
          $checkedConvert('age', (v) => v as int),
          $checkedConvert('location.rating', (v) => (v as num).toDouble()),
          travelTime: $checkedConvert('location.travelTime',
                  (v) => Duration(microseconds: v as int)) ??
              const Duration(days: 1),
          nestedGenericField: $checkedConvert('location.genericField',
              (v) => _$nullableGenericFromJson(v, fromJsonT)),
          normalGeneric: $checkedConvert(
              'normalGeneric', (v) => _$nullableGenericFromJson(v, fromJsonT)),
        );
        return val;
      },
      fieldKeyMap: const {
        'firstName': 'name.firstName',
        'lastName': 'name.lastName',
        'rating': 'location.rating',
        'travelTime': 'location.travelTime',
        'nestedGenericField': 'location.genericField'
      },
    );

Map<String, dynamic> _$NestedFieldsWithCheckedToJson<T>(
  NestedFieldsWithChecked<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'name': {
        'firstName': instance.firstName,
        'lastName': instance.lastName,
      },
      'age': instance.age,
      'location': {
        'rating': instance.rating,
        'travelTime': instance.travelTime.inMicroseconds,
        'genericField':
            _$nullableGenericToJson(instance.nestedGenericField, toJsonT),
      },
      'normalGeneric': _$nullableGenericToJson(instance.normalGeneric, toJsonT),
    };

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) =>
    input == null ? null : fromJson(input);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) =>
    input == null ? null : toJson(input);
''')
@JsonSerializable(checked: true, genericArgumentFactories: true)
class NestedFieldsWithChecked<T> {
  @JsonKey(path: 'name.firstName')
  final String firstName;

  @JsonKey(path: 'name.lastName')
  final String lastName;

  @JsonKey(path: 'age')
  final int age;

  @JsonKey(path: 'location.rating')
  final double rating;

  @JsonKey(path: 'location.travelTime')
  final Duration travelTime;

  @JsonKey(path: 'location.genericField')
  final T? nestedGenericField;

  @JsonKey(path: 'normalGeneric')
  final T? normalGeneric;

  NestedFieldsWithChecked(
    this.firstName,
    this.lastName,
    this.age,
    this.rating, {
    this.travelTime = const Duration(days: 1),
    this.nestedGenericField,
    this.normalGeneric,
  });
}
