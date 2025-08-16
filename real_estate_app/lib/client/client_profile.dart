import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:real_estate_app/core/api_service.dart';
import 'package:real_estate_app/shared/app_layout.dart';
import 'package:real_estate_app/client/client_bottom_nav.dart';
import 'package:real_estate_app/shared/header.dart';

class ClientProfile extends StatefulWidget {
  final String token;

  const ClientProfile({Key? key, required this.token}) : super(key: key);

  @override
  _ClientProfileState createState() => _ClientProfileState();
}

class _ClientProfileState extends State<ClientProfile>
    with TickerProviderStateMixin {
  String? _headerImageUrl;
  late final AnimationController _glowController;
  final Map<int, NumberFormat> _currencyFormatCache = {};
  // bool _aboutExpanded = false;

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) {
      return double.tryParse(v.replaceAll(',', '')) ?? 0.0;
    }
    try {
      return double.parse(v.toString());
    } catch (_) {
      return 0.0;
    }
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) {
      final s = v.replaceAll(',', '').trim();
      return int.tryParse(s) ?? (double.tryParse(s)?.toInt() ?? 0);
    }
    try {
      return int.parse(v.toString());
    } catch (_) {
      // fallback for unexpected types
      try {
        return (double.parse(v.toString())).toInt();
      } catch (_) {
        return 0;
      }
    }
  }

  String formatCurrency(dynamic valueOrDouble, {int? decimalDigits, bool forceSignForPositive = false, String locale = 'en_NG'}) {
    final double value = valueOrDouble is double ? valueOrDouble : _toDouble(valueOrDouble);

    if (value.isNaN || !value.isFinite) return '\u20A6' '0.00';
    final digits = decimalDigits ?? (value.abs() >= 1000 ? 0 : 2);

    final fmt = _currencyFormatCache.putIfAbsent(digits, () {
      return NumberFormat.currency(locale: locale, symbol: '\u20A6', decimalDigits: digits);
    });

    final formatted = fmt.format(value);
    return (forceSignForPositive && value > 0) ? '+$formatted' : formatted;
  }

  String formatPercent(dynamic valueOrDouble, {int digits = 2, bool forceSignForPositive = false}) {
    final double value = valueOrDouble is double ? valueOrDouble : _toDouble(valueOrDouble);
    if (value.isNaN || !value.isFinite) return '0.00%';

    final s = value.toStringAsFixed(digits);
    return (forceSignForPositive && value > 0) ? '+$s%' : '$s%';
  }

  late TabController _tabController;

  late Future<Map<String, dynamic>> _profileFuture;
  late Future<List<dynamic>> _propertiesFuture;
  late Future<List<dynamic>> _appreciationFuture;

  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _jobController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    // Tab controller
    _tabController = TabController(length: 5, vsync: this);

    // Glow controller
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _loadData();
  }

  void _loadData() {
    // _profileFuture = ApiService().getClientDetailByToken(token: widget.token);
    _propertiesFuture = ApiService().getClientProperties(token: widget.token);
    _appreciationFuture =
        ApiService().getValueAppreciation(token: widget.token);

    _profileFuture =
        ApiService().getClientDetailByToken(token: widget.token).then((data) {
      final maybeHeader = (data['header_image'] ?? data['profile_image']);
      if (maybeHeader is String && maybeHeader.isNotEmpty) {
        setState(() {
          _headerImageUrl = maybeHeader;
        });
      }
      return data;
    });

    _propertiesFuture = ApiService().getClientProperties(token: widget.token);
    _appreciationFuture =
        ApiService().getValueAppreciation(token: widget.token);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        final updatedProfile = await ApiService().updateClientProfileByToken(
          token: widget.token,
          fullName: _fullNameController.text,
          about: _aboutController.text,
          company: _companyController.text,
          job: _jobController.text,
          country: _countryController.text,
          address: _addressController.text,
          phone: _phoneController.text,
          email: _emailController.text,
          profileImage: _imageFile,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!',
                style: GoogleFonts.sora(color: Colors.white)),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _profileFuture = Future.value(updatedProfile);
          _isEditing = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e',
                style: GoogleFonts.sora(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    if (_passwordFormKey.currentState!.validate()) {
      if (_newPasswordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Passwords do not match',
                style: GoogleFonts.sora(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        await ApiService().changePasswordByToken(
          token: widget.token,
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password changed successfully!',
                style: GoogleFonts.sora(color: Colors.white)),
            backgroundColor: Colors.green,
          ),
        );

        // Clear password fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing password: $e',
                style: GoogleFonts.sora(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return AppLayout(
        pageTitle: 'Client Profile',
        token: widget.token,
        side: AppSide.client,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.light,
          ),
          child: Scaffold(
            extendBodyBehindAppBar: true,
            // backgroundColor: const Color(0xFFF8F9FA),
            backgroundColor: Colors.transparent,
            bottomNavigationBar: ClientBottomNav(
              currentIndex: 1,
              token: widget.token,
              chatBadge: 1,
            ),
            body: NestedScrollView(
              floatHeaderSlivers: true,
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                final double topPadding = MediaQuery.of(context).padding.top;
                final double expandedHeight = 280.0 + topPadding;

                return [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    pinned: true,
                    stretch: true,
                    expandedHeight: expandedHeight,
                    automaticallyImplyLeading: false,
                    centerTitle: false,
                    systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
                      statusBarColor: Colors.transparent,
                    ),
                    toolbarHeight: kToolbarHeight + topPadding,
                    collapsedHeight: kToolbarHeight + topPadding,
                    flexibleSpace:
                        LayoutBuilder(builder: (context, constraints) {
                      final double maxHeight = constraints.maxHeight;
                      final double t =
                          ((maxHeight - (kToolbarHeight + topPadding)) /
                                  ((expandedHeight) -
                                      (kToolbarHeight + topPadding)))
                              .clamp(0.0, 1.0);

                      const double avatarMax = 110.0;
                      const double avatarMin = 40.0;
                      final double avatarSize =
                          avatarMin + (avatarMax - avatarMin) * t;

                      // compute left positions: when expanded avatar centered, when collapsed near left padding
                      final double screenWidth =
                          MediaQuery.of(context).size.width;
                      final double avatarCenterLeftExpanded =
                          (screenWidth / 2) - (avatarSize / 2);
                      final double avatarLeftCollapsed = 12.0;
                      final double avatarLeft = avatarLeftCollapsed +
                          (avatarCenterLeftExpanded - avatarLeftCollapsed) * t;

                      // compute top positions: expanded avatar near bottom of header, collapsed inside toolbar
                      final double avatarTopExpanded =
                          expandedHeight - avatarSize / 2 - 16;
                      final double avatarTopCollapsed =
                          MediaQuery.of(context).padding.top +
                              (kToolbarHeight - avatarMin) / 2;
                      final double avatarTop = avatarTopCollapsed +
                          (avatarTopExpanded - avatarTopCollapsed) * t;

                      final double bigTitleOpacity = t;
                      final double smallTitleOpacity = 1.0 - t;
                      final double smallTitleLeftCollapsed =
                          avatarLeftCollapsed + avatarMin + 12.0;
                      final double smallTitleLeftExpanded = 20.0;
                      final double smallTitleLeft = smallTitleLeftCollapsed +
                          (smallTitleLeftExpanded - smallTitleLeftCollapsed) *
                              t;

                      // background image widget (use network header if available, else asset)
                      final Widget backgroundImageWidget =
                          (_headerImageUrl != null &&
                                  _headerImageUrl!.isNotEmpty)
                              ? Image.network(_headerImageUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  loadingBuilder: (c, child, progress) {
                                    if (progress == null) return child;
                                    return Container(color: Colors.grey[300]);
                                  },
                                  errorBuilder: (c, e, s) => Image.asset(
                                      'assets/avater.webp',
                                      fit: BoxFit.cover))
                              : Image.asset('assets/avater.webp',
                                  fit: BoxFit.cover);

                      final double glowScale =
                          0.85 + (_glowController.value) * (1.35 - 0.85);
                      final double glowFactor = glowScale * (0.7 + 0.3 * t);

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          // Make sure background paints under the status bar (no white gap)
                          Positioned.fill(
                            child: Transform.translate(
                              offset: Offset(0, (1 - t) * 28),
                              child: backgroundImageWidget,
                            ),
                          ),

                          // gradient overlay (keeps contrast) — remains semi-transparent at all times
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withOpacity(0.36),
                                    Colors.black.withOpacity(0.08),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),

                          // Large expanded title
                          Positioned(
                            left: 20,
                            bottom: 20,
                            child: Opacity(
                              opacity: bigTitleOpacity,
                              child: Transform.translate(
                                offset: Offset(0, (1 - t) * 6),
                                child: Text(
                                  'Profile',
                                  style: GoogleFonts.sora(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    shadows: [
                                      Shadow(
                                          blurRadius: 6.0,
                                          color:
                                              Colors.black.withOpacity(0.45)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Small collapsed title (next to avatar when collapsed)
                          Positioned(
                            left: smallTitleLeft,
                            top: MediaQuery.of(context).padding.top + 12,
                            child: Opacity(
                              opacity: smallTitleOpacity,
                              child: Text(
                                'Profile',
                                style: GoogleFonts.sora(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          // Avatar (shrinks / slides / glows)
                          Positioned(
                            left: avatarLeft,
                            top: avatarTop,
                            child: Container(
                              width: avatarSize,
                              height: avatarSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4154F1)
                                        .withOpacity(0.23 * glowFactor),
                                    blurRadius: 12.0 * glowFactor,
                                    spreadRadius: 1.5 * (glowFactor - 0.9),
                                    offset: Offset(0, 6 * (1.0 - t) + 2),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.14 * t),
                                    blurRadius: 8.0,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.95),
                                    width: 3.0),
                              ),
                              child: ClipOval(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {},
                                    child: Hero(
                                      tag: 'profile-image',
                                      child: (_headerImageUrl != null &&
                                              _headerImageUrl!.isNotEmpty)
                                          ? Image.network(_headerImageUrl!,
                                              fit: BoxFit.cover,
                                              width: avatarSize,
                                              height: avatarSize,
                                              loadingBuilder:
                                                  (c, child, progress) {
                                                if (progress == null)
                                                  return child;
                                                return Container(
                                                    color: Colors.grey[300]);
                                              },
                                              errorBuilder: (c, e, s) =>
                                                  Image.asset(
                                                      'assets/avater.webp',
                                                      fit: BoxFit.cover))
                                          : Image.asset(
                                              'assets/avater.webp',
                                              fit: BoxFit.cover),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        indicatorColor: const Color(0xFF4154F1),
                        indicatorWeight: 3.0,
                        labelStyle: GoogleFonts.sora(
                            fontWeight: FontWeight.w600, fontSize: 14.0),
                        unselectedLabelStyle: GoogleFonts.sora(
                            fontWeight: FontWeight.w500, fontSize: 14.0),
                        tabs: const [
                          Tab(text: 'Overview'),
                          Tab(text: 'Properties'),
                          Tab(text: 'Value Appreciation'),
                          Tab(text: 'Edit Profile'),
                          Tab(text: 'Password'),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildPropertiesTab(),
                  _buildAppreciationTab(),
                  _buildEditProfileTab(),
                  _buildPasswordTab(),
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildOverviewTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoader();
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final profile = snapshot.data!;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildProfileCard(profile),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildProfileDetails(profile),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    _buildContactInfoCard(profile),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid complete':
      case 'fully paid':
        return Colors.green;
      case 'part payment':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ---------- Properties Tab (replacement) ----------
  Widget _buildPropertiesTab() {
    return FutureBuilder<List<dynamic>>(
      future: _propertiesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoader();
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final properties = snapshot.data ?? <dynamic>[];

        if (properties.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.house_outlined, size: 96, color: Colors.grey[300]),
                const SizedBox(height: 20),
                Text('No Properties Found',
                    style: GoogleFonts.sora(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('You haven\'t purchased any properties yet',
                    style: GoogleFonts.sora(color: Colors.grey)),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () {
                    // optional: navigate to marketplace
                  },
                  icon: const Icon(Icons.add_road),
                  label: Text('Explore Estates', style: GoogleFonts.sora()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4154F1),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          );
        }

        // Animated staggered list using TweenAnimationBuilder for each item
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: properties.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final property = properties[index] as Map<String, dynamic>;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 350 + (index * 70)),
              builder: (context, value, child) {
                // slide from bottom + fade
                final offset = (1 - value) * 12;
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, offset),
                    child: child,
                  ),
                );
              },
              child: _buildPropertyCard(property, index),
            );
          },
        );
      },
    );
  }

  // ---------- Property Card (replacement) ----------
  Widget _buildPropertyCard(Map<String, dynamic> property, int index) {
    final String estateName =
        (property['estate_name'] ?? 'Unknown Estate').toString();
    final String plotSize = (property['plot_size'] ?? 'N/A').toString();
    final String plotNumber =
        (property['plot_number'] ?? 'Reserved').toString();
    final double purchasePrice = _toDouble(property['purchase_price']);
    final String purchaseDate = (property['purchase_date'] ?? 'N/A').toString();
    final String status = (property['status'] ?? 'N/A').toString();
    final double paidPercent = property['paid_percent'] != null
        ? _toDouble(property['paid_percent'])
        : 0.0;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => _openPropertyDetailsModal(property, index),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 14),

                    // info column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  estateName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.sora(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                        color: _getStatusColor(status)
                                            .withOpacity(0.18),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6))
                                  ],
                                ),
                                child: Text(
                                  status,
                                  style: GoogleFonts.sora(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // chips row: plot size & number
                          Row(
                            children: [
                              _buildPropertyInfoItemWithChip(
                                  Icons.aspect_ratio, plotSize),
                              const SizedBox(width: 8),
                              _buildPropertyInfoItemWithChip(
                                  Icons.format_list_numbered, plotNumber),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // price summary
                          Text(
                            formatCurrency(purchasePrice, decimalDigits: 2),
                            style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),

                          const SizedBox(height: 6),

                          // mini progress if available
                          if (paidPercent > 0)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                        '${paidPercent.toStringAsFixed(0)}% Paid',
                                        style: GoogleFonts.sora(
                                            fontSize: 12,
                                            color: Colors.grey[700])),
                                    const Spacer(),

                                    Text(
                                      'Balance: ${formatCurrency(_toDouble(purchasePrice) * (1 - (_toDouble(paidPercent) / 100)), decimalDigits: 2)}',
                                      style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey[600],
                                      ),
                                    ),

                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: (paidPercent / 100).clamp(0.0, 1.0),
                                    minHeight: 8,
                                    backgroundColor:
                                        Colors.grey.withOpacity(0.12),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        const Color(0xFF4154F1)),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // actions row: date, receipts, view details
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Purchase Date',
                            style: GoogleFonts.sora(
                                fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 6),
                        Text(purchaseDate,
                            style: GoogleFonts.sora(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Spacer(),
                    // receipts button
                    OutlinedButton.icon(
                      onPressed: () {
                        // implement receipt view
                      },
                      icon: const Icon(Icons.receipt, size: 16),
                      label: Text('Receipts',
                          style: GoogleFonts.sora(fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _openPropertyDetailsModal(property, index),
                      icon: const Icon(Icons.visibility, size: 16),
                      label:
                          Text('View', style: GoogleFonts.sora(fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4154F1),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Helpers: Chip style info item ----------
  Widget _buildPropertyInfoItemWithChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(text,
              style: GoogleFonts.sora(fontSize: 13, color: Colors.grey[800])),
        ],
      ),
    );
  }

  // ---------- Modal details (transitional) ----------
  void _openPropertyDetailsModal(Map<String, dynamic> property, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            final String estateName =
                (property['estate_name'] ?? 'Unknown Estate').toString();
            final double purchasePrice = _toDouble(property['purchase_price']);
            final String purchaseDate =
                (property['purchase_date'] ?? 'N/A').toString();
            final String status = (property['status'] ?? 'N/A').toString();

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // top handle
                    Center(
                      child: Container(
                        width: 48,
                        height: 6,
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Text(estateName,
                              style: GoogleFonts.sora(
                                  fontSize: 20, fontWeight: FontWeight.w700)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(status,
                              style: GoogleFonts.sora(
                                  fontSize: 13, color: Colors.white)),
                        )
                      ],
                    ),

                    const SizedBox(height: 12),
                    Text('Purchase Price',
                        style:
                            GoogleFonts.sora(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Text(
                      formatCurrency(purchasePrice, decimalDigits: 2),
                      style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey[600],),
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey[700]),
                        const SizedBox(width: 8),
                        Text('Purchased on $purchaseDate',
                            style: GoogleFonts.sora(
                                fontSize: 13, color: Colors.grey[800])),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Text('Property Details',
                        style: GoogleFonts.sora(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    // descriptive fields (fallback to defaults)
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        _buildInfoChip('Plot Number',
                            property['plot_number']?.toString() ?? 'Reserved'),
                        _buildInfoChip('Plot Size',
                            property['plot_size']?.toString() ?? 'N/A'),
                        _buildInfoChip('Estate',
                            property['estate_name']?.toString() ?? 'N/A'),
                        _buildInfoChip('Receipt',
                            property['receipt_number']?.toString() ?? 'N/A'),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // implement share or download receipt
                            },
                            icon: const Icon(Icons.download_rounded),
                            label: Text('Download Receipt',
                                style: GoogleFonts.sora()),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // navigate to full property page
                            },
                            icon: const Icon(Icons.open_in_new),
                            label: Text('Open Property',
                                style: GoogleFonts.sora()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4154F1),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------- Small helpers used in modal ----------
  Widget _buildInfoChip(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title + ': ',
              style: GoogleFonts.sora(fontSize: 12, color: Colors.grey[700])),
          const SizedBox(width: 6),
          Text(value,
              style:
                  GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAppreciationTab() {
    return FutureBuilder<List<dynamic>>(
      future: _appreciationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoader();
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final appreciationData = snapshot.data!;

        if (appreciationData.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.trending_up, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No Appreciation Data',
                  style: GoogleFonts.sora(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Property appreciation data will appear here',
                  style: GoogleFonts.sora(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        double totalAppreciation = 0;
        double totalGrowth = 0;
        double highestGrowth = 0;
        String highestGrowthProperty = '';

        for (var item in appreciationData) {
          totalAppreciation += item['appreciation_total'] ?? 0;
          totalGrowth += item['growth_rate'] ?? 0;
          if ((item['growth_rate'] ?? 0) > highestGrowth) {
            highestGrowth = item['growth_rate'] ?? 0;
            highestGrowthProperty = item['estate_name'] ?? '';
          }
        }

        final averageGrowth = appreciationData.isNotEmpty
            ? totalGrowth / appreciationData.length
            : 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Property Value Appreciation',
                style: GoogleFonts.sora(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Detailed view of property value growth over time',
                style: GoogleFonts.sora(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: appreciationData.length,
                itemBuilder: (context, index) {
                  return _buildAppreciationCard(appreciationData[index]);
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Portfolio Summary',
                style: GoogleFonts.sora(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Total Appreciation',
                      // value: '+₦${totalAppreciation.toStringAsFixed(2)}',
                      value: formatCurrency(totalAppreciation, decimalDigits: 2),
                      icon: Icons.trending_up,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Average Growth',
                      value: '${averageGrowth.toStringAsFixed(2)}%',
                      icon: Icons.percent,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSummaryCard(
                title: 'Highest Growth',
                value: highestGrowthProperty,
                subtitle: '+${highestGrowth.toStringAsFixed(2)}%',
                icon: Icons.star,
                color: Colors.amber,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppreciationCard(Map<String, dynamic> data) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['estate_name'] ?? 'Unknown Estate',
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              data['plot_size'] ?? 'N/A',
              style: GoogleFonts.sora(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Purchase Price',
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '₦${data['purchase_price']?.toStringAsFixed(2) ?? '0.00'}',
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Current Value',
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '₦${data['current_value']?.toStringAsFixed(2) ?? '0.00'}',
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Value Increase',
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '+₦${data['appreciation_total']?.toStringAsFixed(2) ?? '0.00'}',
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Growth Rate',
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '+${data['growth_rate']?.toStringAsFixed(2) ?? '0.00'}%',
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  isVisible: false,
                ),
                series: <ChartSeries>[
                  LineSeries<Map<String, dynamic>, String>(
                    dataSource: [
                      {'year': '2022', 'value': data['purchase_price'] ?? 0},
                      {
                        'year': '2023',
                        'value': (data['purchase_price'] ?? 0) * 1.2
                      },
                      {'year': '2024', 'value': data['current_value'] ?? 0},
                    ],
                    xValueMapper: (Map<String, dynamic> sales, _) =>
                        sales['year'],
                    yValueMapper: (Map<String, dynamic> sales, _) =>
                        sales['value'],
                    markerSettings: const MarkerSettings(isVisible: true),
                    color: const Color(0xFF4154F1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.sora(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.sora(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditProfileTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoader();
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final profile = snapshot.data!;

        // Initialize controllers with profile data
        if (!_isEditing) {
          _fullNameController.text = profile['full_name'] ?? '';
          _aboutController.text = profile['about'] ?? '';
          _companyController.text = profile['company'] ?? '';
          _jobController.text = profile['job'] ?? '';
          _countryController.text = profile['country'] ?? '';
          _addressController.text = profile['address'] ?? '';
          _phoneController.text = profile['phone'] ?? '';
          _emailController.text = profile['email'] ?? '';
          _isEditing = true;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : profile['profile_image'] != null
                                ? NetworkImage(
                                    profile['profile_image'] as String)
                                : const AssetImage('assets/avater.webp')
                                    as ImageProvider,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF4154F1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: IconButton(
                          icon:
                              const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _pickImage,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _aboutController,
                  decoration: InputDecoration(
                    labelText: 'About',
                    prefixIcon: const Icon(Icons.info),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _companyController,
                        decoration: InputDecoration(
                          labelText: 'Company',
                          prefixIcon: const Icon(Icons.business),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _jobController,
                        decoration: InputDecoration(
                          labelText: 'Job Title',
                          prefixIcon: const Icon(Icons.work),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _countryController,
                        decoration: InputDecoration(
                          labelText: 'Country',
                          prefixIcon: const Icon(Icons.flag),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4154F1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Save Changes',
                      style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPasswordTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Change Password',
              style: GoogleFonts.sora(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ensure your account is secure with a strong password',
              style: GoogleFonts.sora(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your current password';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a new password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: const Icon(Icons.lock_reset),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your new password';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4154F1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Change Password',
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(
      {required int propertiesCount, required double totalValue}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatItem(
          value: propertiesCount.toString(),
          label: 'Properties',
        ),
        Container(
          height: 30,
          width: 1,
          color: Colors.grey[300],
          margin: const EdgeInsets.symmetric(horizontal: 20),
        ),
        _buildStatItem(
          value: '₦${totalValue.toStringAsFixed(2)}',
          label: 'Total Value',
        ),
      ],
    );
  }

  Widget _buildStatItem({required String value, required String label}) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.sora(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4154F1),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.sora(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // ------------------ BEAUTIFIED / ANIMATED PROFILE CARD ------------------
  Widget _buildProfileCard(Map<String, dynamic> profile) {
    final propertiesCount = _toInt(profile['properties_count']);
    final totalValue = _toDouble(profile['total_value']);
    final avatarUrl = profile['profile_image'] as String?;
    final assigned = profile['assigned_marketer'] as Map<String, dynamic>?;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.85),
              Colors.white.withOpacity(0.72),
            ],
            stops: const [0.0, 0.9],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: const Color(0xFF4154F1).withOpacity(0.06),
              blurRadius: 40,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.6)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (_tabController.index != 0) _tabController.animateTo(0);
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                // Use LayoutBuilder here to make stats area responsive
                child: LayoutBuilder(builder: (context, constraints) {
                  // compute a responsive max width for the mini chart
                  final double maxChartWidth =
                      (constraints.maxWidth * 0.28).clamp(60.0, 110.0);

                  return Column(
                    children: [
                      // header row: avatar + name + marketer badge (animated)
                      Row(
                        children: [
                          Hero(
                            tag: 'profile-image',
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF4154F1).withOpacity(0.12),
                                    Colors.transparent,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: avatarUrl != null && avatarUrl.isNotEmpty
                                    ? FadeInImage.assetNetwork(
                                        placeholder:
                                            'assets/avater.webp',
                                        image: avatarUrl,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.asset(
                                        'assets/avater.webp',
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile['full_name'] ?? 'Valued Client',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.sora(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  profile['company'] ?? profile['job'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.sora(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // <-- changed Row to Wrap so badges don't force overflow -->
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4154F1)
                                            .withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.workspace_premium,
                                              size: 14,
                                              color: const Color(0xFF4154F1)),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Premium Client',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.sora(
                                                fontSize: 12,
                                                color: const Color(0xFF4154F1)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 450),
                                      switchInCurve: Curves.easeOutBack,
                                      child: assigned != null
                                          ? _buildMarketerBadge(assigned)
                                          : SizedBox(
                                              key:
                                                  const ValueKey('no_marketer'),
                                              child: Text(
                                                'No marketer assigned',
                                                style: GoogleFonts.sora(
                                                    fontSize: 12,
                                                    color: Colors.grey),
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Animated stats row with a mini chart
                      Row(
                        children: [
                          // Use Flexible so children can shrink more gracefully than Expanded
                          Flexible(
                            flex: 1,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(
                                  begin: 0, end: propertiesCount.toDouble()),
                              duration: const Duration(milliseconds: 900),
                              builder: (context, value, child) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      value.toInt().toString(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.sora(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF4154F1),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Properties',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.sora(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                          // thin divider (keeps fixed width 1)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Container(
                                height: 36, width: 1, color: Colors.grey[200]),
                          ),

                          Flexible(
                            flex: 1,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: totalValue),
                              duration: const Duration(milliseconds: 1100),
                              builder: (context, value, child,) {
                                final display = value >= 1000
                                    // ? '₦${value.toStringAsFixed(0)}'
                                    ? formatCurrency(value, decimalDigits: 0)
                                    // : '₦${value.toStringAsFixed(2)}';
                                    : formatCurrency(value, decimalDigits: 2);
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      left: 4.0, right: 4.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        display,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.sora(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF10B981),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Total Investment',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey)
                                      ),
                                    ],
                                  ),
                                );
                              },
                            
                            ),
                          ),

                          // mini sparkline chart (visual hint)
                          SizedBox(
                            width: maxChartWidth,
                            height: 56,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: SfCartesianChart(
                                margin: EdgeInsets.zero,
                                plotAreaBorderWidth: 0,
                                primaryXAxis: CategoryAxis(isVisible: false),
                                primaryYAxis: NumericAxis(isVisible: false),
                                series: <ChartSeries>[
                                  LineSeries<Map<String, dynamic>, String>(
                                    dataSource: [
                                      {'y': (totalValue * 0.85)},
                                      {'y': (totalValue * 0.95)},
                                      {'y': (totalValue * 1.05)},
                                      {'y': totalValue},
                                    ],
                                    xValueMapper: (Map<String, dynamic> d, _) =>
                                        _.toString(),
                                    yValueMapper: (Map<String, dynamic> d, _) =>
                                        _toDouble(d['y']),
                                    width: 2,
                                    markerSettings:
                                        const MarkerSettings(isVisible: false),
                                    color: const Color(0xFF4154F1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------ STYLISH MARKETER BADGE ------------------
  Widget _buildMarketerBadge(Map<String, dynamic> marketer) {
    final name = marketer['full_name'] ?? 'Not assigned';
    final avatar = marketer['avatar'] as String?;
    return AnimatedContainer(
      key: ValueKey(name),
      duration: const Duration(milliseconds: 520),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4154F1), Color(0xFF7F8CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (avatar != null && avatar.isNotEmpty)
            CircleAvatar(radius: 10, backgroundImage: NetworkImage(avatar))
          else
            const CircleAvatar(radius: 10, child: Icon(Icons.person, size: 12)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assigned Marketer',
                style: GoogleFonts.sora(
                    fontSize: 10, color: Colors.white.withOpacity(0.9)),
              ),
              Text(
                name,
                style: GoogleFonts.sora(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------ CONTACT CARD (ACTIONS + ANIMATIONS) ------------------
  Widget _buildContactInfoCard(Map<String, dynamic> profile) {
    final email = profile['email'] ?? 'Not specified';
    final phone = profile['phone'] ?? 'Not specified';
    final address = profile['address'] ?? 'Not specified';
    final company = profile['company'] ?? 'Not specified';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 12))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Contact Information',
                    style: GoogleFonts.sora(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  // quick action buttons
                  IconButton(
                    tooltip: 'Message',
                    onPressed: () {
                      // implement message action
                    },
                    icon: const Icon(Icons.message_outlined,
                        color: Color(0xFF4154F1)),
                  ),
                  IconButton(
                    tooltip: 'Call',
                    onPressed: () {
                      // implement call action
                    },
                    icon: const Icon(Icons.call_outlined,
                        color: Color(0xFF10B981)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildContactItem(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: email,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: email));
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Email copied to clipboard')));
                  }),
              _buildContactItem(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: phone,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: phone));
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Phone copied to clipboard')));
                  }),
              _buildContactItem(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: address,
                  onTap: () {}),
              _buildContactItem(
                  icon: Icons.business_outlined,
                  label: 'Company',
                  value: company,
                  onTap: () {}),
            ],
          ),
        ),
      ),
    );
  }

  // contact table row with subtle ripple + copy affordance
  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    GestureTapCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF4154F1).withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF4154F1)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: GoogleFonts.sora(
                            fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 2),
                    Text(value,
                        style: GoogleFonts.sora(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ]),
            ),
            if (onTap != null)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(Icons.copy, size: 16, color: Colors.grey[400]),
              ),
          ],
        ),
      ),
    );
  }

  // ------------------ PROFILE DETAILS (EXPANDABLE ABOUT + GRID) ------------------
  Widget _buildProfileDetails(Map<String, dynamic> profile) {
    final about = profile['about'] as String? ?? 'No information provided';
    final rawDate = profile['date_registered'];
    String dateRegistered;
    if (rawDate == null) {
      dateRegistered = 'Not specified';
    } else {
      final s = rawDate.toString();
      String datePart;
      if (s.contains('T')) {
        datePart = s.split('T')[0];
      } else if (s.contains(' ')) {
        datePart = s.split(' ')[0];
      } else {
        datePart = s;
      }
      try {
        final dt = DateTime.parse(datePart);
        dateRegistered = DateFormat.yMMMMd().format(dt);
      } catch (_) {
        dateRegistered = datePart;
      }
    }

    final country = profile['country']?.toString() ?? 'Not specified';
    final fullName = profile['full_name']?.toString() ?? 'Not specified';

    bool isLong = about.length > 140;
    final preview = isLong ? '${about.substring(0, 140)}…' : about;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 18,
              offset: const Offset(0, 12),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // determine columns based on available width
              final cols = constraints.maxWidth > 600 ? 3 : 2;
              const gap = 12.0;
              // tile width calculation accounts for gaps between items
              final tileWidth =
                  (constraints.maxWidth - (gap * (cols - 1))) / cols;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'About Me',
                          style: GoogleFonts.sora(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            _tabController.animateTo(3);
                          },
                          icon: const Icon(Icons.edit_outlined,
                              color: Color(0xFF4154F1)),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    AnimatedCrossFade(
                      firstChild: Text(
                        preview,
                        style: GoogleFonts.sora(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[700],
                        ),
                      ),
                      secondChild: Text(
                        about,
                        style: GoogleFonts.sora(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[800],
                        ),
                      ),
                      crossFadeState: about.length > 140
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      duration: const Duration(milliseconds: 450),
                    ),
                    if (isLong)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('About', style: GoogleFonts.sora()),
                                content: Text(about, style: GoogleFonts.sora()),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: Text(
                                      'Close',
                                      style: GoogleFonts.sora(),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Text(
                            'Read more',
                            style: GoogleFonts.sora(
                              color: const Color(0xFF4154F1),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      'Profile Details',
                      style: GoogleFonts.sora(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Responsive wrap in place of GridView to avoid overflow and allow tile content to wrap
                    Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        SizedBox(
                          width: tileWidth,
                          child: _buildInfoItem(
                              label: 'Full Name', value: fullName),
                        ),
                        SizedBox(
                          width: tileWidth,
                          child:
                              _buildInfoItem(label: 'Country', value: country),
                        ),
                        SizedBox(
                          width: tileWidth,
                          child: _buildInfoItem(
                              label: 'Date Registered', value: dateRegistered),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPortfolioSummaryCard(
                      propertiesCount: _toInt(profile['properties_count']),
                      totalValue: _toDouble(profile['total_value']),
                      currentValue: _toDouble(profile['current_value']),
                      appreciationTotal:
                          _toDouble(profile['appreciation_total']),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ------------------ SMALL CARD FOR INFO ITEMS ------------------
  Widget _buildInfoItem({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.sora(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 6),
          Text(value,
              style:
                  GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ------------------ PORTFOLIO SUMMARY (SLEEK ROWS + PROGRESS) ------------------
  Widget _buildPortfolioSummaryCard({
    required int propertiesCount,
    required double totalValue,
    required double currentValue,
    required double appreciationTotal,
  }) {
    // ensure values are finite and safe
    totalValue = totalValue.isFinite ? totalValue : 0.0;
    currentValue = currentValue.isFinite ? currentValue : 0.0;
    appreciationTotal = appreciationTotal.isFinite ? appreciationTotal : 0.0;

    final growthPercent = totalValue > 0
        ? ((currentValue - totalValue) / (totalValue) * 100)
            .clamp(-999.0, 9999.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Portfolio Summary',
            style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildSummaryItem(
            label: 'Total Properties', value: propertiesCount.toString()),
        _buildSummaryItem(
            label: 'Total Investment',
            // value: '₦${totalValue.toStringAsFixed(2)}'),
            value: formatCurrency(totalValue, decimalDigits: 2)),
        _buildSummaryItem(
            label: 'Current Value',
            // value: '₦${currentValue.toStringAsFixed(2)}'),
            value: formatCurrency(currentValue, decimalDigits: 2)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: (currentValue > 0 && totalValue > 0)
                    ? (currentValue / (totalValue * 1.15)).clamp(0.0, 1.0)
                    : 0.0,
                minHeight: 8,
                backgroundColor: Colors.grey.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(growthPercent >= 0
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444)),
              ),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                  growthPercent.isFinite
                      ? '${growthPercent.toStringAsFixed(2)}%'
                      : '0.00%',
                  style: GoogleFonts.sora(fontWeight: FontWeight.w700)),
              Text('growth',
                  style:
                      GoogleFonts.sora(fontSize: 12, color: Colors.grey[600])),
            ]),
          ],
        ),
        const SizedBox(height: 8),
        _buildSummaryItem(
            label: 'Total Appreciation',
            value: formatCurrency(appreciationTotal, decimalDigits: 2),
            isPositive: appreciationTotal >= 0),
      ]),
    );
  }

  // ------------------ REFINED SUMMARY ROW ------------------
 
  Widget _buildSummaryItem({
    required String label,
    required dynamic value,
    bool isPositive = false,
    int? decimalDigits,
  }) {
    final formattedValue = value is String
        ? value
        : formatCurrency(value, decimalDigits: decimalDigits ?? 2);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(fontSize: 13, color: Colors.grey[700]),
          ),
          Text(
            formattedValue,
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w800,
              color: isPositive
                  ? const Color(0xFF10B981)
                  : const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------ UPGRADED SHIMMER LOADER ------------------
  Widget _buildShimmerLoader() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
              height: 140,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16))),
        ),
        const SizedBox(height: 14),
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Row(children: [
            Expanded(
                child: Container(
                    height: 90,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12)))),
            const SizedBox(width: 12),
            Expanded(
                child: Container(
                    height: 90,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12)))),
          ]),
        ),
        const SizedBox(height: 14),
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
              height: 220,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16))),
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
