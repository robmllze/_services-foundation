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

import 'package:firebase_auth/firebase_auth.dart';

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class FirebaseAuthServiceBroker extends AuthServiceInterface {
  //
  //
  //

  @visibleForTesting
  final FirebaseAuth firebaseAuth;

  //
  //
  //

  FirebaseAuthServiceBroker({
    required this.firebaseAuth,
    super.onLogin,
    super.onLogout,
  }) {
    this.startHandlingAuthStateChanges();
  }

  //
  //
  //

  StreamSubscription<User?>? _authStateChangesSubscription;

  //
  //
  //

  Future<void> startHandlingAuthStateChanges() async {
    await stopHandlingAuthStateChanges();
    this._authStateChangesSubscription = this.firebaseAuth.authStateChanges().listen((user) async {
      if (user != null) {
        final userInterface = user.toUserInterface();
        await super.pCurrentUser.set(userInterface);
        super.onLogin?.call(userInterface);
      } else {
        await super.pCurrentUser.set(null);
        super.onLogout?.call();
      }
    });
  }

  //
  //
  //

  Future<void> stopHandlingAuthStateChanges() async {
    await this._authStateChangesSubscription?.cancel();
  }

  //
  //
  //

  @override
  Future<void> logInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await this.firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
  }

  //
  //
  //

  @override
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await this.firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
  }

  //
  //
  //

  @override
  Future<void> logOut() async {
    await super.pCurrentUser.set(null);
    await this.firebaseAuth.signOut();
  }

  //
  //
  //

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    await this.firebaseAuth.sendPasswordResetEmail(
          email: email,
        );
  }

  //
  //
  //

  @override
  Future<String?> getIdToken() => this.firebaseAuth.currentUser!.getIdToken();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension UserToUserInterfaceExtension on User {
  UserInterface toUserInterface() {
    return UserInterface(
      userId: this.uid,
      email: this.email!,
    );
  }
}
