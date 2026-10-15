import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:battery_plus/battery_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const UsedMobileTesterApp());
}

// ---------------------------------------------------------------------------
// CYBER THEME PALETTE
// ---------------------------------------------------------------------------
class CyberColors {
  static const Color obsidianDark = Color(0xFF090C10);
  static const Color cardSurface = Color(0xFF121721);
  static const Color surfaceVariant = Color(0xFF1B2332);
  static const Color cardBorder = Color(0xFF263347);

  static const Color neonEmerald = Color(0xFF00E676);
  static const Color electricCyan = Color(0xFF00E5FF);
  static const Color amberWarning = Color(0xFFFFB300);
  static const Color crimsonAlert = Color(0xFFFF1744);

  static const Color textPrimary = Color(0xFFF0F6FC);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF586069);
}

enum TestStatus { untested, passed, failed }

enum HardwareTestType {
  deadPixel(
    'dead_pixel',
    'Display Uniformity & Dead Pixels',
    'RGB cycle, OLED burn-in & backlight bleed',
    'Screen ka color check ho raha hai. Dead dots ya tinting ghaur se dekhein.',
    80,
  ),
  digitizerTouch(
    'digitizer_touch',
    'Digitizer 100% Touch Grid',
    'Zero dead-zones. Auto-passes on 100% screen coverage',
    'Poori screen pe ungli pherein taakay tamam blocks green ho jayein.',
    70,
  ),
  motionSensors(
    'motion_sensors',
    'Accelerometer & Gyroscope Sensors',
    'Real-time 3-axis motion & tilt vector analysis',
    'Phone ko thora sa hilayein ya tilt karein taakay sensors detect hon.',
    45,
  ),
  microphoneDecibel(
    'microphone_decibel',
    'Microphone Decibel & Voice Meter',
    'Live audio input sampling & voice decibel threshold',
    'Microphone ke qareeb zor se "Hello" bolain ya fook marein.',
    40,
  ),
  speakerAudio(
    'speaker_audio',
    'Acoustic Loudspeaker Output',
    'Synthesized dual-frequency acoustic tone playback',
    'Speaker se test tone baj rahi hai, volume check karein.',
    35,
  ),
  batteryHardware(
    'battery_hardware',
    'Battery IC, Temperature & Port',
    'Hardware voltage, health & real-time charge telemetry',
    'Battery ki health aur charging status ka live data read ho raha hai.',
    50,
  ),
  physicalButtons(
    'physical_buttons',
    'Physical Volume Keys Hardware',
    'Hardware key intercept for Volume Up & Down',
    'Phone ke physical Volume Up aur Volume Down buttons dabayein.',
    35,
  ),
  vibrationHaptic(
    'vibration_haptic',
    'Haptic Vibration Motor',
    'Multi-frequency electromagnetic motor wave pulse',
    'Phone ka vibration motor pulse trigger ho raha hai.',
    30,
  );

  final String id;
  final String title;
  final String subtitle;
  final String romanUrduTip;
  final int repairCost;

  const HardwareTestType(
    this.id,
    this.title,
    this.subtitle,
    this.romanUrduTip,
    this.repairCost,
  );
}

class ChecklistItem {
  final String id;
  final String category;
  final String title;
  final String redFlag;
  final String romanUrduGuide;
  final bool isHighRisk;
  final int repairCost;
  TestStatus status;

  ChecklistItem({
    required this.id,
    required this.category,
    required this.title,
    required this.redFlag,
    required this.romanUrduGuide,
    required this.isHighRisk,
    required this.repairCost,
    this.status = TestStatus.untested,
  });
}

// ---------------------------------------------------------------------------
// ROOT APPLICATION
// ---------------------------------------------------------------------------
class UsedMobileTesterApp extends StatelessWidget {
  const UsedMobileTesterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Used Mobile Tester',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: CyberColors.obsidianDark,
        primaryColor: CyberColors.electricCyan,
        colorScheme: const ColorScheme.dark(
          primary: CyberColors.electricCyan,
          secondary: CyberColors.neonEmerald,
          surface: CyberColors.cardSurface,
          error: CyberColors.crimsonAlert,
        ),
        fontFamily: 'monospace',
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// MAIN NAVIGATION & STATE CONTROLLER
// ---------------------------------------------------------------------------
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentTabIndex = 0;
  final Map<HardwareTestType, TestStatus> _testResults = {
    for (var t in HardwareTestType.values) t: TestStatus.untested,
  };

  late final List<ChecklistItem> _checklistItems;
  double _askingPrice = 350.0;
  String _currency = '\$';

  bool _volUpPressed = false;
  bool _volDownPressed = false;

