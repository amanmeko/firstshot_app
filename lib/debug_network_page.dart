import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'utils/network_utils.dart';

class DebugNetworkPage extends StatefulWidget {
  const DebugNetworkPage({super.key});

  @override
  State<DebugNetworkPage> createState() => _DebugNetworkPageState();
}

class _DebugNetworkPageState extends State<DebugNetworkPage> {
  bool _isLoading = false;
  Map<String, dynamic>? _diagnostics;
  String? _error;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final diagnostics = await NetworkUtils.getNetworkDiagnostics();
      setState(() {
        _diagnostics = diagnostics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _testSpecificUrl() async {
    final urlController = TextEditingController(text: 'https://firstshot.my/api/auth/courts');
    
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Specific URL'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'Enter URL to test',
            hintText: 'https://example.com/api/endpoint',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, urlController.text),
            child: const Text('Test'),
          ),
        ],
      ),
    );

    if (url != null && url.isNotEmpty) {
      _testUrl(url);
    }
  }

  Future<void> _testUrl(String url) async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      final result = {
        'url': url,
        'statusCode': response.statusCode,
        'headers': response.headers,
        'body': response.body,
        'bodyLength': response.body.length,
        'timestamp': DateTime.now().toIso8601String(),
      };

      setState(() {
        _diagnostics = {'customTest': result};
        _isLoading = false;
      });

      // Show result in dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Test Result: ${response.statusCode}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('URL: $url'),
                const SizedBox(height: 8),
                Text('Status: ${response.statusCode}'),
                const SizedBox(height: 8),
                Text('Body Length: ${response.body.length}'),
                const SizedBox(height: 8),
                const Text('Response Body:'),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SelectableText(
                    response.body.length > 500 
                      ? '${response.body.substring(0, 500)}...\n\n[Truncated - Full length: ${response.body.length} characters]'
                      : response.body,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'Error testing URL: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runDiagnostics,
          ),
          IconButton(
            icon: const Icon(Icons.link),
            onPressed: _testSpecificUrl,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _runDiagnostics,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _diagnostics == null
                  ? const Center(child: Text('No diagnostics available'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection('Internet Connectivity', [
                            _buildStatusTile(
                              'Basic Internet',
                              _diagnostics!['internet'] ?? false,
                              'Can reach external servers',
                            ),
                          ]),
                          
                          if (_diagnostics!['dns'] != null) ...[
                            const SizedBox(height: 16),
                            _buildSection('DNS Resolution', [
                              _buildStatusTile(
                                'firstshot.my',
                                _diagnostics!['dns']['success'] ?? false,
                                _diagnostics!['dns']['success'] 
                                  ? 'Resolved to: ${_diagnostics!['dns']['addresses']?.join(', ') ?? 'Unknown'}'
                                  : 'Error: ${_diagnostics!['dns']['error'] ?? 'Unknown'}',
                              ),
                            ]),
                          ],

                          if (_diagnostics!['api'] != null) ...[
                            const SizedBox(height: 16),
                            _buildSection('API Connectivity', [
                              _buildStatusTile(
                                'https://firstshot.my/api/auth',
                                _diagnostics!['api']['success'] ?? false,
                                _diagnostics!['api']['success'] 
                                  ? 'Status: ${_diagnostics!['api']['statusCode']}'
                                  : 'Error: ${_diagnostics!['api']['error'] ?? 'Unknown'}',
                              ),
                            ]),
                          ],

                          if (_diagnostics!['multipleUrls'] != null) ...[
                            const SizedBox(height: 16),
                            _buildSection('Multiple URL Test', [
                              ...(_diagnostics!['multipleUrls'] as List).map((result) => 
                                _buildStatusTile(
                                  result['url'],
                                  result['success'],
                                  result['success'] 
                                    ? 'Status: ${result['statusCode']}'
                                    : 'Error: ${result['error']}',
                                ),
                              ),
                            ]),
                          ],

                          if (_diagnostics!['customTest'] != null) ...[
                            const SizedBox(height: 16),
                            _buildSection('Custom URL Test', [
                              _buildStatusTile(
                                _diagnostics!['customTest']['url'],
                                _diagnostics!['customTest']['statusCode'] == 200,
                                'Status: ${_diagnostics!['customTest']['statusCode']} - Length: ${_diagnostics!['customTest']['bodyLength']}',
                              ),
                            ]),
                          ],

                          const SizedBox(height: 32),
                          const Text(
                            'Troubleshooting Tips:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text('• Check your internet connection'),
                          const Text('• Verify the server is running'),
                          const Text('• Check if the API endpoint is correct'),
                          const Text('• Verify SSL certificates if using HTTPS'),
                          const Text('• Check server logs for errors'),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildStatusTile(String title, bool isSuccess, String subtitle) {
    return Card(
      child: ListTile(
        leading: Icon(
          isSuccess ? Icons.check_circle : Icons.error,
          color: isSuccess ? Colors.green : Colors.red,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(
          isSuccess ? Icons.arrow_forward_ios : Icons.info,
          size: 16,
        ),
      ),
    );
  }
}