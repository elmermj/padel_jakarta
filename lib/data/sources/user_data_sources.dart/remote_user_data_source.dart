import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:paddle_jakarta/data/helpers/web_client_id_helper.dart';
import 'package:paddle_jakarta/data/models/user_model.dart';
import 'package:paddle_jakarta/utils/tools/log.dart';

class RemoteUserDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firebaseFirestore;

  RemoteUserDataSource(this._firebaseAuth, this._firebaseFirestore);

  Future<UserCredential> loginEmail(String email, String password) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      Log.red('Failed to login with email: $e');
      throw Exception('Failed to login: $e');
    }
  }

  Future<UserCredential> loginGoogle() async {
    late GoogleSignIn googleSignIn;
    try {
      if(kIsWeb){
        String clientId = await WebClientIdHelper.getWebClientId();
        googleSignIn = GoogleSignIn(
          clientId: clientId,
        );
      } else {
        googleSignIn = GoogleSignIn();
      }
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        Log.red('Google sign-in aborted by user');
        throw Exception('Google sign-in aborted by user');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      await saveUserData(
        UserModel(
          displayName: userCredential.user?.displayName,
          email: userCredential.user?.email,
          photoUrl: userCredential.user?.photoURL,
          creationTime: Timestamp.fromDate(userCredential.user?.metadata.creationTime ?? DateTime.now()),
          lastLogin: Timestamp.fromDate(DateTime.now()),
        )
      );
      Log.yellow('Google sign-in successful');
      Log.green('${userCredential.user}');

      return userCredential;      
    } catch (e) {
      final err = e.toString()=="popup_closed"? "Google sign-in aborted by user":e;
      throw Exception('$err');
    }
  }

  Future<void> registerEmail(String email, String password, String name) async {
    try {
      final userCred = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      await userCred.user?.updateDisplayName(name);
    } catch (e) {
      Log.red('Failed to register with email: $e');
      throw Exception('Failed to register: $e');
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('$e');
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  Future<void> saveUserData(UserModel user) async {
    Log.yellow('Database URL: ${_firebaseFirestore.databaseURL}');
    try {
      await _firebaseFirestore.collection('users').doc(user.email).get().then((value) {
        if(value.exists){
          _firebaseFirestore.collection('users').doc(user.email).update(user.toJson());
        }else{
          _firebaseFirestore.collection('users').doc(user.email).set(user.toJson());
        }
      });
    } on Exception catch (e) {
      throw Exception('Failed to save user data: $e');
    }
  }
}