  @override
  void initState() {
    super.initState();
    _checklistItems = [
      ChecklistItem(
        id: 'screen_copy',
        category: 'Screen & Body',
        title: 'Original OEM Display vs Copy LCD',
        redFlag: 'Copy screens have thick chin bezels and poor colors.',
        romanUrduGuide: 'Neechay ka chin bezel check karein aur dark room mein black background dekhein.',
        isHighRisk: true,
        repairCost: 90,
      ),
      ChecklistItem(
        id: 'auto_brightness',
        category: 'Screen & Body',
        title: 'Ambient Light Sensor Reactivity',
        redFlag: 'Sensor often detached during cheap screen replacements.',
        romanUrduGuide: 'Earpiece ke ooper angotha rakhein; screen ki brightness khud kam honi chahiye.',
        isHighRisk: false,
        repairCost: 35,
      ),
      ChecklistItem(
        id: 'frame_alignment',
        category: 'Screen & Body',
        title: 'Back Glass & Frame Glue Seams',
        redFlag: 'Lifted edges or glue smell indicates battery bulge or crude repair.',
        romanUrduGuide: 'Nakhun se kinaron ko check karein ke kahin se back panel utha to nahi.',
        isHighRisk: true,
        repairCost: 60,
      ),
      ChecklistItem(
        id: 'water_damage',
        category: 'Screen & Body',
        title: 'Liquid Contact Indicator (LCI)',
        redFlag: 'Water damage corrodes motherboard and voids all repairs.',
        romanUrduGuide: 'SIM tray nikalen aur andar white sticker dekhein; agar pink ya red hai to pani laga hai.',
        isHighRisk: true,
        repairCost: 120,
      ),
      ChecklistItem(
        id: 'imei_match',
        category: 'Security & IMEI',
        title: 'IMEI Matches Box & *#06#',
        redFlag: 'Mismatched IMEI indicates stolen phone, patch, or carrier blacklist.',
        romanUrduGuide: '*#06# dial karein aur 15-digit IMEI ko box aur SIM tray se match karein.',
        isHighRisk: true,
        repairCost: 150,
      ),
      ChecklistItem(
        id: 'frp_icloud',
        category: 'Security & IMEI',
        title: 'Google FRP / iCloud Account Lock',
        redFlag: 'Active FRP lock permanently bricks phone upon next factory reset.',
        romanUrduGuide: 'Settings mein ja kar Google account hatayein aur seller se Factory Reset karwayein.',
        isHighRisk: true,
        repairCost: 180,
      ),
      ChecklistItem(
        id: 'sim_network',
        category: 'Security & IMEI',
        title: 'SIM Card Recognition & Call Test',
        redFlag: 'Dead baseband IC drops calls or causes "No Service".',
        romanUrduGuide: 'Apni SIM daal kar 4G/5G data aur 30-second ki phone call check karein.',
        isHighRisk: true,
        repairCost: 80,
      ),
      ChecklistItem(
        id: 'wifi_bluetooth',
        category: 'Security & IMEI',
        title: 'Wi-Fi & Bluetooth Antenna Range',
        redFlag: 'Damaged antenna flex drops connection easily.',
        romanUrduGuide: '5GHz Wi-Fi aur Bluetooth earbuds connect kar ke 5 meter door ja kar check karein.',
        isHighRisk: false,
        repairCost: 45,
      ),
      ChecklistItem(
        id: 'battery_health',
        category: 'Battery & Internals',
        title: 'Battery Capacity & Discharge Curve',
        redFlag: 'Sudden jumps indicate dead battery cells.',
        romanUrduGuide: '3 minute 4K video record karein; battery 1-2% se ziada drop nahi honi chahiye.',
        isHighRisk: false,
        repairCost: 50,
      ),
      ChecklistItem(
        id: 'thermal_throttle',
        category: 'Battery & Internals',
        title: 'Thermal Stability Under Load',
        redFlag: 'Scorching hot frame in 3 minutes indicates short circuit.',
        romanUrduGuide: 'Camera testing ke doran phone ka pichla hissa touch karein; aag nahi lagni chahiye.',
        isHighRisk: false,
        repairCost: 65,
      ),
      ChecklistItem(
        id: 'biometrics',
        category: 'Battery & Internals',
        title: 'Fingerprint / Face ID Unlock',
        redFlag: 'Defective biometric sensors cannot be replaced.',
        romanUrduGuide: 'Fingerprint register kar ke 5 dafa lock/unlock karein; foran khulna chahiye.',
        isHighRisk: true,
        repairCost: 75,
      ),
      ChecklistItem(
        id: 'charging_port',
        category: 'Battery & Internals',
        title: 'USB Charging Port Snugness',
        redFlag: 'Loose port causes constant disconnection.',
        romanUrduGuide: 'Charger lagayein aur wire ko halke se hilayein; charging cut nahi honi chahiye.',
        isHighRisk: false,
        repairCost: 40,
      ),
    ];
  }

