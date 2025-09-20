import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
// Tambahkan impor platform spesifik
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class InvoiceWebviewPage extends StatefulWidget {
  final String redirectUrl;

  const InvoiceWebviewPage({super.key, required this.redirectUrl});

  @override
  State<InvoiceWebviewPage> createState() => _InvoiceWebviewPageState();
}

class _InvoiceWebviewPageState extends State<InvoiceWebviewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _loadingProgress = 0;
  bool _webViewInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    // Buat controller WebView
    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller = WebViewController.fromPlatformCreationParams(params);

    // Inisialisasi platform spesifik
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _isLoading = true;
            _loadingProgress = 0;
          }),
          onProgress: (progress) => setState(() {
            _loadingProgress = progress / 100.0;
          }),
          onPageFinished: (_) => setState(() {
            _isLoading = false;
          }),
          onWebResourceError: (error) {
            debugPrint("❌ WebView error: ${error.description}");
          },
          onUrlChange: (change) {
            debugPrint('URL changed to ${change.url}');
          },
        ),
      );

    setState(() {
      _webViewInitialized = true;
    });

    if (widget.redirectUrl.isNotEmpty) {
      debugPrint('🌐 Memuat URL pembayaran: ${widget.redirectUrl}');
      await _controller.loadRequest(Uri.parse(widget.redirectUrl));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Redirect URL tidak tersedia')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_webViewInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pembayaran Faspay')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran Faspay'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            LinearProgressIndicator(
              value: _loadingProgress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
        ],
      ),
    );
  }
}