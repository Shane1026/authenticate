import 'dart:ui';

import 'package:authenticate/screens/login.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:authenticate/constants.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:authenticate/user.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'welcome_screen.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  User currentUser;
  final usersRef = Firestore.instance.collection('users');
  TextEditingController _namecon;
  TextEditingController _emailcon;
  TextEditingController _passcon;
  final _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  static final FacebookLogin facebookSignIn = new FacebookLogin();
  GoogleSignInAccount googleUser; ////
  bool _showSpinner = false;
  final _formNameKey = GlobalKey<FormState>();
  final _formEmailKey = GlobalKey<FormState>();
  final _formPasswordKey = GlobalKey<FormState>();

  login() async {
    googleUser = await googleSignIn.signIn();
    handleSignIn(googleSignIn.currentUser);
  }

  String emailValidator(String val) {
    if (val.trim().length < 5) {
      return "Email too short";
    }
    int atRate = 0, fdot = 0, sdot = 0;
    if (val.length > 4) {
      if (val.indexOf('@') > 0) {
        atRate = val.indexOf('@');
        val = val.substring(atRate + 1);
        if (val.indexOf('@') == -1) {
          if (val.indexOf('.') > 0) {
            fdot = val.indexOf('.');
            val = val.substring(fdot + 1);
            if (val.indexOf('.') > 0) {
              sdot = val.indexOf('.');
              val = val.substring(sdot + 1);
              if (val.length > 2) {
                return "Invalid domain name";
              }
            }
          } else {
            return "Invalid domain name";
          }
        } else {
          return "Invalid domain name";
        }
      } else {
        return "No domain name";
      }
    } else {
      return null;
    }
  }

  String passwordValidator(String val) {
    if (val.trim().length < 5) {
      return "Password too short";
    } else if (val.trim().length > 20) {
      return "Password too long";
    } else {
      return null;
    }
  }

  Future<Null> _loginfb() async {
    final FacebookLoginResult result = await facebookSignIn.logIn(['email']);

    switch (result.status) {
      case FacebookLoginStatus.loggedIn:
        final FacebookAccessToken accessToken = result.accessToken;
        print('''
         Logged in!
         
         Token: ${accessToken.token}
         User id: ${accessToken.userId}
         Expires: ${accessToken.expires}
         Permissions: ${accessToken.permissions}
         Declined permissions: ${accessToken.declinedPermissions}
         ''');

        final AuthCredential credential = FacebookAuthProvider.getCredential(
          accessToken: accessToken.token,
        );
        final FirebaseUser usr =
            (await _auth.signInWithCredential(credential)).user;
        break;
      case FacebookLoginStatus.cancelledByUser:
        print('Login cancelled by the user.');
        break;
      case FacebookLoginStatus.error:
        print('Something went wrong with the login process.\n'
            'Here\'s the error Facebook gave us: ${result.errorMessage}');
        break;
    }
  }



  bool isAuth = false;

  handleSignIn(GoogleSignInAccount account) async{
    if (account != null) {
      await createUserInFirestore();
      setState(() {
        isAuth = true;

      });
      Navigator.push(context, MaterialPageRoute(builder: (context)=>WelcomePage(currentUser: currentUser,)));
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  createUserInFirestore() async {
    setState(() {
      _showSpinner=true;
    });
    final GoogleSignInAccount user = googleSignIn.currentUser;
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final FirebaseUser usr =
        (await _auth.signInWithCredential(credential)).user;
    DocumentSnapshot doc = await usersRef.document(user.id).get();

    if (!doc.exists) {

      usersRef.document(user.id).setData({
        "id": user.id,
        "username": user.displayName,
        "email": user.email,
      });

      doc = await usersRef.document(user.id).get();

    }
    setState(() {
      _showSpinner=false;
    });

    currentUser =User.fromDocument(doc);

  }

  @override
  void initState() {
    _namecon = TextEditingController();
    _emailcon = TextEditingController();
    _passcon = TextEditingController();
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignIn(account);
    }, onError: (err) {
      print('Error signing in: $err');
    });
    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      handleSignIn(account);
    }).catchError((err) {
      print('Error signing in: $err');
    });
    super.initState();
  }
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: _showSpinner,
      child: Scaffold(
        key: _scaffoldKey,
        body: Stack(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(image: AssetImage("assests/Background.png"),fit: BoxFit.cover),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: Container(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "Register",
                      style: getStyle(Colors.black, 40,0),
                      textAlign: TextAlign.left,
                    ),
                    Text(
                      "Lets get\nyou on board",
                      style: getStyle(Colors.black, 25,0),
                    ),
                    Container(
                      child: Column(
                        children: <Widget>[
                          Form(
                            key: _formNameKey,
                            autovalidate: false,
                            child: TextFormField(
                              autofocus: false,
                              textCapitalization: TextCapitalization.words,
                              validator: (val) {
                                if (val.trim().length < 3 || val.isEmpty) {
                                  return "Name too short";
                                } else {
                                  return null;
                                }
                              },
                              controller: _namecon,
                              decoration: InputDecoration(
                                labelText: "Full Name",
                                labelStyle: getStyle(Colors.black, 15, 2),
                                hintText: "Enter your full name",
                              ),
                            ),
                          ),
                          Form(
                            key: _formEmailKey,
                            autovalidate: false,
                            child: TextFormField(
                              validator: emailValidator,
                              controller: _emailcon,
                              decoration: InputDecoration(
                                labelText: "Email",
                                labelStyle: getStyle(Colors.black, 15, 2),
                                hintText: "Enter your email",
                              ),
                            ),
                          ),
                          Form(
                            key: _formPasswordKey,
                            autovalidate: false,
                            child: TextFormField(
                              obscureText: true,
                              validator: passwordValidator,
                              controller: _passcon,
                              decoration: InputDecoration(
                                labelText: "Password",
                                labelStyle: getStyle(Colors.black, 15, 2),
                                hintText: "Enter your password",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(5.0),
                      elevation: 2.0,
                      child: MaterialButton(
                        onPressed: () async {
                          setState(() {
                            _showSpinner = true;
                          });
                          final formn = _formNameKey.currentState;
                          final form = _formEmailKey.currentState;
                          final formp = _formPasswordKey.currentState;

                          if (form.validate() && formp.validate() && formn.validate()) {
                            try {
                              final FirebaseUser newUser =
                                  (await _auth.createUserWithEmailAndPassword(
                                          email: _emailcon.text,
                                          password: _passcon.text))
                                      .user;
                              DocumentSnapshot doc = await usersRef.document(newUser.uid).get();

                              if (!doc.exists) {
                                usersRef.document(newUser.uid).setData({
                                  "id": newUser.uid,
                                  "username": _namecon.text,
                                  "email": newUser.email,
                                });

                                doc = await usersRef.document(newUser.uid).get();

                              }

                              currentUser = User.fromDocument(doc);
                              if (newUser != null) {
                                _scaffoldKey.currentState.showSnackBar(SnackBar(
                                  content: Text("Registered Successfully"),
                                ));
                                Navigator.push(context, MaterialPageRoute(builder: (context)=>WelcomePage(currentUser: currentUser,)));
                              }
                              setState(() {
                                FocusScope.of(context)
                                    .requestFocus(new FocusNode());
                                _showSpinner = false;

                              });
                            } on PlatformException catch (e) {
                              _scaffoldKey.currentState.showSnackBar(SnackBar(
                                content: Text("Email already in use"),
                              ));
                              setState(() {
                                _showSpinner = false;
                              });
                            } catch (e) {
                              _scaffoldKey.currentState.showSnackBar(SnackBar(
                                content: Text(e.toString()),
                              ));
                              setState(() {
                                _showSpinner = false;
                              });
                            }
                          } else {
                            setState(() {
                              _showSpinner = false;
                            });
                            _scaffoldKey.currentState.showSnackBar(SnackBar(
                              content: Text("Check credentials"),
                            ));
                          }
                        },
                        minWidth: double.maxFinite,
                        height: 42.0,
                        child: Text(
                          "Register",
                          style: getStyle(Colors.white, 20,2),
                        ),
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: new Container(
                              margin:
                                  const EdgeInsets.only(left: 60.0, right: 15.0),
                              child: Divider(
                                color: Colors.black,
                                height: 20,
                              )),
                        ),
                        Text("Or"),
                        Expanded(
                          child: new Container(
                              margin:
                                  const EdgeInsets.only(left: 15.0, right: 60.0),
                              child: Divider(
                                color: Colors.black,
                                height: 20,
                              )),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.black,
                              style: BorderStyle.solid,
                              width: 0.5,
                            ),
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          child: MaterialButton(
                            onPressed: login,
                            minWidth: 150,
                            height: 42.0,
                            child: Row(
                              children: <Widget>[
                                CircleAvatar(
                                  radius: 17,
                                  backgroundImage:
                                      AssetImage("assests/googleSignIn.png"),
                                ),
                                Text(
                                  "  Google",
                                  style: getStyle(Colors.black, 18,2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.black,
                              style: BorderStyle.solid,
                              width: 0.5,
                            ),
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          child: MaterialButton(
                            onPressed: _loginfb,
                            minWidth: 130,
                            height: 42.0,
                            child: Row(
                              children: <Widget>[
                                CircleAvatar(
                                  radius: 17,
                                  backgroundImage:
                                      AssetImage("assests/facebookSignIn.png"),
                                ),
                                Text(
                                  "  Facebook",
                                  style: getStyle(Colors.black, 18,2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          "Already have an account?",
                          style: getStyle(Colors.black, 20,0),
                        ),
                        RawMaterialButton(
                          child: Text(
                            "Sign In",
                            style: getStyle(Colors.blueAccent, 20,0),
                          ),
                          onPressed: (){
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>LoginPage()));
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