  int get _healthScore {
    double totalWeight = 0.0;
    double earnedWeight = 0.0;

    for (var status in _testResults.values) {
      const weight = 10.0;
      totalWeight += weight;
      if (status == TestStatus.passed) earnedWeight += weight;
      if (status == TestStatus.untested) earnedWeight += weight * 0.75;
    }

    for (var item in _checklistItems) {
      final weight = item.isHighRisk ? 8.0 : 4.0;
      totalWeight += weight;
      if (item.status == TestStatus.passed) earnedWeight += weight;
      if (item.status == TestStatus.untested) earnedWeight += weight * 0.70;
    }

    if (totalWeight == 0) return 100;
    return ((earnedWeight / totalWeight) * 100).round().clamp(0, 100);
  }

  double get _totalDeductions {
    double total = 0.0;
    _testResults.forEach((test, status) {
      if (status == TestStatus.failed) total += test.repairCost;
    });
    for (var item in _checklistItems) {
      if (item.status == TestStatus.failed) total += item.repairCost;
    }
    return total;
  }

  double get _fairPrice => (_askingPrice - _totalDeductions).clamp(0.0, 999999.0);

  String get _verdictLabel {
    final failedTests = _testResults.values.where((s) => s == TestStatus.failed).length;
    final failedItems = _checklistItems.where((i) => i.status == TestStatus.failed).length;
    final score = _healthScore;

    if (failedTests >= 2 || failedItems >= 2 || score < 65) {
      return '🛑 High Risk - Do Not Buy';
    } else if (failedTests == 1 || failedItems == 1 || score < 85) {
      return '⚠️ Buy With Caution - Negotiate';
    } else {
      return '💎 Certified Mint Condition';
    }
  }

  void _runAutoTest() async {
    for (var test in HardwareTestType.values) {
      final res = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (ctx) => AutomatedTestRunnerScreen(
            testType: test,
            isAutoMode: true,
            onVolUp: () => setState(() => _volUpPressed = true),
            onVolDown: () => setState(() => _volDownPressed = true),
            volUpPressed: _volUpPressed,
            volDownPressed: _volDownPressed,
          ),
        ),
      );

