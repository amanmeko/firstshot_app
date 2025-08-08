import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';

// Conditional import: use real webview on mobile, stub elsewhere
import 'webview_mobile.dart' if (dart.library.html) 'webview_stub.dart' as wv;

class PaymentWebViewPage extends StatefulWidget {
  final String? url;
  final String? html;
  final String? title;

  const PaymentWebViewPage({
    super.key,
    this.url,
    this.html,
    this.title,
  }) : assert(url != null || html != null, 'Either url or html must be provided');

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late final wv.WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = wv.WebViewController()
        ..setJavaScriptMode(wv.JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          wv.NavigationDelegate(
            onPageStarted: (_) => setState(() => _isLoading = true),
            onPageFinished: (_) => setState(() => _isLoading = false),
            onNavigationRequest: (req) {
              return wv.NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(
          widget.html != null
              ? Uri.dataFromString(
                  widget.html!,
                  mimeType: 'text/html',
                  encoding: utf8,
                )
              : Uri.parse(widget.url!),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Payment'),
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          if (widget.url != null)
            IconButton(
              icon: const Icon(Icons.open_in_browser),
              onPressed: () => launchUrl(Uri.parse(widget.url!), mode: LaunchMode.externalApplication),
            ),
        ],
      ),
      body: kIsWeb
          ? _buildWebFallback()
          : Stack(
              children: [
                wv.WebViewWidget(controller: _controller),
                // Stylish loading overlay
                AnimatedOpacity(
                  opacity: _isLoading ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !_isLoading,
                    child: _buildStylishLoader(context),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildWebFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _BrandHeader(),
              const SizedBox(height: 24),
              _ProgressRing(),
              const SizedBox(height: 16),
              Shimmer.fromColors(
                baseColor: Colors.grey.shade400,
                highlightColor: Colors.grey.shade200,
                child: const Text(
                  'Redirecting to secure payment...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              if (widget.url != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(widget.url!), mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.lock_open_rounded),
                    label: const Text('Open Payment Page'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                )
              else
                const Text('Please use a mobile device to proceed.'),
              const SizedBox(height: 24),
              const _PaymentBadges(),
              const SizedBox(height: 8),
              const Text(
                'Secured by Fiuu',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStylishLoader(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _BrandHeader(),
              SizedBox(height: 28),
              _ProgressRing(),
              SizedBox(height: 16),
              _LoaderText(),
              SizedBox(height: 24),
              _PaymentBadges(),
              SizedBox(height: 8),
              Text('Secured by Fiuu', style: TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.lock_rounded, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 16),
        const Text(
          'Redirecting to Payment',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _LoaderText extends StatelessWidget {
  const _LoaderText();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade400,
      highlightColor: Colors.grey.shade200,
      child: const Text(
        'Please wait while we connect to the gateway...',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              backgroundColor: Colors.black12,
            ),
          ),
          const Icon(Icons.shield_rounded, color: Color(0xFF06B6D4)),
        ],
      ),
    );
  }
}

class _PaymentBadges extends StatelessWidget {
  const _PaymentBadges();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        _badgeSvg('assets/icons/credit_card.svg'),
        _badgeSvg('assets/icons/wallet.svg'),
        _badgeImage('assets/icons/mastercard.png'),
      ],
    );
  }

  Widget _badgeSvg(String asset) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SvgPicture.asset(
        asset,
        width: 28,
        height: 28,
      ),
    );
  }

  Widget _badgeImage(String asset) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Image.asset(
        asset,
        width: 28,
        height: 28,
        fit: BoxFit.contain,
      ),
    );
  }
}
