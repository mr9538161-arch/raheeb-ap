// ============================================================================
// main.dart — نظام إدارة المجمع الرياضي والترفيهي الشامل
// PlayStation + Billiards + Gym + Martial Arts + Sales + Expenses + Advances
// + Manager Dashboard & Backup + تسجيل دخول + حفظ دائم + أرشيف شفتات
//
// ملاحظة تشغيل (Setup note):
// أضف الاعتمادية التالية في ملف pubspec.yaml قبل التشغيل (مطلوبة للحفظ الدائم):
//   dependencies:
//     flutter:
//       sdk: flutter
//     shared_preferences: ^2.2.2
//
// كلمة سر المدير الافتراضية: 1234 (غيّرها من الثابت managerPassword بالأسفل)
//
// ملاحظة عن الطباعة: الفاتورة هنا نصية قابلة للنسخ/المشاركة. لطباعة فعلية على
// طابعة حقيقية أضف حزمة printing (^5.11.0) واستبدل دالة showReceiptDialog.
// ============================================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String managerPassword = '1234';

void main() {
  runApp(const SportsComplexApp());
}

enum UserRole { employee, manager }

// ============================================================================
// APP ROOT
// ============================================================================
class SportsComplexApp extends StatelessWidget {
  const SportsComplexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام إدارة المجمع الرياضي',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        fontFamily: 'Tahoma',
        scaffoldBackgroundColor: const Color(0xFFF3F5F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F5C57),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      home: const RootApp(),
    );
  }
}

// ============================================================================
// ROOT — يتحكم بالتنقل بين شاشة الدخول ولوحة التحكم
// ============================================================================
class RootApp extends StatefulWidget {
  const RootApp({super.key});
  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  UserRole? role;

  void _login(UserRole r) => setState(() => role = r);
  void _logout() => setState(() => role = null);

  @override
  Widget build(BuildContext context) {
    if (role == null) {
      return LoginScreen(onLogin: _login);
    }
    return MainDashboard(role: role!, onLogout: _logout);
  }
}

class LoginScreen extends StatefulWidget {
  final void Function(UserRole) onLogin;
  const LoginScreen({super.key, required this.onLogin});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final passwordCtrl = TextEditingController();
  String? error;

  void _tryManagerLogin() {
    if (passwordCtrl.text == managerPassword) {
      widget.onLogin(UserRole.manager);
    } else {
      setState(() => error = 'كلمة السر غير صحيحة');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F5C57),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.sports_esports, size: 60, color: Colors.teal),
                  const SizedBox(height: 10),
                  const Text('نظام إدارة المجمع الرياضي',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person),
                    label: const Text('دخول كموظف'),
                    onPressed: () => widget.onLogin(UserRole.employee),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('دخول المدير', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordCtrl,
                    obscureText: true,
                    decoration: InputDecoration(labelText: 'كلمة سر المدير', errorText: error),
                    onSubmitted: (_) => _tryManagerLogin(),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('دخول كمدير'),
                    onPressed: _tryManagerLogin,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// MODELS
// ============================================================================
class PSStation {
  final int number;
  bool isRunning = false;
  bool isPaused = false;
  Duration remaining = Duration.zero; // fixed-time countdown
  Duration elapsed = Duration.zero; // open-time count-up
  Timer? fixedTimer;
  Timer? openTimer;
  bool fixedFinished = false;
  PSStation(this.number);
}

class BilliardsEntry {
  final double amount;
  final int hour;
  final DateTime time;
  BilliardsEntry({required this.amount, required this.hour, required this.time});
  double get matches => amount / 100;
  Map<String, dynamic> toJson() => {
        'amount': amount,
        'hour': hour,
        'time': time.toIso8601String(),
      };
  factory BilliardsEntry.fromJson(Map<String, dynamic> j) => BilliardsEntry(
        amount: (j['amount'] as num).toDouble(),
        hour: j['hour'] as int,
        time: DateTime.parse(j['time'] as String),
      );
}

class Subscriber {
  String name;
  String phone;
  double paid;
  double remaining;
  DateTime startDate;
  DateTime endDate;
  String duration;
  Subscriber({
    required this.name,
    required this.phone,
    required this.paid,
    required this.remaining,
    required this.startDate,
    required this.endDate,
    required this.duration,
  });
  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'paid': paid,
        'remaining': remaining,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'duration': duration,
      };
  factory Subscriber.fromJson(Map<String, dynamic> j) => Subscriber(
        name: j['name'] as String,
        phone: j['phone'] as String,
        paid: (j['paid'] as num).toDouble(),
        remaining: (j['remaining'] as num).toDouble(),
        startDate: DateTime.parse(j['startDate'] as String),
        endDate: DateTime.parse(j['endDate'] as String),
        duration: j['duration'] as String,
      );
}

class VisitEntry {
  final double amount;
  final DateTime time;
  VisitEntry({required this.amount, required this.time});
  Map<String, dynamic> toJson() => {'amount': amount, 'time': time.toIso8601String()};
  factory VisitEntry.fromJson(Map<String, dynamic> j) => VisitEntry(
        amount: (j['amount'] as num).toDouble(),
        time: DateTime.parse(j['time'] as String),
      );
}

class SaleItem {
  final String name;
  final double price;
  final int qty;
  final DateTime time;
  SaleItem({required this.name, required this.price, required this.qty, required this.time});
  double get total => price * qty;
  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'qty': qty,
        'time': time.toIso8601String(),
      };
  factory SaleItem.fromJson(Map<String, dynamic> j) => SaleItem(
        name: j['name'] as String,
        price: (j['price'] as num).toDouble(),
        qty: j['qty'] as int,
        time: DateTime.parse(j['time'] as String),
      );
}

