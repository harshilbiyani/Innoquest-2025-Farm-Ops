import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/network_service.dart';
import 'services/api_service.dart';
import 'services/localization_service.dart';

/// Network diagnostics page to help debug connection issues
class NetworkDiagnosticsPage extends StatefulWidget {
  const NetworkDiagnosticsPage({super.key});

  @override
  State<NetworkDiagnosticsPage> createState() => _NetworkDiagnosticsPageState();
}

class _NetworkDiagnosticsPageState extends State<NetworkDiagnosticsPage> {
  Map<String, dynamic>? _networkInfo;
  bool _isLoading = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _loadNetworkInfo();
  }

  Future<void> _loadNetworkInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final info = await NetworkService.getNetworkInfo();
      setState(() {
        _networkInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error loading network info: $e', isError: true);
    }
  }

  Future<void> _refreshBackendUrl() async {
    setState(() {
      _isLoading = true;
      _testResult = null;
    });

    try {
      await ApiService.refreshBackendUrl();
      await _loadNetworkInfo();
      _showSnackBar('Backend URL refreshed successfully!');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error refreshing: $e', isError: true);
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _testResult = null;
    });

    try {
      final backendUrl = await ApiService.getBaseUrl();
      final isReachable = await NetworkService.isUrlReachable(backendUrl);

      setState(() {
        _testResult = isReachable
            ? '✅ Backend server is reachable at $backendUrl'
            : '❌ Backend server is NOT reachable at $backendUrl';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ Error testing connection: $e';
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2FCE1),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Network Diagnostics',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Network Info Card
                  _buildInfoCard(
                    'Network Information',
                    [
                      _buildInfoRow(
                        'Device IP',
                        _networkInfo?['deviceIp'] ?? 'Not detected',
                        Icons.phone_android,
                      ),
                      _buildInfoRow(
                        'Backend URL',
                        _networkInfo?['backendUrl'] ?? 'Not detected',
                        Icons.cloud,
                      ),
                      _buildInfoRow(
                        'Cached',
                        _networkInfo?['cached'] == true ? 'Yes' : 'No',
                        Icons.storage,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Test Result Card
                  if (_testResult != null)
                    _buildResultCard(_testResult!),

                  const SizedBox(height: 16),

                  // Actions
                  _buildActionButton(
                    'Test Connection',
                    Icons.network_check,
                    _testConnection,
                  ),

                  const SizedBox(height: 12),

                  _buildActionButton(
                    'Refresh Backend URL',
                    Icons.refresh,
                    _refreshBackendUrl,
                  ),

                  const SizedBox(height: 12),

                  _buildActionButton(
                    'Clear Cache',
                    Icons.delete_outline,
                    () {
                      NetworkService.clearCache();
                      _loadNetworkInfo();
                      _showSnackBar('Cache cleared successfully!');
                    },
                  ),

                  const SizedBox(height: 24),

                  // Info Box
                  _buildInfoBox(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(String message) {
    final isSuccess = message.contains('✅');
    return Card(
      elevation: 2,
      color: isSuccess ? Colors.green[50] : Colors.red[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.green[700],
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.green[700]!),
        ),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'About Auto IP Detection',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'The app automatically detects the backend server IP address. '
            'If your network changes or OTP fails, use "Refresh Backend URL" '
            'to re-detect the server.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.blue[900],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
