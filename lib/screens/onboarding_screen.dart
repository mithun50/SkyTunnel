import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/theme.dart';

/// First-run onboarding wizard that guides users through setup.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final TextEditingController _tokenController = TextEditingController();
  bool _isAuthenticating = false;
  bool _authSuccess = false;
  String? _authError;
  bool _ngrokDetected = false;

  @override
  void dispose() {
    _pageController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Row(
          children: [
            // Left panel - branding.
            Expanded(
              flex: 5,
              child: _buildLeftPanel(),
            ),
            // Right panel - steps.
            Expanded(
              flex: 7,
              child: _buildRightPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.darkBackground, Color(0xFF1a1a3e)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo.
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.cable,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'SkyTunnel',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'One-click game server hosting',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 40),
              // Step indicators.
              ...List.generate(4, (index) {
                return _buildStepIndicator(index);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int index) {
    final isActive = _currentPage == index;
    final isCompleted = _currentPage > index;
    final labels = ['Welcome', 'ngrok', 'Auth Token', 'Ready'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppTheme.successColor
                  : isActive
                      ? AppTheme.primaryColor
                      : Colors.white12,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : Colors.white54,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Text(
            labels[index],
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive
                  ? Colors.white
                  : isCompleted
                      ? AppTheme.successColor
                      : Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      color: AppTheme.darkSurface,
      child: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildWelcomePage(),
          _buildNgrokDetectionPage(),
          _buildAuthTokenPage(),
          _buildCompletePage(),
        ],
      ),
    );
  }

  // Page 1: Welcome.
  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Welcome to SkyTunnel',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Let\'s get you set up in just a few steps.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),
          _featureRow(Icons.download, 'Auto-download ngrok',
              'We\'ll install ngrok automatically if needed.'),
          const SizedBox(height: 16),
          _featureRow(Icons.vpn_key, 'One-click authentication',
              'Enter your free ngrok auth token once.'),
          const SizedBox(height: 16),
          _featureRow(Icons.cable, 'Create tunnels instantly',
              'Expose your game server with a single click.'),
          const SizedBox(height: 16),
          _featureRow(Icons.shield, 'Secure and reliable',
              'Auto-reconnect and encrypted tunnels.'),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => _nextPage(),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: const Text('Get Started'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Page 2: ngrok detection.
  Widget _buildNgrokDetectionPage() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'ngrok Setup',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'SkyTunnel uses ngrok to create secure tunnels. '
            'We\'ll detect it automatically or download it for you.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),
          // Status card.
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _ngrokDetected
                  ? AppTheme.successColor.withValues(alpha: 0.1)
                  : Colors.white10,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _ngrokDetected
                    ? AppTheme.successColor.withValues(alpha: 0.3)
                    : Colors.white12,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _ngrokDetected ? Icons.check_circle : Icons.search,
                  color: _ngrokDetected
                      ? AppTheme.successColor
                      : Colors.white54,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _ngrokDetected ? 'ngrok Found!' : 'Detecting...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              _ngrokDetected ? AppTheme.successColor : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _ngrokDetected
                            ? 'ngrok is installed and ready to use.'
                            : 'Click "Scan" to search for ngrok on your system.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Info text.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppTheme.infoColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'If ngrok is not installed, you can download it free from ngrok.com. '
                    'SkyTunnel can also auto-detect it after installation.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => _prevPage(),
                child: const Text('Back'),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => _detectNgrok(),
                    child: const Text('Scan'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _nextPage(),
                    child: const Text('Next'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Page 3: Auth token.
  Widget _buildAuthTokenPage() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Authentication',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Enter your ngrok auth token to create tunnels. '
            'Get one free at ngrok.com.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),
          // Token input.
          TextField(
            controller: _tokenController,
            decoration: InputDecoration(
              labelText: 'ngrok Auth Token',
              hintText: 'Paste your token here...',
              prefixIcon: const Icon(Icons.vpn_key, size: 20),
              suffixIcon: IconButton(
                icon: const Icon(Icons.open_in_new, size: 18),
                tooltip: 'Open ngrok dashboard',
                onPressed: () {
                  // Would use url_launcher in production.
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Link to get token.
          Text.rich(
            TextSpan(
              text: 'Don\'t have a token? ',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              children: [
                TextSpan(
                  text: 'Sign up free at dashboard.ngrok.com',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Authenticate button.
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isAuthenticating
                  ? null
                  : () => _authenticateToken(),
              child: _isAuthenticating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Authenticate'),
            ),
          ),
          // Auth result.
          if (_authSuccess) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle,
                      color: AppTheme.successColor, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Successfully authenticated!',
                    style: TextStyle(color: AppTheme.successColor),
                  ),
                ],
              ),
            ),
          ],
          if (_authError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppTheme.errorColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _authError!,
                      style: const TextStyle(color: AppTheme.errorColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => _prevPage(),
                child: const Text('Back'),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _nextPage(),
                    child: const Text('Skip for now'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _nextPage(),
                    child: const Text('Next'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Page 4: Complete.
  Widget _buildCompletePage() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success animation.
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.successColor.withValues(alpha: 0.3),
                width: 3,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.check_circle,
              color: AppTheme.successColor,
              size: 56,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'You\'re All Set!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'SkyTunnel is ready to use. Create your first tunnel\n'
            'and share your game server with the world.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          // Summary.
          Container(
            width: 400,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _summaryRow(
                  Icons.cable,
                  'ngrok',
                  _ngrokDetected ? 'Detected' : 'Configure in Settings',
                  _ngrokDetected,
                ),
                const Divider(height: 24),
                _summaryRow(
                  Icons.vpn_key,
                  'Auth Token',
                  _authSuccess ? 'Configured' : 'Configure in Settings',
                  _authSuccess,
                ),
                const Divider(height: 24),
                _summaryRow(
                  Icons.sports_esports,
                  'Ready to Host',
                  '7 game profiles available',
                  true,
                ),
              ],
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                widget.onComplete();
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
              child: const Text(
                'Start Using SkyTunnel',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
      IconData icon, String label, String value, bool isOk) {
    return Row(
      children: [
        Icon(
          isOk ? Icons.check_circle : Icons.info_outline,
          color: isOk ? AppTheme.successColor : AppTheme.warningColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: isOk ? AppTheme.successColor : Colors.white54,
          ),
        ),
      ],
    );
  }

  void _nextPage() {
    if (_currentPage < 3) {
      setState(() => _currentPage++);
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _detectNgrok() async {
    final state = context.read<AppState>();
    await state.ngrokService.detectNgrok();
    setState(() {
      _ngrokDetected = state.ngrokStatus.isReady;
    });
  }

  Future<void> _authenticateToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() => _authError = 'Please enter your auth token');
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _authError = null;
    });

    final state = context.read<AppState>();
    final success = await state.authenticateNgrok(token);

    setState(() {
      _isAuthenticating = false;
      _authSuccess = success;
      if (!success) {
        _authError = 'Authentication failed. Please check your token.';
      }
    });
  }
}