class ExpenseItem {
  final String description;
  final double amount;
  final DateTime time;
  ExpenseItem({required this.description, required this.amount, required this.time});
  Map<String, dynamic> toJson() => {
        'description': description,
        'amount': amount,
        'time': time.toIso8601String(),
      };
  factory ExpenseItem.fromJson(Map<String, dynamic> j) => ExpenseItem(
        description: j['description'] as String,
        amount: (j['amount'] as num).toDouble(),
        time: DateTime.parse(j['time'] as String),
      );
}

class AdvanceItem {
  final String worker;
  final double amount;
  final String reason;
  final DateTime time;
  AdvanceItem({required this.worker, required this.amount, required this.reason, required this.time});
  Map<String, dynamic> toJson() => {
        'worker': worker,
        'amount': amount,
        'reason': reason,
        'time': time.toIso8601String(),
      };
  factory AdvanceItem.fromJson(Map<String, dynamic> j) => AdvanceItem(
        worker: j['worker'] as String,
        amount: (j['amount'] as num).toDouble(),
        reason: j['reason'] as String,
        time: DateTime.parse(j['time'] as String),
      );
}

// ============================================================================
// MAIN DASHBOARD (holds ALL state)
// ============================================================================
class MainDashboard extends StatefulWidget {
  final UserRole role;
  final VoidCallback onLogout;
  const MainDashboard({super.key, required this.role, required this.onLogout});
  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> with TickerProviderStateMixin {
  static const double psHourlyRate = 400.0; // SAR/hr
  static const String prefsDataKey = 'daily_shift_data';
  static const String prefsArchiveKey = 'shift_archive';

  late TabController _tabController;
  late TabController _psSubTabController;
  late TabController _gymSubTabController;
  late TabController _martialSubTabController;

  bool _loaded = false;

  // ---- PlayStation ----
  final List<PSStation> stations = List.generate(7, (i) => PSStation(i + 1));
  double psTotalRevenue = 0;

  // ---- Billiards ----
  final List<BilliardsEntry> billiardsLog = [];
  final TextEditingController billiardsAmountCtrl = TextEditingController();
  int billiardsSelectedHour = DateTime.now().hour;
  double get billiardsTotal => billiardsLog.fold(0, (s, e) => s + e.amount);

  // ---- Gym ----
  final List<Subscriber> gymSubscribers = [];
  final List<VisitEntry> gymVisits = [];
  double get gymSubsTotal => gymSubscribers.fold(0, (s, e) => s + e.paid);
  double get gymVisitsTotal => gymVisits.fold(0, (s, e) => s + e.amount);
  double get gymTotal => gymSubsTotal + gymVisitsTotal;

  // ---- Martial Arts ----
  final List<Subscriber> martialSubscribers = [];
  final List<VisitEntry> martialVisits = [];
  double get martialSubsTotal => martialSubscribers.fold(0, (s, e) => s + e.paid);
  double get martialVisitsTotal => martialVisits.fold(0, (s, e) => s + e.amount);
  double get martialTotal => martialSubsTotal + martialVisitsTotal;

  // ---- Other Sales ----
  final List<SaleItem> sales = [];
  double get salesTotal => sales.fold(0, (s, e) => s + e.total);

  // ---- Expenses ----
  final List<ExpenseItem> expenses = [];
  double get expensesTotal => expenses.fold(0, (s, e) => s + e.amount);

  // ---- Advances ----
  final List<String> workers = ['عاصم', 'بكر', 'محمد الهندي', 'هلال', 'راغب'];
  final List<AdvanceItem> advances = [];
  double get advancesTotal => advances.fold(0, (s, e) => s + e.amount);

  // ---- Totals ----
  double get totalIncome => psTotalRevenue + billiardsTotal + gymTotal + martialTotal + salesTotal;
  double get netCash => totalIncome - expensesTotal - advancesTotal;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _psSubTabController = TabController(length: 2, vsync: this);
    _gymSubTabController = TabController(length: 2, vsync: this);
    _martialSubTabController = TabController(length: 2, vsync: this);
    _loadPersistedData();
  }

  @override
  void dispose() {
    for (final s in stations) {
      s.fixedTimer?.cancel();
      s.openTimer?.cancel();
    }
    _tabController.dispose();
    _psSubTabController.dispose();
    _gymSubTabController.dispose();
    _martialSubTabController.dispose();
    billiardsAmountCtrl.dispose();
    super.dispose();
  }

