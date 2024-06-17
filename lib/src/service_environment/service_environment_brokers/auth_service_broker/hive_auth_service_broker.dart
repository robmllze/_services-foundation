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

@visibleForTesting
final class HiveAuthServiceBroker extends AuthServiceInterface {
  //
  //
  //

  // ignore: invalid_use_of_visible_for_testing_member
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
        await super.pCurrentUser.podOrNull!.set(authUser);
        super.onLogin?.call(authUser);
      } else {
        await super.pCurrentUser.podOrNull!.set(null);
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
  Future<void> deleteUser({
    required Future<void> Function() cleanup,
  }) async {
    await cleanup();
    final currentUser = await this._getCurrentUser();
    final ref = currentUser?.ref;
    if (ref == null) {
      throw Exception('Login required for account deletion.');
    }
    await this.hiveServiceBroker.deleteModel(ref);
    await this.logOut(cleanup: () async {});
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
    final ref = this._getAuthUserRef(email);
    final authUser = await this._getAuthUser(ref);
    if (authUser == null) {
      throw Exception('User not found.');
    }
    if (authUser.password != password) {
      throw Exception('Invalid password.');
    }
    await this.hiveServiceBroker.updateModel(authUser);
    await this.pCurrentUser.podOrNull!.set(authUser);
  }

  //
  //
  //

  @override
  Future<void> logOut({
    required Future<void> Function() cleanup,
  }) async {
    await cleanup();
    await this.hiveServiceBroker.deleteModel(
          this.sessionRef,
        );
    await this.pCurrentUser.podOrNull!.set(null);
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
    final ref = this._getAuthUserRef($email);

    final authUser = ModelAuthUser(
      ref: ref,
      id: IdUtils.newUuidV4(),
      email: $email,
      password: password,
    );
    await this.hiveServiceBroker.createModel(authUser);
    await this.pCurrentUser.podOrNull!.set(authUser);
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

    await this.hiveServiceBroker.updateModel(updatedUser);
    await this.pCurrentUser.podOrNull!.set(updatedUser);
  }

  //
  //
  //

  DataRef _getAuthUserRef(String email) {
    return DataRef(
      collection: ['session', this.sessionKey, 'auth_users'],
      id: email,
    );
    // return this.authUsersRef.copy()..id = email;
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

  Future<ModelAuthUser?> _getAuthUser(DataRef ref) async {
    final model = await this.hiveServiceBroker.readModel(
          ref,
          ModelAuthUser.fromJsonOrNull,
        );
    return model;
  }
}
