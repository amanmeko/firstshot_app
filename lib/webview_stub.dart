import 'package:flutter/material.dart';

class JavaScriptMode {
  static const unrestricted = JavaScriptMode();
  const JavaScriptMode();
}

class NavigationDecision {
  static const navigate = NavigationDecision();
  const NavigationDecision();
}

class NavigationDelegate {
  final void Function(String url)? onPageStarted;
  final void Function(String url)? onPageFinished;
  final NavigationDecision Function(dynamic request)? onNavigationRequest;
  const NavigationDelegate({
    this.onPageStarted,
    this.onPageFinished,
    this.onNavigationRequest,
  });
}

class WebViewController {
  void setJavaScriptMode(JavaScriptMode mode) {}
  void setNavigationDelegate(NavigationDelegate delegate) {}
  Future<void> loadRequest(Uri uri) async {}
}

class WebViewWidget extends StatelessWidget {
  final WebViewController controller;
  const WebViewWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Payment page will open in a new tab.'),
      ),
    );
  }
}
