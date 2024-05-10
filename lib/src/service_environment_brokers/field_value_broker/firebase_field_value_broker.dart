//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Licencing details are in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:cloud_firestore/cloud_firestore.dart';

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class FirebaseFieldValueBroker extends FieldValueInterface {
  //
  //
  //

  static const instance = FirebaseFieldValueBroker._();

  //
  //
  //

  const FirebaseFieldValueBroker._();

  //
  //
  //

  @override
  dynamic deleteFieldValue() => FieldValue.delete();

  //
  //
  //

  @override
  dynamic incremementFieldValue([int i = 1]) => FieldValue.increment(i);

  //
  //
  //

  @override
  dynamic decrementFieldValue([int i = 1]) => FieldValue.increment(-i);

  //
  //
  //

  @override
  dynamic arrayUnionFieldValue(List elementsToAdd) => FieldValue.arrayUnion(elementsToAdd);

  //
  //
  //

  @override
  dynamic arrayRemoveFieldValue(List elementsToRemove) => FieldValue.arrayRemove(elementsToRemove);
}
