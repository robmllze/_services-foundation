//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// 🇽🇾🇿 & Dev
//
// Licencing details are in the LICENSE file in the root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:_data/_common.dart';

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class HiveAuthServiceBroker extends AuthServiceInterface {
  //
  //
  //

  final HiveServiceBroker hiveServiceBroker;

  final String sessionKey;

  late final sessionRef = DataRef(
    collection: ['sessions'],
    id: this.sessionKey,
  );

  late final authUsersRef = sessionRef +
      DataRef(
        collection: ['auth_users'],
      );

  //
  //
  //

  HiveAuthServiceBroker({
    required this.hiveServiceBroker,
    required this.sessionKey,
  });

  //
  //
  //

  //
  //
  //

  StreamSubscription<ModelAuthUser?>? _authStateChangesSubscription;

  //
  //
  //

  Future<void> startHandlingAuthStateChanges() async {
    await stopHandlingAuthStateChanges();

    this
        .hiveServiceBroker
        .streamModel(this.sessionRef, ModelAuthUser.fromJsonOrNull)
        .listen((authUser) async {
      if (authUser != null) {
        await super.pCurrentUser.set(authUser);
        super.onLogin?.call(authUser);
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
  Future<void> deleteUser() async {
    final currentUser = await this._getCurrentUser();
    final ref = currentUser?.ref;
    if (ref == null) {
      throw Exception('Login required for account deletion.');
    }
    await this.hiveServiceBroker.deleteModel(ref);
    await this.logOut();
  }

  //
  //
  //

  @override
  Future<String?> getIdToken() async {
    final currentUser = await this._getCurrentUser();
    return currentUser?.idToken;
  }

  //
  //
  //

  @override
  Future<void> logInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final userRef = this._getUserRef(email);
    final authUser = await this._getAuthUser(userRef);
    if (authUser == null) {
      throw Exception('User not found.');
    }
    if (authUser.password != password) {
      throw Exception('Invalid password.');
    }
    await this.hiveServiceBroker.setModel(authUser);
    await this.pCurrentUser.set(authUser);
  }

  //
  //
  //

  @override
  Future<void> logOut() async {
    await this.hiveServiceBroker.deleteModel(
          this.sessionRef,
        );
    await this.pCurrentUser.set(null);
  }

  //
  //
  //

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    throw UnimplementedError();
  }

  //
  //
  //

  @override
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final $email = email.trim().toLowerCase();
    if ($email.isEmpty || password.isEmpty) {
      throw Exception('Email and password must not be empty.');
    }
    final userRef = this._getUserRef($email);
    final authUser = ModelAuthUser(
      ref: userRef,
      id: email,
      email: $email,
      password: password,
    );
    await this.hiveServiceBroker.setModel(authUser);
    await this.pCurrentUser.set(authUser);
  }

  //
  //
  //

  @override
  Future<void> updateUser({
    String? displayName,
    String? photoURL,
    String? password,
  }) async {
    final currentUser = await this._getCurrentUser();
    if (currentUser == null) {
      throw Exception('User not found.');
    }
    final updatedUser = currentUser.copyWith<ModelAuthUser>(
      ModelAuthUser(
        displayName: displayName,
        photoUrl: photoURL,
        password: password,
      ),
    );

    await this.hiveServiceBroker.setModel(updatedUser);
    await this.pCurrentUser.set(updatedUser);
  }

  //
  //
  //

  DataRef _getUserRef(String email) {
    return this.authUsersRef.copy()..id = email;
  }

  //
  //
  //

  Future<ModelAuthUser?> _getCurrentUser() async {
    final model = await this.hiveServiceBroker.readModel(
          this.sessionRef,
          ModelAuthUser.fromJsonOrNull,
        );
    return model;
  }

  //
  //
  //

  Future<ModelAuthUser?> _getAuthUser(DataRef authUserRef) async {
    final model = await this.hiveServiceBroker.readModel(
          authUserRef,
          ModelAuthUser.fromJsonOrNull,
        );
    return model;
  }
}
