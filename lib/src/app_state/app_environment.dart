//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Licencing details are in the LICENSE file in the root directory.
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
    this._defineAuthStateChangesBehaviour();
  }

  //
  //
  //

  var _didAlreadyStartApp = false;
  bool get didAlreadyStartApp => this._didAlreadyStartApp;

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

  void onFreshLogin(ModelAuthUser currentAuthUser);

  void onLogin(ModelAuthUser currentAuthUser);

  void onFreshLogout();

  void onLogout();
}
