//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Licencing details are in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:firebase_auth/firebase_auth.dart';

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class FirebaseAuthServiceBroker extends AuthServiceInterface {
  //
  //
  //

  final FirebaseAuth _firebaseAuth;

  //
  //
  //

  FirebaseAuthServiceBroker({
    required FirebaseAuth firebaseAuth,
    super.onLogin,
    super.onLogout,
  }) : _firebaseAuth = firebaseAuth {
    this.startHandlingAuthStateChanges();
  }

  //
  //
  //

  StreamSubscription<ModelAuthUser?>? _authStateChangesSubscription;

  //
  //
  //

  Future<void> startHandlingAuthStateChanges() async {
    await stopHandlingAuthStateChanges();
    this._authStateChangesSubscription =
        this._firebaseAuth.authStateChanges().map((e) => e?.toAuthUser()).listen((authUser) async {
      if (authUser != null) {
        await Pod.cast(this.pCurrentUser).set(authUser);
        super.onLogin?.call(authUser);
      } else {
        await Pod.cast(this.pCurrentUser).set(null);
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
    try {
      await this._firebaseAuth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-credential':
          throw const InvalidCredentialException();
        default:
          rethrow;
      }
    }
  }

  //
  //
  //

  @override
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await this._firebaseAuth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw const EmailAlreadyInUseException();
        default:
          rethrow;
      }
    }
  }

  //
  //
  //

  @override
  Future<void> logOut({
    required Future<void> Function() cleanup,
  }) async {
    await cleanup();
    await  Pod.cast(this.pCurrentUser).set(null);
    await this._firebaseAuth.signOut();
  }

  //
  //
  //

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    await this._firebaseAuth.sendPasswordResetEmail(
          email: email,
        );
  }

  //
  //
  //

  @override
  Future<String?> getIdToken() => this._firebaseAuth.currentUser!.getIdToken();

  //
  //
  //

  @override
  Future<void> updateUser({
    String? displayName,
    String? photoURL,
    String? password,
  }) async {
    final currentUser = this._firebaseAuth.currentUser!;
    if (displayName != null) {
      await currentUser.updateDisplayName(displayName);
    }
    if (photoURL != null) {
      await currentUser.updatePhotoURL(photoURL);
    }
    if (password != null) {
      await currentUser.updatePassword(password);
    }
  }

  //
  //
  //

  @override
  Future<void> deleteUser({
    required Future<void> Function() cleanup,
  }) async {
    await cleanup();
    await this._firebaseAuth.currentUser!.delete();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension ToAuthUserOnUserExtension on User {
  ModelAuthUser toAuthUser() {
    return ModelAuthUser(
      id: this.uid,
      email: this.email,
      displayName: this.displayName,
      photoUrl: this.photoURL,
      emailVerified: this.emailVerified,
    );
  }
}
