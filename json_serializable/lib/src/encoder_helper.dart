// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:source_helper/source_helper.dart';

import 'constants.dart';
import 'helper_core.dart';
import 'type_helpers/generic_factory_helper.dart';
import 'type_helpers/json_converter_helper.dart';
import 'unsupported_type_error.dart';

abstract class EncodeHelper implements HelperCore {
  String _fieldAccess(FieldElement field) => '$_toJsonParamName.${field.name}';

  Iterable<String> createToJson(Set<FieldElement> accessibleFields) sync* {
    assert(config.createToJson);

    final buffer = StringBuffer();

    final functionName = '${prefix}ToJson${genericClassArgumentsImpl(true)}';
    buffer.write('Map<String, dynamic> '
        '$functionName($targetClassReference $_toJsonParamName');

    if (config.genericArgumentFactories) {
      for (var arg in element.typeParameters) {
        final helperName = toJsonForType(
          arg.instantiate(nullabilitySuffix: NullabilitySuffix.none),
        );
        buffer.write(',Object? Function(${arg.name} value) $helperName');
      }
      if (element.typeParameters.isNotEmpty) {
        buffer.write(',');
      }
    }
    buffer.write(') ');

    final writeNaive = accessibleFields.every(_writeJsonValueNaive);

    if (writeNaive) {
      // write simple `toJson` method that includes all keys...
      _writeToJsonSimple(buffer, accessibleFields);
    } else {
      // At least one field should be excluded if null
      _writeToJsonWithNullChecks(buffer, accessibleFields);
    }

    yield buffer.toString();
  }

  void _writeToJsonSimple(StringBuffer buffer, Iterable<FieldElement> fields) {
    final nestedMapFields = <String, dynamic>{};
    for (final field in fields) {
      final access = _fieldAccess(field);
      final isFieldPath = isUsingFieldPath(field);
      final jsonKey = safeNameAccess(field);
      final nestedKeys = isFieldPath ? getNestedJsonKeyNames(jsonKey) : [jsonKey];
      final value = _serializeField(field, access);

      // if we have nested key create map for each of key
      if (isFieldPath) {
        makeNestedMap(nestedMapFields, nestedKeys, value);
      } else {
        nestedMapFields[jsonKey] = value;
      }
    }

    var strResult = mapToString(nestedMapFields);
    strResult = strResult.substring(0, strResult.length - 1);
    buffer..writeln('=> <String, dynamic>')..writeln(strResult)..writeln(';');
  }

  final List<Object> _toStringVisiting = [];

  /// Check if we are currently visiting `o` in a toString call.
  bool _isToStringVisiting(Object o) {
    for (var i = 0; i < _toStringVisiting.length; i++) {
      if (identical(o, _toStringVisiting[i])) return true;
    }
    return false;
  }

  String mapToString(Map<String, dynamic> m) {
    // Modified version of mapToString from BaseIterable
    if (_isToStringVisiting(m)) {
      return '{...}';
    }

    final result = StringBuffer();
    try {
      _toStringVisiting.add(m);
      result.write('{');
      m.forEach((String k, dynamic v) {
        result..write(k)..write(': ');
        if (v is Map<String,dynamic>) {
          result.write(mapToString(v));
        } else {
          result..write(v)..write(', ');
        }
      });
      result.write('},');
    } finally {
      assert(identical(_toStringVisiting.last, m));
      _toStringVisiting.removeLast();
    }
    return result.toString();
  }

  static const _toJsonParamName = 'instance';

  void _writeToJsonWithNullChecks(
    StringBuffer buffer,
    Iterable<FieldElement> fields,
  ) {
    buffer
      ..writeln('{')
      ..writeln('    final $generatedLocalVarName = <String, dynamic>{');

    // Note that the map literal is left open above. As long as target fields
    // don't need to be intercepted by the `only if null` logic, write them
    // to the map literal directly. In theory, should allow more efficient
    // serialization.
    var directWrite = true;

    for (final field in fields) {
      var safeFieldAccess = _fieldAccess(field);
      final safeJsonKeyString = safeNameAccess(field);

      // If `fieldName` collides with one of the local helpers, prefix
      // access with `this.`.
      if (safeFieldAccess == generatedLocalVarName ||
          safeFieldAccess == toJsonMapHelperName) {
        safeFieldAccess = 'this.$safeFieldAccess';
      }

      final expression = _serializeField(field, safeFieldAccess);
      if (_writeJsonValueNaive(field)) {
        if (directWrite) {
          buffer.writeln('      $safeJsonKeyString: $expression,');
        } else {
          buffer.writeln(
              '    $generatedLocalVarName[$safeJsonKeyString] = $expression;');
        }
      } else {
        if (directWrite) {
          // close the still-open map literal
          buffer
            ..writeln('    };')
            ..writeln()

            // write the helper to be used by all following null-excluding
            // fields
            ..writeln('''
    void $toJsonMapHelperName(String key, dynamic value) {
      if (value != null) {
        $generatedLocalVarName[key] = value;
      }
    }
''');
          directWrite = false;
        }
        buffer.writeln(
            '    $toJsonMapHelperName($safeJsonKeyString, $expression);');
      }
    }

    buffer..writeln('    return $generatedLocalVarName;')..writeln('  }');
  }

  String _serializeField(FieldElement field, String accessExpression) {
    try {
      return getHelperContext(field)
          .serialize(field.type, accessExpression)
          .toString();
    } on UnsupportedTypeError catch (e) // ignore: avoid_catching_errors
    {
      throw createInvalidGenerationError('toJson', field, e);
    }
  }

  /// Returns `true` if the field can be written to JSON 'naively' – meaning
  /// we can avoid checking for `null`.
  bool _writeJsonValueNaive(FieldElement field) {
    final jsonKey = jsonKeyFor(field);

    return jsonKey.includeIfNull ||
        (!field.type.isNullableType && !_fieldHasCustomEncoder(field));
  }

  /// Returns `true` if [field] has a user-defined encoder.
  ///
  /// This can be either a `toJson` function in [JsonKey] or a [JsonConverter]
  /// annotation.
  bool _fieldHasCustomEncoder(FieldElement field) {
    final helperContext = getHelperContext(field);
    return helperContext.serializeConvertData != null ||
        const JsonConverterHelper()
                .serialize(field.type, 'test', helperContext) !=
            null;
  }
}

List<String> getNestedJsonKeyNames(String jsonKey) {
  return jsonKey.replaceAll("'", '').split('.').map((e) => "'$e'").toList();
}

void makeNestedMap(
    Map<String, dynamic> nested, List<String> keys, String value) {
  final last = keys.last;
  keys.fold<Map<String, dynamic>>(nested, (obj, key) {
    if (last == key) {
      // ignore: avoid_dynamic_calls
      obj[key] = value;
      return obj;
    } else {
      // ignore: avoid_dynamic_calls
      obj[key] ??= <String, dynamic>{};
      return obj[key] as Map<String, dynamic>;
    }
  });
}