  // -------------------- PERSISTENCE --------------------
  Future<void> _loadPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(prefsDataKey);
      if (raw != null && raw.isNotEmpty) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        psTotalRevenue = (data['psTotalRevenue'] as num?)?.toDouble() ?? 0;
        billiardsLog
          ..clear()
          ..addAll((data['billiards'] as List? ?? []).map((e) => BilliardsEntry.fromJson(e)));
        gymSubscribers
          ..clear()
          ..addAll((data['gymSubscribers'] as List? ?? []).map((e) => Subscriber.fromJson(e)));
        gymVisits
          ..clear()
          ..addAll((data['gymVisits'] as List? ?? []).map((e) => VisitEntry.fromJson(e)));
        martialSubscribers
          ..clear()
          ..addAll((data['martialSubscribers'] as List? ?? []).map((e) => Subscriber.fromJson(e)));
        martialVisits
          ..clear()
          ..addAll((data['martialVisits'] as List? ?? []).map((e) => VisitEntry.fromJson(e)));
        sales
          ..clear()
          ..addAll((data['sales'] as List? ?? []).map((e) => SaleItem.fromJson(e)));
        expenses
          ..clear()
          ..addAll((data['expenses'] as List? ?? []).map((e) => ExpenseItem.fromJson(e)));
        advances
          ..clear()
          ..addAll((data['advances'] as List? ?? []).map((e) => AdvanceItem.fromJson(e)));
      }
    } catch (_) {
      // تجاهل أي خطأ في التحميل والبدء ببيانات فارغة
    } finally {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'psTotalRevenue': psTotalRevenue,
        'billiards': billiardsLog.map((e) => e.toJson()).toList(),
        'gymSubscribers': gymSubscribers.map((e) => e.toJson()).toList(),
        'gymVisits': gymVisits.map((e) => e.toJson()).toList(),
        'martialSubscribers': martialSubscribers.map((e) => e.toJson()).toList(),
        'martialVisits': martialVisits.map((e) => e.toJson()).toList(),
        'sales': sales.map((e) => e.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'advances': advances.map((e) => e.toJson()).toList(),
      };
      await prefs.setString(prefsDataKey, jsonEncode(data));
    } catch (_) {
      // تجاهل فشل الحفظ حتى لا يعطل واجهة المستخدم
    }
  }

  Future<void> _archiveShift(Map<String, dynamic> backup) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(prefsArchiveKey) ?? [];
      list.insert(0, jsonEncode(backup));
      if (list.length > 60) list.removeRange(60, list.length); // احتفظ بآخر 60 شفت
      await prefs.setStringList(prefsArchiveKey, list);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> _loadArchive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(prefsArchiveKey) ?? [];
      return list.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  // -------------------- ROLE / SECURITY HELPERS --------------------
  void _requireManagerAuth(String actionLabel, VoidCallback action) {
    if (widget.role == UserRole.manager) {
      action();
      return;
    }
    final pwCtrl = TextEditingController();
    String? err;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text('صلاحية المدير مطلوبة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('إجراء "$actionLabel" يحتاج كلمة سر المدير.'),
              const SizedBox(height: 10),
              TextField(
                controller: pwCtrl,
                obscureText: true,
                decoration: InputDecoration(labelText: 'كلمة السر', errorText: err),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (pwCtrl.text == managerPassword) {
                  Navigator.pop(ctx);
                  action();
                } else {
                  setD(() => err = 'كلمة السر غير صحيحة');
                }
              },
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );
  }

  String _two(int n) => n.toString().padLeft(2, '0');
  String fmtDuration(Duration d) {
    final h = _two(d.inHours);
    final m = _two(d.inMinutes.remainder(60));
    final s = _two(d.inSeconds.remainder(60));
    return '$h:$m:$s';
  }

  String fmtMoney(double v) => '${v.toStringAsFixed(2)} ريال';

  String fmtTime(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}';
  String fmtDate(DateTime t) => '${t.year}-${_two(t.month)}-${_two(t.day)}';

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  // -------------------- RECEIPT (نصي قابل للنسخ) --------------------
  void showReceiptDialog(String title, List<MapEntry<String, String>> lines) {
    final buffer = StringBuffer();
    buffer.writeln('=== $title ===');
    for (final l in lines) {
      buffer.writeln('${l.key}: ${l.value}');
    }
    buffer.writeln('التاريخ: ${fmtDate(DateTime.now())}  ${fmtTime(DateTime.now())}');
    final receiptText = buffer.toString();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('الفاتورة'),
        content: SingleChildScrollView(child: SelectableText(receiptText)),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: receiptText));
              _showSnack('تم نسخ الفاتورة، يمكنك لصقها لإرسالها أو طباعتها');
            },
            child: const Text('نسخ الفاتورة'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  // -------------------- PLAYSTATION LOGIC --------------------
  void startFixedSession(PSStation station, double amount) {
    station.fixedTimer?.cancel();
    final totalSeconds = (amount / psHourlyRate * 3600).round();
    setState(() {
      station.remaining = Duration(seconds: totalSeconds);
      station.isRunning = true;
      station.isPaused = false;
      station.fixedFinished = false;
      psTotalRevenue += amount;
    });
    _persist();
    showReceiptDialog('فاتورة بلايستيشن - وقت محدد', [
      MapEntry('المحطة', '${station.number}'),
      MapEntry('المبلغ', fmtMoney(amount)),
      MapEntry('المدة', fmtDuration(Duration(seconds: totalSeconds))),
    ]);
    station.fixedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (station.remaining.inSeconds <= 1) {
          station.remaining = Duration.zero;
          station.isRunning = false;
          station.fixedFinished = true;
          timer.cancel();
          SystemSound.play(SystemSoundType.alert);
          HapticFeedback.vibrate();
          _showTimeUpDialog(station);
        } else {
          station.remaining -= const Duration(seconds: 1);
        }
      });
    });
  }

  void _showTimeUpDialog(PSStation station) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.red[50],
        title: Row(
          children: const [
            Icon(Icons.alarm, color: Colors.red, size: 32),
            SizedBox(width: 8),
            Text('انتهى الوقت!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('انتهى الوقت المحدد لمحطة رقم ${station.number}.\nيرجى تحصيل التمديد أو إخلاء المحطة.',
            style: const TextStyle(fontSize: 15)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('تم الاطلاع'),
          ),
        ],
      ),
    );
  }

  void pauseFixedSession(PSStation station) {
    station.fixedTimer?.cancel();
    setState(() {
      station.isRunning = false;
      station.isPaused = true;
    });
    _showSnack('تم إيقاف الوقت مؤقتاً في محطة ${station.number}');
  }

  void resumeFixedSession(PSStation station) {
    setState(() {
      station.isRunning = true;
      station.isPaused = false;
    });
    station.fixedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (station.remaining.inSeconds <= 1) {
          station.remaining = Duration.zero;
          station.isRunning = false;
          station.fixedFinished = true;
          timer.cancel();
          SystemSound.play(SystemSoundType.alert);
          HapticFeedback.vibrate();
          _showTimeUpDialog(station);
        } else {
          station.remaining -= const Duration(seconds: 1);
        }
      });
    });
  }

  void cancelFixedSession(PSStation station) {
    station.fixedTimer?.cancel();
    setState(() {
      station.isRunning = false;
      station.isPaused = false;
      station.fixedFinished = false;
      station.remaining = Duration.zero;
    });
  }

  void toggleOpenSession(PSStation station) {
    if (station.isRunning) {
      station.openTimer?.cancel();
      setState(() => station.isRunning = false);
    } else {
      setState(() => station.isRunning = true);
      station.openTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          station.elapsed += const Duration(seconds: 1);
        });
      });
    }
  }

  void checkoutOpenSession(PSStation station) {
    station.openTimer?.cancel();
    final cost = station.elapsed.inSeconds * (psHourlyRate / 3600.0);
    final duration = station.elapsed;
    setState(() {
      psTotalRevenue += cost;
      station.elapsed = Duration.zero;
      station.isRunning = false;
    });
    _persist();
    _showSnack('تم تحصيل ${fmtMoney(cost)} من محطة ${station.number}');
    showReceiptDialog('فاتورة بلايستيشن - وقت مفتوح', [
      MapEntry('المحطة', '${station.number}'),
      MapEntry('المدة', fmtDuration(duration)),
      MapEntry('المبلغ', fmtMoney(cost)),
    ]);
  }

  // -------------------- WHATSAPP (بدون حزم خارجية) --------------------
  void sendWhatsAppReminder(Subscriber s) {
    final message =
        'مرحباً ${s.name}، نود تذكيركم بأن المبلغ المتبقي على اشتراككم هو ${s.remaining.toStringAsFixed(2)} ريال. يرجى التكرم بالسداد في أقرب وقت ممكن. شكراً لكم.';
    String phone = s.phone.trim();
    if (phone.isEmpty) {
      phone = '774113545';
    }
    phone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.startsWith('0')) phone = phone.substring(1);
    if (!phone.startsWith('967')) phone = '967$phone';
    final link = 'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تذكير واتساب'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('نص الرسالة:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              SelectableText(message),
              const SizedBox(height: 14),
              const Text('رابط واتساب:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              SelectableText(link, style: const TextStyle(fontSize: 12, color: Colors.blue)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: link));
              _showSnack('تم نسخ الرابط، افتحه في المتصفح أو الصقه في واتساب');
            },
            child: const Text('نسخ الرابط'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: message));
              _showSnack('تم نسخ نص الرسالة');
            },
            child: const Text('نسخ الرسالة فقط'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  // -------------------- BACKUP / EXPORT --------------------
  Map<String, dynamic> buildBackupJson() {
    return {
      'exportedAt': DateTime.now().toIso8601String(),
      'summary': {
        'إجمالي_البلايستيشن': psTotalRevenue,
        'إجمالي_البلياردو': billiardsTotal,
        'إجمالي_الجيم': gymTotal,
        'إجمالي_الفنون_القتالية': martialTotal,
        'إجمالي_المبيعات_الأخرى': salesTotal,
        'إجمالي_المداخيل': totalIncome,
        'إجمالي_المصاريف': expensesTotal,
        'إجمالي_السلف': advancesTotal,
        'الصافي_الفعلي': netCash,
      },
      'billiards': billiardsLog.map((e) => e.toJson()).toList(),
      'gymSubscribers': gymSubscribers.map((e) => e.toJson()).toList(),
      'gymVisits': gymVisits.map((e) => e.toJson()).toList(),
      'martialSubscribers': martialSubscribers.map((e) => e.toJson()).toList(),
      'martialVisits': martialVisits.map((e) => e.toJson()).toList(),
      'sales': sales.map((e) => e.toJson()).toList(),
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'advances': advances.map((e) => e.toJson()).toList(),
    };
  }

  void showBackupDialog() {
    final jsonStr = const JsonEncoder.withIndent('  ').convert(buildBackupJson());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تصدير نسخة احتياطية (JSON)'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(jsonStr, style: const TextStyle(fontSize: 12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              _showSnack('تم نسخ البيانات إلى الحافظة');
            },
            child: const Text('نسخ إلى الحافظة'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  void confirmCloseShift() {
    _requireManagerAuth('تقفيل الشفت النهائي', () {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تقفيل الشفت النهائي'),
          content: const Text(
            'سيتم أرشفة بيانات اليوم، ثم تصدير نسخة احتياطية، ثم إعادة تعيين جميع القيم إلى الصفر. هل تريد المتابعة؟',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final backup = buildBackupJson();
                await _archiveShift(backup);
                showBackupDialog();
                _resetShift();
              },
              child: const Text('تأكيد الإقفال'),
            ),
          ],
        ),
      );
    });
  }

  void _resetShift() {
    for (final s in stations) {
      s.fixedTimer?.cancel();
      s.openTimer?.cancel();
    }
    setState(() {
      for (var i = 0; i < stations.length; i++) {
        stations[i] = PSStation(i + 1);
      }
      psTotalRevenue = 0;
      billiardsLog.clear();
      gymVisits.clear();
      martialVisits.clear();
      sales.clear();
      expenses.clear();
      advances.clear();
      // ملاحظة: المشتركون (عقود شهرية/سنوية) لا يُمسحون عند تقفيل الشفت اليومي
    });
    _persist();
  }

  void showArchiveDialog() async {
    final archive = await _loadArchive();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('أرشيف الشفتات السابقة'),
        content: SizedBox(
          width: double.maxFinite,
          height: 420,
          child: archive.isEmpty
              ? const Center(child: Text('لا يوجد أرشيف بعد'))
              : ListView.separated(
                  itemCount: archive.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final item = archive[i];
                    final summary = item['summary'] as Map<String, dynamic>? ?? {};
                    final exportedAt = DateTime.tryParse(item['exportedAt'] as String? ?? '');
                    return ListTile(
                      leading: const Icon(Icons.receipt_long),
                      title: Text(exportedAt != null ? fmtDate(exportedAt) : 'شفت سابق'),
                      subtitle: Text('الصافي: ${(summary['الصافي_الفعلي'] as num?)?.toStringAsFixed(2) ?? '-'} ريال'),
                      onTap: () {
                        Navigator.pop(ctx);
                        showDialog(
                          context: context,
                          builder: (ctx2) => AlertDialog(
                            title: const Text('تفاصيل الشفت'),
                            content: SizedBox(
                              width: double.maxFinite,
                              height: 400,
                              child: SingleChildScrollView(
                                child: SelectableText(
                                  const JsonEncoder.withIndent('  ').convert(item),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('إغلاق')),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  // -------------------- SUBSCRIPTION EXPIRY --------------------
  List<MapEntry<Subscriber, String>> _expiringSoon() {
    final now = DateTime.now();
    final result = <MapEntry<Subscriber, String>>[];
    for (final s in gymSubscribers) {
      final diff = s.endDate.difference(now).inDays;
      if (diff <= 3) result.add(MapEntry(s, 'جيم'));
    }
    for (final s in martialSubscribers) {
      final diff = s.endDate.difference(now).inDays;
      if (diff <= 3) result.add(MapEntry(s, 'فنون قتالية'));
    }
    return result;
  }

  // ============================================================================
  // BUILD
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.role == UserRole.manager ? 'وضع المدير' : 'وضع الموظف',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
            Text('صافي كاش المحل اليوم: ${fmtMoney(netCash)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'تصدير نسخة احتياطية (JSON)',
            onPressed: showBackupDialog,
            icon: const Icon(Icons.backup),
          ),
          IconButton(
            tooltip: 'تقفيل الشفت النهائي',
            onPressed: confirmCloseShift,
            icon: const Icon(Icons.lock_clock),
          ),
          IconButton(
            tooltip: 'تسجيل الخروج',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.amberAccent,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'البلايستيشن'),
            Tab(text: 'البلياردو'),
            Tab(text: 'الجيم'),
            Tab(text: 'الفنون القتالية'),
            Tab(text: 'المبيعات الأخرى'),
            Tab(text: 'المصاريف والصرفيات'),
            Tab(text: 'حسابات العمال والسُلف'),
            Tab(text: 'لوحة المدير والإقفال'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPlayStationTab(),
          _buildBilliardsTab(),
          _buildSubscriptionSection(
            title: 'الجيم',
            subscribers: gymSubscribers,
            visits: gymVisits,
            subTabController: _gymSubTabController,
          ),
          _buildSubscriptionSection(
            title: 'الفنون القتالية',
            subscribers: martialSubscribers,
            visits: martialVisits,
            subTabController: _martialSubTabController,
          ),
          _buildSalesTab(),
          _buildExpensesTab(),
          _buildAdvancesTab(),
          _buildManagerDashboardTab(),
        ],
      ),
    );
  }

  // -------------------- HELPERS: UI --------------------
  Widget _sectionPadding(Widget child) => Padding(padding: const EdgeInsets.all(12), child: child);

  Widget _totalBanner(String label, double value, {Color? color}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: (color ?? Colors.teal).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (color ?? Colors.teal).withOpacity(0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text(fmtMoney(value),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color ?? Colors.teal[800])),
        ],
      ),
    );
  }

  // -------------------- 1) PLAYSTATION TAB --------------------
  Widget _buildPlayStationTab() {
    return Column(
      children: [
        TabBar(
          controller: _psSubTabController,
          labelColor: Colors.teal[800],
          tabs: const [
            Tab(text: 'وقت محدد'),
            Tab(text: 'وقت مفتوح'),
          ],
        ),
        _totalBanner('إجمالي دخل البلايستيشن', psTotalRevenue),
        Expanded(
          child: TabBarView(
            controller: _psSubTabController,
            children: [
              _buildFixedTimeGrid(),
              _buildOpenTimeGrid(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFixedTimeGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: stations.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.05,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, i) {
        final s = stations[i];
        final idle = !s.isRunning && !s.isPaused && !s.fixedFinished;
        return Card(
          color: s.fixedFinished
              ? Colors.red[50]
              : (s.isPaused ? Colors.amber[50] : (s.isRunning ? Colors.green[50] : Colors.white)),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('محطة ${s.number}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Text(
                  idle ? '00:00:00' : fmtDuration(s.remaining),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: s.fixedFinished ? Colors.red : Colors.black87,
                  ),
                ),
                if (s.fixedFinished) const Text('انتهى الوقت!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                if (s.isPaused) const Text('متوقف مؤقتاً', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (idle)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: [100, 200, 300, 400].map((amt) {
                      return SizedBox(
                        width: 58,
                        height: 32,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, textStyle: const TextStyle(fontSize: 11)),
                          onPressed: () => startFixedSession(s, amt.toDouble()),
                          child: Text('$amt ر.س'),
                        ),
                      );
                    }).toList(),
                  )
                else if (s.isRunning)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 32,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, textStyle: const TextStyle(fontSize: 11)),
                          onPressed: () => pauseFixedSession(s),
                          icon: const Icon(Icons.pause, size: 16),
                          label: const Text('إيقاف مؤقت'),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        height: 32,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: EdgeInsets.zero),
                          onPressed: () => cancelFixedSession(s),
                          icon: const Icon(Icons.stop, size: 16),
                          label: const Text('إلغاء'),
                        ),
                      ),
                    ],
                  )
                else if (s.isPaused)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 32,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, textStyle: const TextStyle(fontSize: 11)),
                          onPressed: () => resumeFixedSession(s),
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: const Text('استئناف'),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        height: 32,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: EdgeInsets.zero),
                          onPressed: () => cancelFixedSession(s),
                          icon: const Icon(Icons.stop, size: 16),
                          label: const Text('إلغاء'),
                        ),
                      ),
                    ],
                  ),
                if (s.fixedFinished)
                  TextButton(
                    onPressed: () => cancelFixedSession(s),
                    child: const Text('تصفير'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOpenTimeGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: stations.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.05,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, i) {
        final s = stations[i];
        final estimatedCost = s.elapsed.inSeconds * (psHourlyRate / 3600.0);
        return Card(
          color: s.isRunning ? Colors.blue[50] : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('محطة ${s.number}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Text(fmtDuration(s.elapsed), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text('التكلفة: ${estimatedCost.toStringAsFixed(1)} ر.س', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: s.isRunning ? Colors.orange : Colors.teal,
                          textStyle: const TextStyle(fontSize: 11),
                        ),
                        onPressed: () => toggleOpenSession(s),
                        child: Text(s.isRunning ? 'إيقاف مؤقت' : 'ابدأ'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, textStyle: const TextStyle(fontSize: 11)),
                        onPressed: s.elapsed.inSeconds > 0 ? () => checkoutOpenSession(s) : null,
                        child: const Text('محاسبة'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------- 2) BILLIARDS TAB --------------------
  Widget _buildBilliardsTab() {
    return _sectionPadding(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _totalBanner('إجمالي توريد البلياردو', billiardsTotal),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('توريد نقدي (عاصم)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: billiardsAmountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'المبلغ (ريال)'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: billiardsSelectedHour,
                    decoration: const InputDecoration(labelText: 'الساعة'),
                    items: List.generate(24, (h) => h)
                        .map((h) => DropdownMenuItem(value: h, child: Text('الساعة $h:00')))
                        .toList(),
                    onChanged: (v) => setState(() => billiardsSelectedHour = v ?? billiardsSelectedHour),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      final amt = double.tryParse(billiardsAmountCtrl.text.trim());
                      if (amt == null || amt <= 0) {
                        _showSnack('الرجاء إدخال مبلغ صحيح');
                        return;
                      }
                      setState(() {
                        billiardsLog.insert(
                          0,
                          BilliardsEntry(amount: amt, hour: billiardsSelectedHour, time: DateTime.now()),
                        );
                        billiardsAmountCtrl.clear();
                      });
                      _persist();
                    },
                    child: const Text('تسجيل التوريد من عاصم'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('سجل التوريدات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          Expanded(
            child: billiardsLog.isEmpty
                ? const Center(child: Text('لا توجد توريدات مسجلة'))
                : ListView.separated(
                    itemCount: billiardsLog.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final e = billiardsLog[i];
                      return ListTile(
                        leading: const Icon(Icons.sports_bar),
                        title: Text('${fmtMoney(e.amount)}  —  الساعة ${e.hour}:00'),
                        subtitle: Text('عدد المباريات: ${e.matches.toStringAsFixed(1)}  |  الوقت: ${fmtTime(e.time)}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // -------------------- 3/4) GYM & MARTIAL ARTS (shared) --------------------
  Widget _buildSubscriptionSection({
    required String title,
    required List<Subscriber> subscribers,
    required List<VisitEntry> visits,
    required TabController subTabController,
  }) {
    return Column(
      children: [
        TabBar(
          controller: subTabController,
          labelColor: Colors.teal[800],
          tabs: const [
            Tab(text: 'المشتركين'),
            Tab(text: 'الدخول اليومي'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: subTabController,
            children: [
              _buildSubscribersList(subscribers, title),
              _buildDailyVisits(visits, title),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubscribersList(List<Subscriber> list, String sectionTitle) {
    final total = list.fold<double>(0, (s, e) => s + e.paid);
    return _sectionPadding(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _totalBanner('إجمالي اشتراكات $sectionTitle', total),
          ElevatedButton.icon(
            icon: const Icon(Icons.person_add),
            label: const Text('إضافة مشترك جديد'),
            onPressed: () => _showAddSubscriberDialog(list),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('لا يوجد مشتركون بعد'))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final sub = list[i];
                      final hasDebt = sub.remaining > 0;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () => _requireManagerAuth(
                                      'حذف مشترك',
                                      () {
                                        setState(() => list.remove(sub));
                                        _persist();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              Text('الهاتف: ${sub.phone}'),
                              Text('المدفوع: ${fmtMoney(sub.paid)}  |  المتبقي: ${fmtMoney(sub.remaining)}',
                                  style: TextStyle(color: hasDebt ? Colors.red : Colors.green[700], fontWeight: FontWeight.bold)),
                              Text('المدة: ${sub.duration}   |   من ${fmtDate(sub.startDate)} إلى ${fmtDate(sub.endDate)}'),
                              const SizedBox(height: 8),
                              if (hasDebt)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                                    onPressed: () => sendWhatsAppReminder(sub),
                                    icon: const Icon(Icons.chat, size: 18),
                                    label: const Text('تذكير عبر واتساب'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddSubscriberDialog(List<Subscriber> targetList) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final paidCtrl = TextEditingController();
    final remainingCtrl = TextEditingController(text: '0');
    String duration = 'شهر';
    DateTime startDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('إضافة مشترك جديد'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم')),
                    const SizedBox(height: 8),
                    TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
                    const SizedBox(height: 8),
                    TextField(controller: paidCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ المدفوع')),
                    const SizedBox(height: 8),
                    TextField(controller: remainingCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ المتبقي')),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: duration,
                      decoration: const InputDecoration(labelText: 'مدة الاشتراك'),
                      items: const [
                        DropdownMenuItem(value: 'شهر', child: Text('شهر')),
                        DropdownMenuItem(value: '3 أشهر', child: Text('3 أشهر')),
                        DropdownMenuItem(value: 'سنوي', child: Text('سنوي')),
                      ],
                      onChanged: (v) => setDialogState(() => duration = v ?? duration),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: Text('تاريخ البدء: ${startDate.toString().split(" ")[0]}')),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) setDialogState(() => startDate = picked);
                          },
                          child: const Text('تغيير'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) {
                      _showSnack('الرجاء إدخال اسم المشترك');
                      return;
                    }
                    final paid = double.tryParse(paidCtrl.text.trim()) ?? 0;
                    final remaining = double.tryParse(remainingCtrl.text.trim()) ?? 0;
                    DateTime end;
                    switch (duration) {
                      case '3 أشهر':
                        end = DateTime(startDate.year, startDate.month + 3, startDate.day);
                        break;
                      case 'سنوي':
                        end = DateTime(startDate.year + 1, startDate.month, startDate.day);
                        break;
                      default:
                        end = DateTime(startDate.year, startDate.month + 1, startDate.day);
                    }
                    setState(() {
                      targetList.add(Subscriber(
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        paid: paid,
                        remaining: remaining,
                        startDate: startDate,
                        endDate: end,
                        duration: duration,
                      ));
                    });
                    _persist();
                    Navigator.pop(ctx);
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDailyVisits(List<VisitEntry> visits, String sectionTitle) {
    final visitAmountCtrl = TextEditingController();
    final total = visits.fold<double>(0, (s, e) => s + e.amount);
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return _sectionPadding(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _totalBanner('إجمالي دخول $sectionTitle اليومي', total),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: visitAmountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'قيمة الدخول (ريال)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          final amt = double.tryParse(visitAmountCtrl.text.trim());
                          if (amt == null || amt <= 0) {
                            _showSnack('الرجاء إدخال مبلغ صحيح');
                            return;
                          }
                          setState(() {
                            visits.insert(0, VisitEntry(amount: amt, time: DateTime.now()));
                          });
                          _persist();
                          visitAmountCtrl.clear();
                          setLocalState(() {});
                        },
                        child: const Text('تسجيل دخول'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('عدد الزيارات اليوم: ${visits.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Expanded(
                child: visits.isEmpty
                    ? const Center(child: Text('لا توجد زيارات مسجلة بعد'))
                    : ListView.separated(
                        itemCount: visits.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final v = visits[i];
                          return ListTile(
                            leading: const Icon(Icons.login),
                            title: Text(fmtMoney(v.amount)),
                            subtitle: Text(fmtTime(v.time)),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------- 5) OTHER SALES TAB --------------------
  Widget _buildSalesTab() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return _sectionPadding(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _totalBanner('إجمالي المبيعات الأخرى', salesTotal),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('تسجيل عملية بيع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 10),
                      TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الصنف (ماء، مشروب طاقة، قفازات...)')),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: priceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'السعر'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: qtyCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'الكمية'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          final name = nameCtrl.text.trim();
                          final price = double.tryParse(priceCtrl.text.trim());
                          final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;
                          if (name.isEmpty || price == null || price <= 0 || qty <= 0) {
                            _showSnack('الرجاء تعبئة جميع الحقول بشكل صحيح');
                            return;
                          }
                          setState(() {
                            sales.insert(0, SaleItem(name: name, price: price, qty: qty, time: DateTime.now()));
                          });
                          _persist();
                          nameCtrl.clear();
                          priceCtrl.clear();
                          qtyCtrl.text = '1';
                          setLocalState(() {});
                        },
                        child: const Text('تسجيل عملية بيع'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('سجل المبيعات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 6),
              Expanded(
                child: sales.isEmpty
                    ? const Center(child: Text('لا توجد مبيعات مسجلة'))
                    : ListView.separated(
                        itemCount: sales.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final s = sales[i];
                          return ListTile(
                            leading: const Icon(Icons.shopping_bag_outlined),
                            title: Text('${s.name}  ×${s.qty}'),
                            subtitle: Text('${fmtTime(s.time)}  |  السعر: ${fmtMoney(s.price)}'),
                            trailing: Text(fmtMoney(s.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------- 6) EXPENSES TAB --------------------
  Widget _buildExpensesTab() {
    final descCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return _sectionPadding(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _totalBanner('إجمالي المصاريف والصرفيات', expensesTotal, color: Colors.deepOrange),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('تسجيل مصروف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 10),
                      TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'الوصف / الصنف المشترى (صيانة، مواد تنظيف، فواتير...)')),
                      const SizedBox(height: 8),
                      TextField(controller: amtCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ المسحوب')),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                        onPressed: () {
                          final desc = descCtrl.text.trim();
                          final amt = double.tryParse(amtCtrl.text.trim());
                          if (desc.isEmpty || amt == null || amt <= 0) {
                            _showSnack('الرجاء تعبئة جميع الحقول بشكل صحيح');
                            return;
                          }
                          setState(() {
                            expenses.insert(0, ExpenseItem(description: desc, amount: amt, time: DateTime.now()));
                          });
                          _persist();
                          descCtrl.clear();
                          amtCtrl.clear();
                          setLocalState(() {});
                        },
                        child: const Text('تسجيل مصروف'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('سجل المصاريف اليومي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 6),
              Expanded(
                child: expenses.isEmpty
                    ? const Center(child: Text('لا توجد مصاريف مسجلة'))
                    : ListView.separated(
                        itemCount: expenses.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final e = expenses[i];
                          return ListTile(
                            leading: const Icon(Icons.money_off),
                            title: Text(e.description),
                            subtitle: Text(fmtTime(e.time)),
                            trailing: Text('- ${fmtMoney(e.amount)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------- 7) EMPLOYEE ADVANCES TAB --------------------
  Widget _buildAdvancesTab() {
    String selectedWorker = workers.first;
    final amtCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    return StatefulBuilder(
      builder: (context, setLocalState) {
        final Map<String, double> perWorkerTotals = {
          for (final w in workers) w: advances.where((a) => a.worker == w).fold(0.0, (s, a) => s + a.amount),
        };
        return _sectionPadding(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _totalBanner('إجمالي سُلف العمال', advancesTotal, color: Colors.indigo),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('تسجيل سلفة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: selectedWorker,
                        decoration: const InputDecoration(labelText: 'اسم العامل'),
                        items: workers.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                        onChanged: (v) => setLocalState(() => selectedWorker = v ?? selectedWorker),
                      ),
                      const SizedBox(height: 8),
                      TextField(controller: amtCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مبلغ السلفة')),
                      const SizedBox(height: 8),
                      TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'السبب')),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                        onPressed: () {
                          final amt = double.tryParse(amtCtrl.text.trim());
                          if (amt == null || amt <= 0) {
                            _showSnack('الرجاء إدخال مبلغ صحيح');
                            return;
                          }
                          setState(() {
                            advances.insert(
                              0,
                              AdvanceItem(
                                worker: selectedWorker,
                                amount: amt,
                                reason: reasonCtrl.text.trim().isEmpty ? 'غير محدد' : reasonCtrl.text.trim(),
                                time: DateTime.now(),
                              ),
                            );
                          });
                          _persist();
                          amtCtrl.clear();
                          reasonCtrl.clear();
                          setLocalState(() {});
                        },
                        child: const Text('تسجيل السلفة'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('كشف حساب العمال', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 6),
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: workers.map((w) {
                    return Container(
                      width: 140,
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(w, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(fmtMoney(perWorkerTotals[w] ?? 0)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              const Text('سجل السُلف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 6),
              Expanded(
                child: advances.isEmpty
                    ? const Center(child: Text('لا توجد سُلف مسجلة'))
                    : ListView.separated(
                        itemCount: advances.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final a = advances[i];
                          return ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: Text('${a.worker}  —  ${a.reason}'),
                            subtitle: Text(fmtTime(a.time)),
                            trailing: Text('- ${fmtMoney(a.amount)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------- 8) MANAGER DASHBOARD TAB --------------------
  Widget _buildManagerDashboardTab() {
    final expiring = _expiringSoon();
    return _sectionPadding(
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (expiring.isNotEmpty)
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.warning_amber, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('اشتراكات قاربت على الانتهاء أو منتهية', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...expiring.map((e) {
                        final s = e.key;
                        final days = s.endDate.difference(DateTime.now()).inDays;
                        final status = days < 0 ? 'منتهي منذ ${-days} يوم' : (days == 0 ? 'ينتهي اليوم' : 'يتبقى $days يوم');
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text('${s.name} (${e.value}) — $status'),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            if (expiring.isNotEmpty) const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('الملخص المالي التفصيلي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const Divider(height: 20),
                    _summaryRow('البلايستيشن', psTotalRevenue),
                    _summaryRow('البلياردو', billiardsTotal),
                    _summaryRow('الجيم', gymTotal),
                    _summaryRow('الفنون القتالية', martialTotal),
                    _summaryRow('المبيعات الأخرى', salesTotal),
                    const Divider(height: 20),
                    _summaryRow('(+) إجمالي المداخيل', totalIncome, bold: true, color: Colors.green[800]),
                    _summaryRow('(-) إجمالي المصاريف والصرفيات', expensesTotal, bold: true, color: Colors.deepOrange),
                    _summaryRow('(-) إجمالي سُلف العمال', advancesTotal, bold: true, color: Colors.indigo),
                    const Divider(height: 20, thickness: 1.5),
                    _summaryRow('(=) الصافي الفعلي المطابق للكاش في الخزينة', netCash, bold: true, big: true, color: Colors.teal[900]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.backup),
                    label: const Text('تصدير نسخة احتياطية (JSON)'),
                    onPressed: showBackupDialog,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                    icon: const Icon(Icons.history),
                    label: const Text('أرشيف الشفتات'),
                    onPressed: showArchiveDialog,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              icon: const Icon(Icons.restart_alt),
              label: const Text('تقفيل الشفت وتصفيره'),
              onPressed: confirmCloseShift,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool bold = false, bool big = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: big ? 16 : 14, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(
            fmtMoney(value),
            style: TextStyle(
              fontSize: big ? 18 : 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}