import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import 'look_up_angle_screen.dart';
import 'loss_calculator_screen.dart';

class DashboardScreen extends StatefulWidget {
  static const String routeName = '/dashboard';
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String userName = "";
  String userEmail = "";
  String userImage = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // LOAD USER DATA
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;
    setState(() {
      userName = prefs.getString('name') ?? "VSAT User";
      userEmail = prefs.getString('email') ?? "user@vsat.com";
      userImage = prefs.getString('image') ?? "";
    });
  }

  // Dashboard → Splash → Login
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    try {
      await GoogleSignIn().signOut();
    } catch (_) {}

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 16, 47, 132),
        elevation: 0,
        title: const Text(
          "VSAT Saarthi",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      userImage.isNotEmpty ? NetworkImage(userImage) : null,
                  child: userImage.isEmpty
                      ? const Icon(Icons.person, color: Colors.black)
                      : null,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),

      // RIGHT SIDE PROFILE DRAWER
      endDrawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.75,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),

              CircleAvatar(
                radius: 55,
                backgroundColor: const Color(0xFFE5EDFF),
                backgroundImage:
                    userImage.isNotEmpty ? NetworkImage(userImage) : null,
                child: userImage.isEmpty
                    ? const Icon(
                        Icons.person,
                        size: 60,
                        color: Color(0xFF1E3A8A),
                      )
                    : null,
              ),

              const SizedBox(height: 16),

              Text(
                userName,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                userEmail,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  color: AppColors.textLight,
                ),
              ),

              const SizedBox(height: 30),
              const Divider(),

              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text("Settings"),
                onTap: () {},
              ),

              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text("Help & Support"),
                onTap: () {},
              ),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),

      body: const _DashboardTabs(),
    );
  }
}

class _DashboardTabs extends StatefulWidget {
  const _DashboardTabs();

  @override
  State<_DashboardTabs> createState() => _DashboardTabsState();
}

class _DashboardTabsState extends State<_DashboardTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF1D4ED8),
            unselectedLabelColor: Colors.black54,
            indicatorColor: const Color(0xFF1D4ED8),
            tabs: const [
              Tab(text: "Look Up Angle"),
              Tab(text: "Loss Calculator"),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              LookUpAngleScreen(),
              LossCalculatorScreen(),
            ],
          ),
        ),
      ],
    );
  }
}