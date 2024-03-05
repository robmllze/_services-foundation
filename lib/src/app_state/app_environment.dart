//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// X|Y|Z & Dev
//
// Copyright Ⓒ Robert Mollentze, xyzand.dev
//
// Licensing details can be found in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

abstract class AppEnvironment<TAppSession extends AppSession> {
  //
  //
  //

  final ServiceEnvironment serviceEnvironment;
  late final Pod<TAppSession> pAppSession;

  //
  //
  //

  AppEnvironment(this.serviceEnvironment) {
    this.pAppSession = Pod<TAppSession>(this.createAppSession());
  }

  //
  //
  //

  var _didAlreadyStartApp = false;
  bool get didAlreadyStartApp => this._didAlreadyStartApp;

  //
  //
  //

  void initApp() async {
    this._defineAuthStateChangesBehaviour();
  }

  //
  //
  //

  TAppSession createAppSession();

  //
  //
  //

  void _defineAuthStateChangesBehaviour() {
    this.serviceEnvironment.authServiceBroker
      ..onLogin = (userInterface) {
        if (this._didAlreadyStartApp) {
          this.onLogin(userInterface);
        } else {
          this.onFreshLogin(userInterface);
        }
        this._didAlreadyStartApp = true;
      }
      ..onLogout = () {
        if (this._didAlreadyStartApp) {
          this.onLogout();
        } else {
          this.onFreshLogout();
        }
        this._didAlreadyStartApp = true;
      };
  }

  //
  //
  //

  void onFreshLogin(UserInterface currentUser);

  void onLogin(UserInterface currentUser);

  void onFreshLogout();

  void onLogout();
}
