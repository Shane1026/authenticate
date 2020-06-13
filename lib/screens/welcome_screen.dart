import 'package:authenticate/constants.dart';
import 'package:flutter/material.dart';
import 'package:authenticate/user.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';

class WelcomePage extends StatelessWidget {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  logout() {
    googleSignIn.signOut();
    googleSignIn.disconnect();
  }
  final User currentUser;
  WelcomePage({this.currentUser});
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Center(child: Text("Welcome ${currentUser.username}",style: getStyle(Colors.blueAccent, 20, 1),)),
            Center(child: Text("You have logged in with email\n ${currentUser.email}",style: getStyle(Colors.blueAccent, 20, 1),)),
            FlatButton(
              color: Colors.blueAccent,
              onPressed: (){
                logout();
                Navigator.pop(context);
              },
              child: Text("log out"),
            )
          ],
        ),
      ),
    );
  }
}
