import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../core/constants/app_colors.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String? url;
  final String? htmlContent;
  final String successUrl;
  final String failureUrl;
  final String title;

  const PaymentWebViewScreen({
    super.key,
    this.url,
    this.htmlContent,
    required this.successUrl,
    required this.failureUrl,
    this.title = 'Secure Payment',
  }) : assert(url != null || htmlContent != null);

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  WebViewController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(AppColors.background)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              setState(() => _isLoading = true);
              _handleNavigation(url);
            },
            onPageFinished: (String url) {
              setState(() => _isLoading = false);
              _handleNavigation(url);
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint('WebView Error: ${error.description}');
            },
            onNavigationRequest: (NavigationRequest request) {
              return _handleNavigation(request.url) 
                  ? NavigationDecision.prevent 
                  : NavigationDecision.navigate;
            },
          ),
        );

      if (widget.htmlContent != null) {
        _controller!.loadHtmlString(widget.htmlContent!);
      } else if (widget.url != null) {
        _controller!.loadRequest(Uri.parse(widget.url!));
      }
    } else {
       // On Web, we assume the launcher handled it, but set loading false
       _isLoading = false;
    }
  }

  bool _handleNavigation(String url) {
    if (url.startsWith(widget.successUrl)) {
      Navigator.pop(context, 'success');
      return true;
    } else if (url.startsWith(widget.failureUrl)) {
      Navigator.pop(context, 'failure');
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, 'cancelled'),
        ),
      ),
      body: kIsWeb 
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.open_in_new, size: 64, color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      "Payment is being processed in a new tab.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Please do not close this window until the transaction is complete.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.subtle, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                if (_controller != null) WebViewWidget(controller: _controller!),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
              ],
            ),
    );
  }
}
