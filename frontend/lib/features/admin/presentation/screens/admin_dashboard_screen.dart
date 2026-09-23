import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';
import '../../domain/admin_models.dart';
import '../../../../shared/widgets/sahyan_logo.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  // Theme Color Tokens: Professional Deep Blue & Slate
  static const Color _bgCanvas = Color(0xFF0F172A);
  static const Color _sidebarBg = Color(0xFF1E293B);
  static const Color _cardBg = Color(0xFF1E293B);
  static const Color _cardBorder = Color(0xFF334155);
  static const Color _accentBlue = Color(0xFF2563EB);
  static const Color _accentMint = Color(0xFF2EC486);
  static const Color _urgentCoral = Color(0xFFEF4444);
  static const Color _textMain = Color(0xFFF8FAFC);
  static const Color _textMuted = Color(0xFF94A3B8);

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);
    final notifier = ref.read(adminProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Scaffold(
          backgroundColor: _bgCanvas,
          appBar: isDesktop
              ? null
              : AppBar(
                  backgroundColor: _sidebarBg,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: _textMain),
                  title: const Row(
                    children: [
                      SahyanLogo(
                        variant: SahyanLogoVariant.symbolOnly,
                        size: 22,
                        theme: SahyanLogoTheme.monochromeWhite,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Sahyān Admin',
                        style: TextStyle(
                          color: _textMain,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: _textMuted),
                      tooltip: 'Refresh',
                      onPressed: () => notifier.loadAll(),
                    ),
                  ],
                ),
          drawer: isDesktop ? null : Drawer(child: _buildSidebar(state, notifier)),
          body: Row(
            children: [
              if (isDesktop)
                SizedBox(
                  width: 250,
                  child: _buildSidebar(state, notifier),
                ),
              Expanded(
                child: Column(
                  children: [
                    if (isDesktop) _buildTopHeader(state, notifier),
                    Expanded(
                      child: state.isLoading && state.verifications.isEmpty && state.rides.isEmpty
                          ? const Center(
                              child: CircularProgressIndicator(color: _accentMint),
                            )
                          : _buildActiveTabContent(state, notifier),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopHeader(AdminState state, AdminNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: _sidebarBg,
        border: Border(
          bottom: BorderSide(color: _cardBorder, width: 0.8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _accentMint.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _accentMint.withValues(alpha: 0.3), width: 0.8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: _accentMint, size: 8),
                      SizedBox(width: 6),
                      Text(
                        'MongoDB Connected · API v1.0.0',
                        style: TextStyle(
                          color: _accentMint,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _accentBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _accentBlue.withValues(alpha: 0.3), width: 0.8),
                    ),
                    child: const Text(
                      'Production Mesh',
                      style: TextStyle(
                        color: Color(0xFF93C5FD),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: _textMuted, size: 20),
                tooltip: 'Refresh Data',
                onPressed: () => notifier.loadAll(),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _cardBorder, width: 0.8),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: _textMain, size: 20),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SuperAdmin',
                    style: TextStyle(color: _textMain, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  Text(
                    'Root Clearance',
                    style: TextStyle(color: _textMuted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(AdminState state, AdminNotifier notifier) {
    return Container(
      color: _sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Platform Brand Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _accentMint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: SahyanLogo(
                      variant: SahyanLogoVariant.symbolOnly,
                      size: 24,
                      theme: SahyanLogoTheme.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SAHYĀN',
                        style: TextStyle(
                          color: _textMain,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'ADMIN OS · MODERATION',
                        style: TextStyle(
                          color: _accentMint,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                          letterSpacing: 0.8,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: _cardBorder, height: 1),
          const SizedBox(height: 12),

          // Sidebar Navigation Tabs
          _buildSidebarNavItem(
            title: 'Overview & Stats',
            icon: Icons.dashboard_rounded,
            tab: AdminTab.overview,
            currentTab: state.selectedTab,
            onTap: () => notifier.setTab(AdminTab.overview),
          ),
          _buildSidebarNavItem(
            title: 'Driver Verifications',
            icon: Icons.verified_user_rounded,
            tab: AdminTab.verifications,
            currentTab: state.selectedTab,
            badgeCount: state.stats.pendingVerifications > 0 ? state.stats.pendingVerifications : null,
            badgeColor: _accentMint,
            onTap: () => notifier.setTab(AdminTab.verifications),
          ),
          _buildSidebarNavItem(
            title: 'Ride Moderation',
            icon: Icons.route_rounded,
            tab: AdminTab.rides,
            currentTab: state.selectedTab,
            badgeCount: state.stats.activeJourneys > 0 ? state.stats.activeJourneys : null,
            badgeColor: _accentBlue,
            onTap: () => notifier.setTab(AdminTab.rides),
          ),
          _buildSidebarNavItem(
            title: 'Safety & Reports',
            icon: Icons.security_rounded,
            tab: AdminTab.reports,
            currentTab: state.selectedTab,
            badgeCount: state.stats.openReports > 0 ? state.stats.openReports : null,
            badgeColor: _urgentCoral,
            onTap: () => notifier.setTab(AdminTab.reports),
          ),
          _buildSidebarNavItem(
            title: 'System Settings',
            icon: Icons.settings_suggest_rounded,
            tab: AdminTab.settings,
            currentTab: state.selectedTab,
            onTap: () => notifier.setTab(AdminTab.settings),
          ),

          const Spacer(),
          const Divider(color: _cardBorder, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Sahyān Carpool v1.0.0-p5\nGujarat State Highway Mesh',
              style: TextStyle(color: _textMuted.withValues(alpha: 0.7), fontSize: 11, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem({
    required String title,
    required IconData icon,
    required AdminTab tab,
    required AdminTab currentTab,
    required VoidCallback onTap,
    int? badgeCount,
    Color? badgeColor,
  }) {
    final isSelected = tab == currentTab;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: isSelected ? _accentBlue.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: isSelected ? Border.all(color: _accentBlue.withValues(alpha: 0.4), width: 0.8) : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? const Color(0xFF60A5FA) : _textMuted,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? _textMain : _textMuted,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (badgeCount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor ?? _accentMint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: _bgCanvas,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(AdminState state, AdminNotifier notifier) {
    switch (state.selectedTab) {
      case AdminTab.overview:
        return _buildOverviewTab(state, notifier);
      case AdminTab.verifications:
        return _buildVerificationsTab(state, notifier);
      case AdminTab.rides:
        return _buildRidesTab(state, notifier);
      case AdminTab.reports:
        return _buildReportsTab(state, notifier);
      case AdminTab.settings:
        return _buildSettingsTab(state, notifier);
    }
  }

  // TAB 1: OVERVIEW & BENTO METRIC ANALYTICS
  Widget _buildOverviewTab(AdminState state, AdminNotifier notifier) {
    final stats = state.stats;
    final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isMobile) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Platform Overview',
                        style: TextStyle(
                          color: _textMain,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Real-time corridor telemetry, fleet metrics, and community safety stats.',
                        style: TextStyle(color: _textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentMint,
                          foregroundColor: _bgCanvas,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.verified_user_rounded, size: 16),
                        label: Text(
                          'Review Queue (${stats.pendingVerifications})',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onPressed: () => notifier.setTab(AdminTab.verifications),
                      ),
                    ],
                  ),
                ] else ...[
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Platform Overview',
                            style: TextStyle(
                              color: _textMain,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Real-time corridor telemetry, fleet metrics, and community safety stats.',
                            style: TextStyle(color: _textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentMint,
                          foregroundColor: _bgCanvas,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.verified_user_rounded, size: 16),
                        label: Text(
                          'Review Queue (${stats.pendingVerifications})',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onPressed: () => notifier.setTab(AdminTab.verifications),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),

          // Bento Metric Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 1000 ? 4 : (constraints.maxWidth >= 600 ? 2 : 1);

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.45,
                children: [
                  _buildMetricCard(
                    title: 'COMMUNITY MEMBERS',
                    value: '${stats.totalUsers}',
                    subtitle: 'Active passengers & commuters',
                    icon: Icons.people_alt_rounded,
                    accentColor: const Color(0xFF38BDF8),
                  ),
                  _buildMetricCard(
                    title: 'VERIFIED FLEET DRIVERS',
                    value: '${stats.verifiedDrivers}',
                    subtitle: '${stats.pendingVerifications} in verification queue',
                    icon: Icons.directions_car_filled_rounded,
                    accentColor: _accentMint,
                  ),
                  _buildMetricCard(
                    title: 'ACTIVE CORRIDORS & TRIPS',
                    value: '${stats.activeJourneys}',
                    subtitle: '${stats.scheduledRides} scheduled today',
                    icon: Icons.alt_route_rounded,
                    accentColor: _accentBlue,
                  ),
                  _buildMetricCard(
                    title: 'ENVIRONMENTAL IMPACT',
                    value: '${stats.totalCo2SavedKg} kg',
                    subtitle: '${currencyFormatter.format(stats.totalFuelSplit)} fuel cost shared',
                    icon: Icons.eco_rounded,
                    accentColor: const Color(0xFF34D399),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // Secondary Telemetry Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 850;

              final healthCard = Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _cardBorder, width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.monitor_heart_rounded, color: _accentMint, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Corridor Operating Health',
                            style: TextStyle(color: _textMain, fontWeight: FontWeight.w700, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildHealthRow('MongoDB High Availability Replica', 'Online · Primary (127.0.0.1:27017)'),
                    _buildHealthRow('Directions & Polyline Routing Engine', 'Operational · Normal Quota'),
                    _buildHealthRow('Push Notifications & Messaging Relay', 'Active · 0.05ms Latency'),
                    _buildHealthRow('Automated Safety & SOS Dispatch', 'Ready · Highway Police Ring 112'),
                  ],
                ),
              );

              final incidentCard = Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _cardBorder, width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Incident Logs',
                      style: TextStyle(color: _textMain, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    if (state.reports.isEmpty)
                      const Text('No unresolved safety incidents.', style: TextStyle(color: _textMuted))
                    else
                      ...state.reports.take(3).map(
                            (r) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: r.severity == 'critical' ? _urgentCoral : Colors.amber,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          r.title,
                                          style: const TextStyle(color: _textMain, fontSize: 12, fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${r.reporterName} • ${DateFormat('hh:mm a').format(r.createdAt)}',
                                          style: const TextStyle(color: _textMuted, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ],
                ),
              );

              if (isNarrow) {
                return Column(
                  children: [
                    healthCard,
                    const SizedBox(height: 16),
                    incidentCard,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: healthCard),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: incidentCard),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
},
);
}

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: _textMain,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: _textMuted.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthRow(String title, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: _textMuted, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              status,
              textAlign: TextAlign.end,
              style: const TextStyle(color: _textMain, fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // TAB 2: DRIVER VERIFICATION QUEUE
  Widget _buildVerificationsTab(AdminState state, AdminNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, headerConstraints) {
              final isMobile = headerConstraints.maxWidth < 700;
              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Driver Verification Queue',
                      style: TextStyle(color: _textMain, fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Review submitted licenses and vehicle registration documents before granting driver privileges.',
                      style: TextStyle(color: _textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 38,
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: _textMain, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search applicant, phone, or plate...',
                          hintStyle: const TextStyle(color: _textMuted, fontSize: 12),
                          prefixIcon: const Icon(Icons.search_rounded, color: _textMuted, size: 18),
                          filled: true,
                          fillColor: _cardBg,
                          contentPadding: EdgeInsets.zero,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: _cardBorder, width: 0.8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: _accentBlue, width: 1.2),
                          ),
                        ),
                        onSubmitted: (val) => notifier.setSearchQuery(val.trim()),
                      ),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Driver Verification Queue',
                          style: TextStyle(color: _textMain, fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Review submitted licenses and vehicle registration documents before granting driver privileges.',
                          style: TextStyle(color: _textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 260,
                    height: 38,
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: _textMain, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search applicant, phone, or plate...',
                        hintStyle: const TextStyle(color: _textMuted, fontSize: 12),
                        prefixIcon: const Icon(Icons.search_rounded, color: _textMuted, size: 18),
                        filled: true,
                        fillColor: _cardBg,
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _cardBorder, width: 0.8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _accentBlue, width: 1.2),
                        ),
                      ),
                      onSubmitted: (val) => notifier.setSearchQuery(val.trim()),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all', state.verificationFilter, (f) => notifier.setVerificationFilter(f)),
                const SizedBox(width: 8),
                _buildFilterChip('Pending Review', 'pending', state.verificationFilter, (f) => notifier.setVerificationFilter(f)),
                const SizedBox(width: 8),
                _buildFilterChip('Verified', 'verified', state.verificationFilter, (f) => notifier.setVerificationFilter(f)),
                const SizedBox(width: 8),
                _buildFilterChip('Rejected', 'rejected', state.verificationFilter, (f) => notifier.setVerificationFilter(f)),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Verification Table List
          Expanded(
            child: state.verifications.isEmpty
                ? const Center(
                    child: Text('No applicants found matching filter criteria.', style: TextStyle(color: _textMuted)),
                  )
                : ListView.builder(
                    itemCount: state.verifications.length,
                    itemBuilder: (context, index) {
                      final item = state.verifications[index];
                      return _buildVerificationCard(item, notifier);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String activeValue, Function(String) onSelect) {
    final isActive = value == activeValue;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? _accentBlue : _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? _accentBlue : _cardBorder, width: 0.8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : _textMuted,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationCard(DriverVerificationItem item, AdminNotifier notifier) {
    final statusColor = item.onboardingStatus == 'approved'
        ? _accentMint
        : (item.onboardingStatus == 'rejected' ? _urgentCoral : const Color(0xFFF59E0B));

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundColor: _accentBlue.withValues(alpha: 0.2),
                    radius: 20,
                    child: Text(
                      item.name.isNotEmpty ? item.name[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Color(0xFF93C5FD), fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(color: _textMain, fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              item.onboardingStatus.toUpperCase(),
                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.phone} • ${item.email}',
                        style: const TextStyle(color: _textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF93C5FD),
                      side: const BorderSide(color: _cardBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.description_outlined, size: 14),
                    label: const Text('View Docs', style: TextStyle(fontSize: 12)),
                    onPressed: () => _showDocumentModal(item),
                  ),
                  const SizedBox(width: 10),
                  if (item.onboardingStatus == 'submitted' || item.onboardingStatus == 'rejected')
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentMint,
                        foregroundColor: _bgCanvas,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        final ok = await notifier.approveDriver(item.id);
                        if (ok && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Approved ${item.name} as verified fleet driver.')),
                          );
                        }
                      },
                      child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                  if (item.onboardingStatus == 'submitted' || item.onboardingStatus == 'approved') ...[
                    const SizedBox(width: 8),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: _urgentCoral,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onPressed: () => _showRejectionDialog(item, notifier),
                      child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _bgCanvas,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _cardBorder, width: 0.6),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 6,
              children: [
                Text(
                  'Vehicle: ${item.vehicleMake ?? "Hyundai"} ${item.vehicleModel ?? "Creta"} (Plate: ${item.vehiclePlate ?? "GJ-01-AB-1234"})',
                  style: const TextStyle(color: _textMain, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  'DL: ${item.licenseNumber.isNotEmpty ? item.licenseNumber : "GJ01-2023-009844"}',
                  style: const TextStyle(color: _textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDocumentModal(DriverVerificationItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.document_scanner_rounded, color: _accentMint, size: 20),
            const SizedBox(width: 10),
            Text('Verification Docs: ${item.name}', style: const TextStyle(color: _textMain, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Driving License (Smart Card RC)', style: TextStyle(color: _textMuted, fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _bgCanvas,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _cardBorder),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.badge_rounded, color: _accentBlue, size: 40),
                      const SizedBox(height: 8),
                      Text('Driving License: ${item.licenseNumber}', style: const TextStyle(color: _textMain, fontSize: 12)),
                      const Text('Verified by DigiLocker National Registry', style: TextStyle(color: _accentMint, fontSize: 10)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Vehicle Registration (RC)', style: TextStyle(color: _textMuted, fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _bgCanvas,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _cardBorder),
                ),
                child: Center(
                  child: Text(
                    'Plate: ${item.vehiclePlate ?? "GJ-01-AB-1234"} · ${item.vehicleMake ?? "Hyundai"}',
                    style: const TextStyle(color: _textMain, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: _textMuted)),
          ),
        ],
      ),
    );
  }

  void _showRejectionDialog(DriverVerificationItem item, AdminNotifier notifier) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject Application: ${item.name}', style: const TextStyle(color: _textMain, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please provide a constructive reason for the driver. This feedback will be sent in their notification inbox.',
              style: TextStyle(color: _textMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: _textMain, fontSize: 13),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. License photo was blurry or plate number mismatch.',
                hintStyle: const TextStyle(color: _textMuted, fontSize: 12),
                filled: true,
                fillColor: _bgCanvas,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: _textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _urgentCoral,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final reason = reasonController.text.trim();
              Navigator.of(ctx).pop();
              final ok = await notifier.rejectDriver(item.id, reason.isNotEmpty ? reason : 'Documentation check failed.');
              if (ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Marked ${item.name} as rejected.')),
                );
              }
            },
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );
  }

  // TAB 3: RIDE MODERATION
  Widget _buildRidesTab(AdminState state, AdminNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, headerConstraints) {
              final isMobile = headerConstraints.maxWidth < 700;
              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ride Moderation Console', style: TextStyle(color: _textMain, fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('Monitor active, boarding, and scheduled intercity highway carpool corridors.', style: TextStyle(color: _textMuted, fontSize: 13)),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All', 'all', state.rideFilter, (f) => notifier.setRideFilter(f)),
                          const SizedBox(width: 6),
                          _buildFilterChip('Scheduled', 'scheduled', state.rideFilter, (f) => notifier.setRideFilter(f)),
                          const SizedBox(width: 6),
                          _buildFilterChip('Boarding', 'boarding', state.rideFilter, (f) => notifier.setRideFilter(f)),
                          const SizedBox(width: 6),
                          _buildFilterChip('Cancelled', 'cancelled', state.rideFilter, (f) => notifier.setRideFilter(f)),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ride Moderation Console', style: TextStyle(color: _textMain, fontSize: 22, fontWeight: FontWeight.w800)),
                        SizedBox(height: 4),
                        Text('Monitor active, boarding, and scheduled intercity highway carpool corridors.', style: TextStyle(color: _textMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      _buildFilterChip('All', 'all', state.rideFilter, (f) => notifier.setRideFilter(f)),
                      const SizedBox(width: 6),
                      _buildFilterChip('Scheduled', 'scheduled', state.rideFilter, (f) => notifier.setRideFilter(f)),
                      const SizedBox(width: 6),
                      _buildFilterChip('Boarding', 'boarding', state.rideFilter, (f) => notifier.setRideFilter(f)),
                      const SizedBox(width: 6),
                      _buildFilterChip('Cancelled', 'cancelled', state.rideFilter, (f) => notifier.setRideFilter(f)),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Expanded(
            child: state.rides.isEmpty
                ? const Center(child: Text('No rides found in this corridor category.', style: TextStyle(color: _textMuted)))
                : ListView.builder(
                    itemCount: state.rides.length,
                    itemBuilder: (context, index) {
                      final ride = state.rides[index];
                      return _buildRideCard(ride, notifier);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(AdminRideItem ride, AdminNotifier notifier) {
    final isCancelled = ride.status == 'cancelled';
    final statusColor = ride.status == 'boarding'
        ? _accentMint
        : (ride.status == 'scheduled' ? _accentBlue : (isCancelled ? _urgentCoral : Colors.grey));

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.navigation_outlined, color: statusColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${ride.originName} → ${ride.destinationName}',
                    style: const TextStyle(color: _textMain, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ride.status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              if (!isCancelled)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _urgentCoral.withValues(alpha: 0.15),
                    foregroundColor: _urgentCoral,
                    side: const BorderSide(color: _urgentCoral, width: 0.8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 14),
                  label: const Text('Cancel Ride', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  onPressed: () => _showCancelRideDialog(ride, notifier),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _urgentCoral.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Cancelled by Moderation', style: TextStyle(color: _urgentCoral, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _bgCanvas,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _cardBorder, width: 0.6),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 15, color: _textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Driver: ${ride.driverName} (${ride.driverPhone})',
                      style: const TextStyle(color: _textMain, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 2),
                          Text(
                            ride.driverRating.toStringAsFixed(1),
                            style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.airline_seat_recline_normal_rounded, size: 14, color: Color(0xFF93C5FD)),
                        const SizedBox(width: 4),
                        Text(
                          '${ride.availableSeats}/${ride.totalSeats} Seats Available',
                          style: const TextStyle(color: _textMain, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '₹${ride.contributionPerSeat.toStringAsFixed(0)} / seat',
                      style: const TextStyle(color: _accentMint, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelRideDialog(AdminRideItem ride, AdminNotifier notifier) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Ride via Admin Moderation', style: TextStyle(color: _textMain, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Corridor: ${ride.originName} -> ${ride.destinationName}', style: const TextStyle(color: _textMuted, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: _textMain, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Reason for cancellation (e.g. Safety flag, road hazard)',
                hintStyle: const TextStyle(color: _textMuted, fontSize: 12),
                filled: true,
                fillColor: _bgCanvas,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Active', style: TextStyle(color: _textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _urgentCoral, foregroundColor: Colors.white),
            onPressed: () async {
              final reason = reasonController.text.trim();
              Navigator.of(ctx).pop();
              final ok = await notifier.cancelRide(ride.id, reason.isNotEmpty ? reason : 'Admin policy moderation.');
              if (ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ride has been cancelled and passengers refunded/notified.')),
                );
              }
            },
            child: const Text('Confirm Cancellation'),
          ),
        ],
      ),
    );
  }

  // TAB 4: SAFETY & REPORTS CONSOLE
  Widget _buildReportsTab(AdminState state, AdminNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Safety & SOS Incident Center', style: TextStyle(color: _textMain, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Incident reports, SOS triggers, route deviations, and conduct flags.', style: TextStyle(color: _textMuted, fontSize: 13)),
          const SizedBox(height: 18),
          Expanded(
            child: state.reports.isEmpty
                ? const Center(child: Text('No safety reports currently pending.', style: TextStyle(color: _textMuted)))
                : ListView.builder(
                    itemCount: state.reports.length,
                    itemBuilder: (context, index) {
                      final report = state.reports[index];
                      return _buildReportCard(report, notifier);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(AdminReportItem report, AdminNotifier notifier) {
    final isResolved = report.status == 'resolved';
    final severityColor = report.severity == 'critical'
        ? _urgentCoral
        : (report.severity == 'high' ? Colors.orange : _accentBlue);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      report.severity.toUpperCase(),
                      style: TextStyle(color: severityColor, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    report.title,
                    style: const TextStyle(color: _textMain, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isResolved ? _accentMint.withValues(alpha: 0.15) : _urgentCoral.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report.status.toUpperCase(),
                  style: TextStyle(
                    color: isResolved ? _accentMint : _urgentCoral,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(report.description, style: const TextStyle(color: _textMuted, fontSize: 13, height: 1.4)),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                'Reported by ${report.reporterName} (${report.reporterPhone})',
                style: const TextStyle(color: _textMuted, fontSize: 11),
              ),
              if (!isResolved)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentMint,
                    foregroundColor: _bgCanvas,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                  label: const Text('Resolve Incident', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  onPressed: () => _showResolveDialog(report, notifier),
                )
              else
                Text(
                  'Resolved: ${report.resolutionNotes.isNotEmpty ? report.resolutionNotes : "Handled by trust & safety"}',
                  style: const TextStyle(color: _accentMint, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showResolveDialog(AdminReportItem report, AdminNotifier notifier) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Resolve Report: ${report.title}', style: const TextStyle(color: _textMain, fontSize: 16)),
        content: TextField(
          controller: notesController,
          style: const TextStyle(color: _textMain, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Resolution summary (e.g. Passenger contacted, verified safety)',
            hintStyle: const TextStyle(color: _textMuted, fontSize: 12),
            filled: true,
            fillColor: _bgCanvas,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel', style: TextStyle(color: _textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accentMint, foregroundColor: _bgCanvas),
            onPressed: () async {
              final notes = notesController.text.trim();
              Navigator.of(ctx).pop();
              final ok = await notifier.resolveReport(report.id, notes.isNotEmpty ? notes : 'Resolved by administrator.');
              if (ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incident resolved.')));
              }
            },
            child: const Text('Confirm Resolution'),
          ),
        ],
      ),
    );
  }

  // TAB 5: SYSTEM SETTINGS
  Widget _buildSettingsTab(AdminState state, AdminNotifier notifier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('System Architecture & Deployment', style: TextStyle(color: _textMain, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Configuration parameters, network gateway, and database status.', style: TextStyle(color: _textMuted, fontSize: 13)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _cardBorder, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gateway Endpoints', style: TextStyle(color: _textMain, fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 14),
                  _buildSettingsTile('Backend REST API', 'http://localhost:5000/api/v1', Icons.link_rounded),
                  _buildSettingsTile('Database Status', 'MongoDB Replica Active (127.0.0.1)', Icons.storage_rounded),
                  _buildSettingsTile('Active Geolocation Engine', 'Google Directions API + Bezier Fallback', Icons.map_rounded),
                  _buildSettingsTile('Platform Version', 'Sahyān v1.0.0 (Phase 5 Admin Mesh)', Icons.info_outline_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: _accentMint, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: _textMuted, fontSize: 11)),
                Text(value, style: const TextStyle(color: _textMain, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
