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

import 'dart:async';

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
  });

  //
  //
  //

  Future<void> _handleSpontaneousAuthStateChanges() async {
    StreamSubscription<User?>? authStateChangesSubscription;
    authStateChangesSubscription =
        this.firebaseAuth.authStateChanges().listen((final firebaseUser) async {
      if (firebaseUser != null) {
        Here().debugLogStart("Log-in detected...");
        final userBroker = _firebaseUserToUserBroker(firebaseUser);
        await super.pCurrentUser.set(userBroker);
        super.onLogin?.call(userBroker);
      } else {
        Here().debugLogStop("log_out detected...");
        authStateChangesSubscription?.cancel();
        await super.pCurrentUser.set(null);
        super.onLogout?.call();
      }
    });
  }

  //
  //
  //

  @override
  Future<bool> checkPersistency() async {
    final currentFirebaseUser = this.firebaseAuth.currentUser;
    final loggedIn = currentFirebaseUser != null;
    if (loggedIn) {
      await this._postLogin();
    }
    return loggedIn;
  }

  //
  //
  //

  @override
  Future<void> logInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await this
        .firebaseAuth
        .signInWithEmailAndPassword(email: email, password: password);
    await this._postLogin();
  }

  //
  //
  //

  @override
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await this
        .firebaseAuth
        .createUserWithEmailAndPassword(email: email, password: password);
    await this._postLogin();
  }

  //
  //
  //

  Future<void> _postLogin() async {
    final userBroker =
        _firebaseUserToUserBroker(this.firebaseAuth.currentUser!);
    await super.pCurrentUser.set(userBroker);
    await this._handleSpontaneousAuthStateChanges();
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
    await this.firebaseAuth.sendPasswordResetEmail(email: email);
  }

  //
  //
  //

  @override
  Future<String?> getIdToken() async {
    final token = await this.firebaseAuth.currentUser!.getIdToken();
    return token;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

UserInterface _firebaseUserToUserBroker(User firebaseAuthUser) {
  return UserInterface(
    userId: firebaseAuthUser.uid,
    email: firebaseAuthUser.email!,
  );
}
