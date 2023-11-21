import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

// import 'package:connectivity_plus/connectivity_plus.dart';

void main() async {
  final String infoKey = 'UserInfo';
  SharedPreferences prefs;
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();
  OneSignal.shared.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);
  OneSignal.shared.setAppId("3883d614-02e2-4314-a619-d1dc907fa5ea");
  OneSignal.shared.promptUserForPushNotificationPermission().then((accepted) {
    print("Accepted permission: $accepted");
  });

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: prefs.getBool(infoKey) == true ? WebViewPage() : MainPage(),
  ));
}

class MainPage extends StatelessWidget {
  TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2F2E3E),
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
        bottomOpacity: 0.0,
        elevation: 0.0, title: Center(child: Text("")),
//        backgroundColor: Color(0xFF2F2E3E),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 25.0),
                  child: Container(
                      width: 180,
                      child:
                          Center(child: Image.asset("assets/agrowiologo.png"))),
                ),
                Center(
                  child: Container(
                    height: 48,
                    width: 300,
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText:
                            "Örnek: 0549 543 0761", // Hint metni bu formatta
                        hintStyle: TextStyle(color: Colors.white38, height: 3),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            width: 1,
                            color: Color(0xFF8CBA24),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            width: 1,
                            color: Color(0xFF8CBA24),
                          ),
                        ),
                      ),
                      keyboardType: TextInputType
                          .phone, // Telefon numarası için uygun klavye türü
                      style: TextStyle(color: Colors.white),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                        PhoneNumberFormatter(), // Özel bir giriş biçimi düzenleyici (aşağıda tanımlanacak)
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: Container(
                      height: 40,
                      width: 300,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF8CBA24),
                        ),
                        child: Text(
                          "Telefon Numarası Ekle",
                          style: TextStyle(fontSize: 16),
                        ),
                        onPressed: () {
                          String deger = _controller.text.replaceAll(" ", "");

                          checkInternetConnection().then((value) {
                            if (value) {
                              if (deger.length == 11) {
                                writeData(true);
                                OneSignal.shared.sendTag("phoneNumber", deger);
                                print(deger);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WebViewPage(),
                                  ),
                                );
                              } else {
                                _showToastWhenNotValid(
                                  context,
                                  "Girilen bilgileri kontrol ediniz!",
                                );
                              }
                            } else {
                              _showToastWhenNotValid(
                                context,
                                "İnternet bağlantınızı kontrol ediniz!",
                              );
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WebViewPage extends StatelessWidget {
  final Completer<WebViewController> _completer =
      Completer<WebViewController>();

  Future<bool> _onBackPressed(WebViewController webViewController) async {
    if (await webViewController.canGoBack()) {
      webViewController.goBack();
      return false;
    } else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return WillPopScope(
      onWillPop: () async {
        final webController = await _completer.future;

        return _onBackPressed(webController);
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          title: Center(child: Text("")),
          backgroundColor: Color(0xFF2F2E3E),
        ),
        body: WebView(
          initialUrl: Uri.encodeFull("http://agrowio.targe.com.tr/"),
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController webViewController) {
            _completer.complete(webViewController);
          },
        ),
      ),
    );
  }
}

void _showToastWhenNotValid(BuildContext context, String message) {
  final scaffold = ScaffoldMessenger.of(context);
  scaffold.showSnackBar(
    SnackBar(
      backgroundColor: Color(0xFF8CBA24),
      content: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}

Future<bool> checkInternetConnection() async {
  bool result = await InternetConnectionChecker().hasConnection;
  return result;
}

void writeData(bool isSubscribed) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setBool("UserInfo", isSubscribed);
}

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Telefon numarasını istediğiniz formata dönüştürün
    final text = newValue.text
        .replaceAllMapped(RegExp(r'(\d{4})(\d{3})(\d{4})'), (match) {
      return '${match[1]} ${match[2]} ${match[3]}';
    });

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
