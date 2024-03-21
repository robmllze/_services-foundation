//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Copyright Ⓒ Robert Mollentze, xyzand.dev
//
// Licensing details can be found in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

abstract class AppSession {
  //
  //
  //

  final ServiceEnvironment serviceEnvironment;

  //
  //
  //

  AppSession(this.serviceEnvironment);

  //
  //
  //

  //bool _didStart = false;

  //
  //
  //

  @mustCallSuper
  FutureOr<void> startSession(UserInterface currentUser) async {
    // assert(
    //   !this._didStart,
    //   "The session has already been started.",
    // );
    // assert(
    //   !this.loggedIn,
    //   "The user is already logged in.",
    // );
    //this._didStart = true;
  }

  //
  //
  //

  @mustCallSuper
  FutureOr<void> stopSession() async {
    // assert(
    //   this._didStart,
    //   "The session has already been stopped.",
    // );
    // assert(
    //   this.loggedOut,
    //   "The user is already logged out.",
    // );
    //this._didStart = false;
  }

  //
  //
  //

  bool get loggedIn => this.serviceEnvironment.authServiceBroker.loggedIn;
  bool get loggedOut => this.serviceEnvironment.authServiceBroker.loggedOut;
}