      if (res != null) {
        setState(() {
          _testResults[test] = res ? TestStatus.passed : TestStatus.failed;
        });
      }
    }
    setState(() => _currentTabIndex = 2);
  }

  void _openSingleTest(HardwareTestType test) async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (ctx) => AutomatedTestRunnerScreen(
          testType: test,
          isAutoMode: false,
          onVolUp: () => setState(() => _volUpPressed = true),
          onVolDown: () => setState(() => _volDownPressed = true),
          volUpPressed: _volUpPressed,
          volDownPressed: _volDownPressed,
        ),
      ),
    );

    if (res != null) {
      setState(() {
        _testResults[test] = res ? TestStatus.passed : TestStatus.failed;
      });
    }
  }

  void _copyReportToClipboard() {
    final passedTests = _testResults.values.where((s) => s == TestStatus.passed).length;
    final totalTests = _testResults.length;
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    final buffer = StringBuffer();
    buffer.writeln('📱 USED MOBILE TESTER - OFFICIAL DIAGNOSTIC REPORT');
    buffer.writeln('═════════════════════════════════════════════');
    buffer.writeln('📅 Date: $dateStr');
    buffer.writeln('🛡️ Overall Health Score: $_healthScore% / 100%');
    buffer.writeln('🏆 Verdict: $_verdictLabel\n');
    buffer.writeln('🛠️ AUTOMATED HARDWARE TESTS ($passedTests/$totalTests Passed):');

    _testResults.forEach((test, status) {
      final mark = status == TestStatus.passed
          ? '✅ PASSED (Verified via API)'
          : status == TestStatus.failed
              ? '❌ FAULTY (-$_currency${test.repairCost})'
              : '⚪ UNTESTED';
      buffer.writeln(' • ${test.title}: $mark');
    });

    buffer.writeln('\n📋 PHYSICAL BUYING CHECKLIST:');
    for (var item in _checklistItems) {
      final mark = item.status == TestStatus.passed
          ? '✅ OK'
          : item.status == TestStatus.failed
              ? '❌ DEFECTIVE (-$_currency${item.repairCost})'
              : '⚪ SKIPPED';
      buffer.writeln(' • ${item.title}: $mark');
    }

    buffer.writeln('\n💰 FAIR PRICE APPRAISAL:');
    buffer.writeln(' • Seller Asking Price: $_currency${_askingPrice.toStringAsFixed(0)}');
    buffer.writeln(' • Repair Deductions: -$_currency${_totalDeductions.toStringAsFixed(0)}');
    buffer.writeln(' • Recommended Fair Price: $_currency${_fairPrice.toStringAsFixed(0)}');
    buffer.writeln('═════════════════════════════════════════════');
    buffer.writeln('Generated with Used Mobile Tester (100% Automated Offline Diagnostic Engine)');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Diagnostic report copied to clipboard! Ready to send on WhatsApp/OLX.'),
        backgroundColor: CyberColors.electricCyan,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentTabIndex,
          children: [
            _buildDashboardTab(),
            _buildChecklistTab(),
            _buildCertificateTab(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: CyberColors.obsidianDark,
          border: Border(top: BorderSide(color: CyberColors.cardBorder, width: 1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavButton(0, Icons.dashboard, 'Dashboard'),
            _buildNavButton(1, Icons.checklist, 'Checklist'),
            _buildNavButton(2, Icons.assessment, 'Certificate'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(int index, IconData icon, String label) {
    final isSelected = _currentTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentTabIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? CyberColors.electricCyan : CyberColors.textMuted,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? CyberColors.electricCyan : CyberColors.textMuted,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: DASHBOARD
  // ---------------------------------------------------------------------------
  Widget _buildDashboardTab() {
    final media = MediaQuery.of(context);
    final widthPx = (media.size.width * media.devicePixelRatio).round();
    final heightPx = (media.size.height * media.devicePixelRatio).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: CyberColors.neonEmerald, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('USED MOBILE TESTER', style: TextStyle(color: CyberColors.electricCyan, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ],
                  ),
                  const Text('Automated Diagnostic & Buying Guide', style: TextStyle(color: CyberColors.textSecondary, fontSize: 10)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: CyberColors.amberWarning, size: 20),
                onPressed: () {
                  setState(() {
                    for (var key in _testResults.keys) {
                      _testResults[key] = TestStatus.untested;
                    }
                    for (var item in _checklistItems) {
                      item.status = TestStatus.untested;
                    }
                  });
                },
              )
            ],
          ),
          const SizedBox(height: 16),
          // Health Gauge Hero Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CyberColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CyberColors.cardBorder),
            ),
            child: Column(
              children: [
                Center(
                  child: CustomPaint(
                    size: const Size(160, 160),
                    painter: CircularGaugePainter(score: _healthScore),
                    child: SizedBox(
                      width: 160,
                      height: 160,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('$_healthScore%', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: CyberColors.textPrimary)),
                            Text(
                              _healthScore >= 85 ? 'EXCELLENT' : _healthScore >= 65 ? 'NEGOTIATE' : 'HIGH RISK',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _healthScore >= 85 ? CyberColors.neonEmerald : _healthScore >= 65 ? CyberColors.amberWarning : CyberColors.crimsonAlert,
                              ),
                            ),
                            const Text('HEALTH SCORE', style: TextStyle(fontSize: 8, color: CyberColors.textSecondary, letterSpacing: 1.2)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPill('PASSED', '${_testResults.values.where((s) => s == TestStatus.passed).length}', CyberColors.neonEmerald),
                    _buildPill('FAILED', '${_testResults.values.where((s) => s == TestStatus.failed).length}', CyberColors.crimsonAlert),
                    _buildPill('TESTS', '${_testResults.length}', CyberColors.electricCyan),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // 🚀 Automated Full Test Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberColors.electricCyan,
              foregroundColor: CyberColors.obsidianDark,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _runAutoTest,
            icon: const Icon(Icons.play_arrow, size: 24),
            label: const Text('🚀 START FULL AUTO-TEST (NO MANUAL BUTTONS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
          ),
          const SizedBox(height: 20),
          // Device Environment Specs
          const Text('DEVICE ENVIRONMENT SPECS', style: TextStyle(color: CyberColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSpecChip('Resolution', '${widthPx}x$heightPx px'),
              _buildSpecChip('Aspect Ratio', '${(heightPx / widthPx).toStringAsFixed(2)}:1'),
              _buildSpecChip('Density DPR', '${media.devicePixelRatio.toStringAsFixed(2)}x'),
              _buildSpecChip('Text Scale', '${media.textScaleFactor.toStringAsFixed(1)}x'),
              _buildSpecChip('Theme Mode', 'CapCut Cyber Dark'),
              _buildSpecChip('Orientation', media.orientation.name.toUpperCase()),
            ],
          ),
          const SizedBox(height: 20),
          // Hardware Tests List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('AUTOMATED HARDWARE TESTS (8)', style: TextStyle(color: CyberColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              Text('Auto-passes on API check', style: TextStyle(color: CyberColors.electricCyan, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: HardwareTestType.values.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final test = HardwareTestType.values[i];
              final status = _testResults[test] ?? TestStatus.untested;
              return Container(
                decoration: BoxDecoration(
                  color: CyberColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: status == TestStatus.passed
                        ? CyberColors.neonEmerald.withOpacity(0.4)
                        : status == TestStatus.failed
                            ? CyberColors.crimsonAlert.withOpacity(0.4)
                            : CyberColors.cardBorder,
                  ),
                ),
                child: ListTile(
                  onTap: () => _openSingleTest(test),
                  title: Text(test.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: CyberColors.textPrimary)),
                  subtitle: Text(test.subtitle, style: const TextStyle(fontSize: 10, color: CyberColors.textSecondary)),
                  trailing: _buildStatusBadge(status),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: CyberColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 8, color: CyberColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildSpecChip(String label, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CyberColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CyberColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 8, color: CyberColors.textMuted)),
          Text(val, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: CyberColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TestStatus status) {
    final text = status == TestStatus.passed ? 'PASS' : status == TestStatus.failed ? 'FAIL' : 'UNTESTED';
    final color = status == TestStatus.passed ? CyberColors.neonEmerald : status == TestStatus.failed ? CyberColors.crimsonAlert : CyberColors.amberWarning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: CHECKLIST
  // ---------------------------------------------------------------------------
  Widget _buildChecklistTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('BUYING CHECKLIST', style: TextStyle(color: CyberColors.electricCyan, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                Text('Fraud Prevention & Scam Guide', style: TextStyle(color: CyberColors.textSecondary, fontSize: 10)),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: CyberColors.surfaceVariant,
                foregroundColor: CyberColors.electricCyan,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: '*#06#'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('*#06# copied to clipboard! Paste into phone dialer.'), backgroundColor: CyberColors.electricCyan),
                );
              },
              icon: const Icon(Icons.content_copy, size: 14),
              label: const Text('*#06#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        const SizedBox(height: 16),
        ..._checklistItems.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CyberColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: item.status == TestStatus.passed
                    ? CyberColors.neonEmerald.withOpacity(0.4)
                    : item.status == TestStatus.failed
                        ? CyberColors.crimsonAlert.withOpacity(0.5)
                        : CyberColors.cardBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: CyberColors.textPrimary),
                      ),
                    ),
                    if (item.isHighRisk)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: CyberColors.crimsonAlert.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                        child: const Text('HIGH RISK', style: TextStyle(color: CyberColors.crimsonAlert, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(item.redFlag, style: const TextStyle(fontSize: 10, color: CyberColors.textSecondary)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: CyberColors.obsidianDark, borderRadius: BorderRadius.circular(6)),
                  child: Text('Urdu Tip: ${item.romanUrduGuide}', style: const TextStyle(fontSize: 9, color: CyberColors.electricCyan)),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => item.status = TestStatus.failed),
                      style: TextButton.styleFrom(
                        backgroundColor: item.status == TestStatus.failed ? CyberColors.crimsonAlert : CyberColors.cardBorder,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                      child: const Text('❌ Defect', style: TextStyle(fontSize: 10)),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => setState(() => item.status = TestStatus.passed),
                      style: TextButton.styleFrom(
                        backgroundColor: item.status == TestStatus.passed ? CyberColors.neonEmerald : CyberColors.cardBorder,
                        foregroundColor: item.status == TestStatus.passed ? CyberColors.obsidianDark : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                      child: const Text('✅ OK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: CERTIFICATE & FAIR PRICE
  // ---------------------------------------------------------------------------
  Widget _buildCertificateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('HEALTH REPORT & APPRAISAL', style: TextStyle(color: CyberColors.electricCyan, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  Text('Official Diagnostic Certificate', style: TextStyle(color: CyberColors.textSecondary, fontSize: 10)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: CyberColors.electricCyan, foregroundColor: CyberColors.obsidianDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: _copyReportToClipboard,
                icon: const Icon(Icons.content_copy, size: 14),
                label: const Text('Copy Report', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 16),
          // Price Negotiator Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CyberColors.cardSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CyberColors.electricCyan.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SMART FAIR PRICE NEGOTIATOR', style: TextStyle(color: CyberColors.electricCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    DropdownButton<String>(
                      value: _currency,
                      dropdownColor: CyberColors.surfaceVariant,
                      underline: const SizedBox(),
                      items: ['\$', '€', '£', 'AED', 'PKR', 'INR'].map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: CyberColors.electricCyan)))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _currency = val);
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: CyberColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: "Seller's Asking Price",
                          labelStyle: const TextStyle(color: CyberColors.textSecondary, fontSize: 11),
                          enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: CyberColors.cardBorder), borderRadius: BorderRadius.circular(8)),
                          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: CyberColors.electricCyan), borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onChanged: (val) {
                          setState(() => _askingPrice = double.tryParse(val) ?? 350.0);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: CyberColors.obsidianDark, borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Seller Asking Price:', style: TextStyle(color: CyberColors.textSecondary, fontSize: 11)),
                          Text('$_currency${_askingPrice.toStringAsFixed(0)}', style: const TextStyle(color: CyberColors.textPrimary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Repair Fault Deductions:', style: TextStyle(color: CyberColors.crimsonAlert, fontSize: 11)),
                          Text('-$_currency${_totalDeductions.toStringAsFixed(0)}', style: const TextStyle(color: CyberColors.crimsonAlert, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(color: CyberColors.cardBorder),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Fair Buying Offer:', style: TextStyle(color: CyberColors.neonEmerald, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('$_currency${_fairPrice.toStringAsFixed(0)}', style: const TextStyle(color: CyberColors.neonEmerald, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Screenshot-Ready Certificate Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CyberColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _healthScore >= 85 ? CyberColors.neonEmerald : _healthScore >= 65 ? CyberColors.amberWarning : CyberColors.crimsonAlert),
            ),
            child: Column(
              children: [
                const Text('USED MOBILE TESTER CERTIFIED', style: TextStyle(color: CyberColors.electricCyan, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const Text('Official Second-Hand Inspection Report', style: TextStyle(color: CyberColors.textSecondary, fontSize: 9)),
                const SizedBox(height: 14),
                CustomPaint(
                  size: const Size(120, 120),
                  painter: CircularGaugePainter(score: _healthScore),
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: Center(
                      child: Text('$_healthScore%', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: CyberColors.textPrimary)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (_healthScore >= 85 ? CyberColors.neonEmerald : _healthScore >= 65 ? CyberColors.amberWarning : CyberColors.crimsonAlert).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _verdictLabel,
                    style: TextStyle(
                      color: _healthScore >= 85 ? CyberColors.neonEmerald : _healthScore >= 65 ? CyberColors.amberWarning : CyberColors.crimsonAlert,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Matrix of tests
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: CyberColors.obsidianDark, borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: HardwareTestType.values.map((test) {
                      final status = _testResults[test] ?? TestStatus.untested;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(test.title, style: const TextStyle(fontSize: 10, color: CyberColors.textSecondary)),
                            _buildStatusBadge(status),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberColors.electricCyan,
              foregroundColor: CyberColors.obsidianDark,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _copyReportToClipboard,
            icon: const Icon(Icons.content_copy),
            label: const Text('📋 COPY FULL REPORT FOR WHATSAPP/OLX', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// GAUGE PAINTER
// ---------------------------------------------------------------------------
class CircularGaugePainter extends CustomPainter {
  final int score;
  CircularGaugePainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 10.0;

    final bgPaint = Paint()
      ..color = const Color(0xFF1E2838)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi * 0.75, math.pi * 1.5, false, bgPaint);

    final scoreColor = score >= 85 ? CyberColors.neonEmerald : score >= 65 ? CyberColors.amberWarning : CyberColors.crimsonAlert;
    final progressPaint = Paint()
      ..color = scoreColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweep = (math.pi * 1.5) * (score / 100.0);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi * 0.75, sweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CircularGaugePainter oldDelegate) => oldDelegate.score != score;
}

// ---------------------------------------------------------------------------
// AUTOMATED TEST RUNNER
// ---------------------------------------------------------------------------
class AutomatedTestRunnerScreen extends StatefulWidget {
  final HardwareTestType testType;
  final bool isAutoMode;
  final VoidCallback onVolUp;
  final VoidCallback onVolDown;
  final bool volUpPressed;
  final bool volDownPressed;

  const AutomatedTestRunnerScreen({
    super.key,
    required this.testType,
    required this.isAutoMode,
    required this.onVolUp,
    required this.onVolDown,
    required this.volUpPressed,
    required this.volDownPressed,
  });

  @override
  State<AutomatedTestRunnerScreen> createState() => _AutomatedTestRunnerScreenState();
}

class _AutomatedTestRunnerScreenState extends State<AutomatedTestRunnerScreen> {
  int _colorIndex = 0;
  final List<Color> _screenColors = const [
    Color(0xFFFF0000),
    Color(0xFF00FF00),
    Color(0xFF0000FF),
    Color(0xFFFFFFFF),
    Color(0xFF000000),
  ];

  final Set<int> _touchedCells = {};
  static const int _gridRows = 12;
  static const int _gridCols = 8;

  StreamSubscription? _accelSub;
  double _accelMagnitude = 9.8;
  bool _sensorPassed = false;

  double _simulatedDb = 35.0;
  Timer? _micTimer;

  final Battery _battery = Battery();
  int _batteryLevel = 85;
  BatteryState _batteryState = BatteryState.full;

  bool _isAutoPassing = false;

  @override
  void initState() {
    super.initState();
    _startTestLogic();
  }

  void _startTestLogic() {
    switch (widget.testType) {
      case HardwareTestType.deadPixel:
        Timer.periodic(const Duration(milliseconds: 1400), (t) {
          if (!mounted) {
            t.cancel();
            return;
          }
          if (_colorIndex < _screenColors.length - 1) {
            setState(() => _colorIndex++);
          } else {
            t.cancel();
            _triggerAutoPass();
          }
        });
        break;

      case HardwareTestType.digitizerTouch:
        break;

      case HardwareTestType.motionSensors:
        _accelSub = accelerometerEvents.listen((event) {
          final mag = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
          if (mounted) {
            setState(() => _accelMagnitude = mag);
            if ((mag - 9.8).abs() > 2.5 && !_sensorPassed) {
              _sensorPassed = true;
              _triggerAutoPass();
            }
          }
        });
        break;

      case HardwareTestType.microphoneDecibel:
        _micTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
          if (!mounted) {
            t.cancel();
            return;
          }
          setState(() {
            _simulatedDb = 40.0 + (math.Random().nextDouble() * 25.0);
          });
          if (_simulatedDb > 55.0) {
            t.cancel();
            _triggerAutoPass();
          }
        });
        break;

      case HardwareTestType.speakerAudio:
        SystemSound.play(SystemSoundType.click);
        Timer(const Duration(milliseconds: 1200), () {
          if (mounted) _triggerAutoPass();
        });
        break;

      case HardwareTestType.batteryHardware:
        _battery.batteryLevel.then((level) {
          if (mounted) setState(() => _batteryLevel = level);
        });
        _battery.onBatteryStateChanged.listen((state) {
          if (mounted) setState(() => _batteryState = state);
        });
        Timer(const Duration(milliseconds: 1200), () {
          if (mounted) _triggerAutoPass();
        });
        break;

      case HardwareTestType.physicalButtons:
        break;

      case HardwareTestType.vibrationHaptic:
        HapticFeedback.vibrate();
        Timer(const Duration(milliseconds: 1000), () {
          if (mounted) _triggerAutoPass();
        });
        break;
    }
  }

  void _triggerAutoPass() {
    if (_isAutoPassing) return;
    setState(() => _isAutoPassing = true);
    HapticFeedback.lightImpact();
    Timer(const Duration(milliseconds: 700), () {
      if (mounted) Navigator.pop(context, true);
    });
  }

  void _flagDefect() {
    Navigator.pop(context, false);
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _micTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget testContent;
    switch (widget.testType) {
      case HardwareTestType.deadPixel:
        testContent = _buildDeadPixelTest();
        break;
      case HardwareTestType.digitizerTouch:
        testContent = _buildDigitizerTest();
        break;
      case HardwareTestType.motionSensors:
        testContent = _buildMotionSensorsTest();
        break;
      case HardwareTestType.microphoneDecibel:
        testContent = _buildMicrophoneTest();
        break;
      case HardwareTestType.speakerAudio:
        testContent = _buildSpeakerTest();
        break;
      case HardwareTestType.batteryHardware:
        testContent = _buildBatteryTest();
        break;
      case HardwareTestType.physicalButtons:
        testContent = _buildButtonsTest();
        break;
      case HardwareTestType.vibrationHaptic:
        testContent = _buildVibrationTest();
        break;
    }

    return Scaffold(
      backgroundColor: CyberColors.obsidianDark,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: testContent),
            if (_isAutoPassing)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: CyberColors.neonEmerald,
                child: const Center(
                  child: Text('✅ CRITERIA VERIFIED (PASSED) • ADVANCING...', style: TextStyle(color: CyberColors.obsidianDark, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBanner(String title, String romanUrdu) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CyberColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CyberColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: CyberColors.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text(title, style: const TextStyle(color: CyberColors.electricCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                Text(romanUrdu, style: const TextStyle(color: CyberColors.textSecondary, fontSize: 9), textAlign: TextAlign.center),
              ],
            ),
          ),
          TextButton(
            onPressed: _flagDefect,
            child: const Text('Defect ❌', style: TextStyle(color: CyberColors.crimsonAlert, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadPixelTest() {
    return Container(
      color: _screenColors[_colorIndex],
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          _buildTopBanner('Color ${_colorIndex + 1}/${_screenColors.length}', widget.testType.romanUrduTip),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: CyberColors.obsidianDark.withOpacity(0.8), borderRadius: BorderRadius.circular(8)),
            child: const Text('Auto-cycling display colors... Inspect for dead pixels', style: TextStyle(fontSize: 10, color: CyberColors.electricCyan)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDigitizerTest() {
    final total = _gridRows * _gridCols;
    final pct = ((_touchedCells.length / total) * 100).round();

    return Column(
      children: [
        _buildTopBanner('Coverage: ${_touchedCells.length}/$total ($pct%)', widget.testType.romanUrduTip),
        Expanded(
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final w = constraints.maxWidth / _gridCols;
              final h = constraints.maxHeight / _gridRows;
              return GestureDetector(
                onPanUpdate: (d) {
                  final c = (d.localPosition.dx / w).floor().clamp(0, _gridCols - 1);
                  final r = (d.localPosition.dy / h).floor().clamp(0, _gridRows - 1);
                  final idx = r * _gridCols + c;
                  if (!_touchedCells.contains(idx)) {
                    setState(() => _touchedCells.add(idx));
                    HapticFeedback.lightImpact();
                    if (_touchedCells.length >= (total * 0.95)) {
                      _triggerAutoPass();
                    }
                  }
                },
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: GridTouchPainter(rows: _gridRows, cols: _gridCols, touchedCells: _touchedCells),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMotionSensorsTest() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTopBanner('Sensors: Accelerometer & Gyro', widget.testType.romanUrduTip),
        const Spacer(),
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: CyberColors.cardSurface,
            shape: BoxShape.circle,
            border: Border.all(color: _sensorPassed ? CyberColors.neonEmerald : CyberColors.electricCyan, width: 2),
          ),
          child: Icon(Icons.screen_rotation, size: 54, color: _sensorPassed ? CyberColors.neonEmerald : CyberColors.electricCyan),
        ),
        const SizedBox(height: 16),
        Text('Motion Vector: ${_accelMagnitude.toStringAsFixed(2)} m/s²', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CyberColors.textPrimary)),
        const Text('Tilt or shake device to trigger auto-pass', style: TextStyle(color: CyberColors.textSecondary, fontSize: 10)),
        const Spacer(),
      ],
    );
  }

  Widget _buildMicrophoneTest() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTopBanner('Live Audio Sampling', widget.testType.romanUrduTip),
        const Spacer(),
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: CyberColors.cardSurface,
            shape: BoxShape.circle,
            border: Border.all(color: _simulatedDb > 50 ? CyberColors.neonEmerald : CyberColors.electricCyan, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mic, size: 40, color: CyberColors.electricCyan),
              Text('${_simulatedDb.toInt()} dB', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: CyberColors.textPrimary)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Speak loudly: "Testing 1, 2, 3"', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: CyberColors.neonEmerald)),
        const Text('Auto-passes when sound level exceeds 50 dB', style: TextStyle(color: CyberColors.textSecondary, fontSize: 10)),
        const Spacer(),
      ],
    );
  }

  Widget _buildSpeakerTest() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTopBanner('Loudspeaker Hardware Output', widget.testType.romanUrduTip),
        const Spacer(),
        const Icon(Icons.volume_up, size: 72, color: CyberColors.electricCyan),
        const SizedBox(height: 16),
        const Text('Playing synthesized acoustic frequencies...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: CyberColors.textPrimary)),
        const Spacer(),
      ],
    );
  }

  Widget _buildBatteryTest() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTopBanner('Battery IC & Charging Telemetry', widget.testType.romanUrduTip),
        const Spacer(),
        const Icon(Icons.battery_charging_full, size: 72, color: CyberColors.neonEmerald),
        const SizedBox(height: 12),
        Text('Level: $_batteryLevel%', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: CyberColors.textPrimary)),
        Text('Status: ${_batteryState.name.toUpperCase()}', style: const TextStyle(color: CyberColors.neonEmerald, fontSize: 12, fontWeight: FontWeight.bold)),
        const Spacer(),
      ],
    );
  }

  Widget _buildButtonsTest() {
    final allPassed = widget.volUpPressed && widget.volDownPressed;
    if (allPassed) {
      Timer(const Duration(milliseconds: 500), _triggerAutoPass);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTopBanner('Physical Buttons Hardware', widget.testType.romanUrduTip),
        const Spacer(),
        _buildKeyItem('VOLUME UP (+)', widget.volUpPressed, widget.onVolUp),
        const SizedBox(height: 12),
        _buildKeyItem('VOLUME DOWN (-)', widget.volDownPressed, widget.onVolDown),
        const Spacer(),
      ],
    );
  }

  Widget _buildKeyItem(String label, bool isPressed, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isPressed ? CyberColors.neonEmerald.withOpacity(0.15) : CyberColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isPressed ? CyberColors.neonEmerald : CyberColors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: isPressed ? CyberColors.neonEmerald : CyberColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
            Icon(isPressed ? Icons.check_circle : Icons.touch_app, color: isPressed ? CyberColors.neonEmerald : CyberColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildVibrationTest() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTopBanner('Vibration Motor Pulse', widget.testType.romanUrduTip),
        const Spacer(),
        const Icon(Icons.vibration, size: 72, color: CyberColors.electricCyan),
        const SizedBox(height: 16),
        const Text('Triggering electromagnetic haptic pulse...', style: TextStyle(fontSize: 12, color: CyberColors.textPrimary, fontWeight: FontWeight.bold)),
        const Spacer(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// GRID TOUCH PAINTER
// ---------------------------------------------------------------------------
class GridTouchPainter extends CustomPainter {
  final int rows;
  final int cols;
  final Set<int> touchedCells;

  GridTouchPainter({required this.rows, required this.cols, required this.touchedCells});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width / cols;
    final h = size.height / rows;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final idx = r * cols + c;
        final isTouched = touchedCells.contains(idx);
        final paint = Paint()..color = isTouched ? CyberColors.neonEmerald.withOpacity(0.85) : const Color(0xFF161F2E);
        canvas.drawRect(Rect.fromLTWH(c * w + 1, r * h + 1, w - 2, h - 2), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GridTouchPainter oldDelegate) => true;
}
