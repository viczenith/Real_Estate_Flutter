// // lib/screens/client_profile.dart
// import 'dart:io';
// import 'dart:math';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:cached_network_image/cached_network_image.dart';

// // <-- Imported bottom nav
// import 'package:real_estate_app/client/client_bottom_nav.dart';

// import 'package:real_estate_app/core/api_service.dart';
// import 'package:real_estate_app/shared/app_layout.dart';
// import 'package:real_estate_app/shared/header.dart';

// class ClientProfile extends StatefulWidget {
//   const ClientProfile({required this.token, super.key});
//   final String token;

//   @override
//   _ClientProfileState createState() => _ClientProfileState();
// }

// class _ClientProfileState extends State<ClientProfile>
//     with SingleTickerProviderStateMixin {
//   // Tabs: Overview | Properties | Value
//   late TabController _tabController;

//   // scaffold key to open end drawer programmatically
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

//   // Forms
//   final GlobalKey<FormState> _editFormKey = GlobalKey<FormState>();
//   final GlobalKey<FormState> _pwFormKey = GlobalKey<FormState>();

//   // Controllers
//   final TextEditingController _fullNameCtrl = TextEditingController();
//   final TextEditingController _companyCtrl = TextEditingController();
//   final TextEditingController _jobCtrl = TextEditingController();
//   final TextEditingController _countryCtrl = TextEditingController();
//   final TextEditingController _addressCtrl = TextEditingController();
//   final TextEditingController _phoneCtrl = TextEditingController();
//   final TextEditingController _emailCtrl = TextEditingController();
//   final TextEditingController _aboutCtrl = TextEditingController();

//   final TextEditingController _currentPwCtrl = TextEditingController();
//   final TextEditingController _newPwCtrl = TextEditingController();
//   final TextEditingController _confirmPwCtrl = TextEditingController();

//   // image
//   File? _pickedImage;
//   final ImagePicker _picker = ImagePicker();

//   // states
//   bool _isLoading = true;
//   bool _isSavingProfile = false;
//   bool _isChangingPassword = false;
//   bool _isLoadingProperties = true;
//   bool _isLoadingAppreciation = true;

//   // data
//   Map<String, dynamic> _profile = {};
//   List<Map<String, dynamic>> _properties = [];
//   List<Map<String, dynamic>> _appreciationSeries = [];

//   // which panel to show in endDrawer: 'edit' | 'password'
//   String _openPanel = 'edit';

//   // subtle header animation
//   double _gradientTween = 0.0;

//   // scroll controller for parallax & avatar animation
//   final ScrollController _scrollController = ScrollController();
//   double _scrollOffset = 0.0;

//   // constants for expanded sizes
//   static const double _expandedHeight = 260.0;
//   static const double _avatarMaxSize = 120.0;
//   static const double _avatarMinSize = 44.0;
//   static const double _avatarLeftPadding = 20.0;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//     _scrollController.addListener(_onScroll);
//     _loadAll();
//     Future.delayed(const Duration(milliseconds: 400), () {
//       if (mounted) setState(() => _gradientTween = 1.0);
//     });
//   }

//   void _onScroll() {
//     if (!mounted) return;
//     setState(() {
//       _scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
//     });
//   }

//   @override
//   void dispose() {
//     _scrollController.removeListener(_onScroll);
//     _scrollController.dispose();
//     _tabController.dispose();

//     _fullNameCtrl.dispose();
//     _companyCtrl.dispose();
//     _jobCtrl.dispose();
//     _countryCtrl.dispose();
//     _addressCtrl.dispose();
//     _phoneCtrl.dispose();
//     _emailCtrl.dispose();
//     _aboutCtrl.dispose();
//     _currentPwCtrl.dispose();
//     _newPwCtrl.dispose();
//     _confirmPwCtrl.dispose();

//     super.dispose();
//   }

//   // -------------------------
//   // Data loading & API stubs
//   // -------------------------
//   Future<void> _loadAll() async {
//     setState(() {
//       _isLoading = true;
//     });
//     await Future.wait([_loadProfile(), _loadProperties(), _loadAppreciation()]);
//     if (mounted) setState(() => _isLoading = false);
//   }

//   Future<void> _loadProfile() async {
//     try {
//       final data = await ApiService().getClientDetailByToken(token: widget.token);
//       if (!mounted) return;
//       setState(() {
//         _profile = Map<String, dynamic>.from(data);
//         _fullNameCtrl.text = _profile['full_name'] ?? '';
//         _companyCtrl.text = _profile['company'] ?? '';
//         _jobCtrl.text = _profile['job'] ?? '';
//         _countryCtrl.text = _profile['country'] ?? '';
//         _addressCtrl.text = _profile['address'] ?? '';
//         _phoneCtrl.text = _profile['phone'] ?? '';
//         _emailCtrl.text = _profile['email'] ?? '';
//         _aboutCtrl.text = _profile['about'] ?? '';
//       });
//     } catch (e) {
//       _showModal('Failed to load profile', e.toString());
//     }
//   }

//   Future<void> _loadProperties() async {
//     setState(() => _isLoadingProperties = true);
//     try {
//       final list = await ApiService().getClientProperties(token: widget.token);
//       if (!mounted) return;
//       setState(() => _properties = List<Map<String, dynamic>>.from(list));
//     } catch (_) {
//       // ignore
//     } finally {
//       if (mounted) setState(() => _isLoadingProperties = false);
//     }
//   }

//   Future<void> _loadAppreciation() async {
//     setState(() => _isLoadingAppreciation = true);
//     try {
//       final series = await ApiService().getValueAppreciation(token: widget.token);
//       if (!mounted) return;
//       setState(() => _appreciationSeries = List<Map<String, dynamic>>.from(series));
//     } catch (_) {
//       // ignore
//     } finally {
//       if (mounted) setState(() => _isLoadingAppreciation = false);
//     }
//   }

//   // -------------------------
//   // Image & save actions
//   // -------------------------
//   Future<void> _pickImage() async {
//     try {
//       final XFile? picked = await _picker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 80,
//       );
//       if (picked != null && mounted) setState(() => _pickedImage = File(picked.path));
//     } on PlatformException catch (e) {
//       _showModal('Image pick failed', e.message ?? e.toString());
//     }
//   }

//   Future<void> _saveProfile() async {
//     if (!_editFormKey.currentState!.validate()) return;
//     _editFormKey.currentState!.save();

//     setState(() => _isSavingProfile = true);
//     try {
//       await ApiService().updateClientProfileByToken(
//         token: widget.token,
//         fullName: _fullNameCtrl.text.trim(),
//         about: _aboutCtrl.text.trim(),
//         company: _companyCtrl.text.trim(),
//         job: _jobCtrl.text.trim(),
//         country: _countryCtrl.text.trim(),
//         address: _addressCtrl.text.trim(),
//         phone: _phoneCtrl.text.trim(),
//         email: _emailCtrl.text.trim(),
//         profileImage: _pickedImage,
//       );
//       _showModal('Success', 'Profile updated successfully.');
//       await _loadProfile();
//       Navigator.of(context).maybePop();
//     } catch (e) {
//       _showModal('Update Failed', e.toString());
//     } finally {
//       if (mounted) setState(() => _isSavingProfile = false);
//     }
//   }

//   Future<void> _changePassword() async {
//     if (!_pwFormKey.currentState!.validate()) return;
//     if (_newPwCtrl.text != _confirmPwCtrl.text) {
//       _showSnack('New passwords do not match');
//       return;
//     }
//     setState(() => _isChangingPassword = true);
//     try {
//       await ApiService().changePasswordByToken(
//           token: widget.token,
//           currentPassword: _currentPwCtrl.text,
//           newPassword: _newPwCtrl.text);
//       _showModal('Success', 'Password changed successfully');
//       _currentPwCtrl.clear();
//       _newPwCtrl.clear();
//       _confirmPwCtrl.clear();
//       Navigator.of(context).maybePop();
//     } catch (e) {
//       _showModal('Password change failed', e.toString());
//     } finally {
//       if (mounted) setState(() => _isChangingPassword = false);
//     }
//   }

//   // -------------------------
//   // UI helpers
//   // -------------------------
//   void _openRightPanel(String panel) {
//     _openPanel = panel;
//     _scaffoldKey.currentState?.openEndDrawer();
//   }

//   void _showModal(String title, String message) {
//     showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//               title: Text(title,
//                   style: const TextStyle(
//                       color: Color(0xFF6C63FF),
//                       fontWeight: FontWeight.bold)),
//               content: Text(message),
//               actions: [
//                 TextButton(
//                     onPressed: () => Navigator.pop(context),
//                     child: const Text('OK',
//                         style: TextStyle(color: Color(0xFF6C63FF))))
//               ],
//             ));
//   }

//   void _showProfileDetailsSheet() {
//     showModalBottomSheet(
//         context: context,
//         shape: const RoundedRectangleBorder(
//             borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
//         isScrollControlled: true,
//         builder: (ctx) {
//           return DraggableScrollableSheet(
//             initialChildSize: 0.6,
//             minChildSize: 0.3,
//             maxChildSize: 0.95,
//             expand: false,
//             builder: (_, controller) {
//               return Container(
//                 padding: const EdgeInsets.all(16),
//                 child: ListView(controller: controller, children: [
//                   Center(
//                       child: Container(
//                           height: 5,
//                           width: 40,
//                           decoration: BoxDecoration(
//                               color: Colors.grey[300],
//                               borderRadius: BorderRadius.circular(4)))),
//                   const SizedBox(height: 14),
//                   Text('Profile Details',
//                       style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFF6C63FF))),
//                   const SizedBox(height: 12),
//                   _DetailRow(
//                       label: 'Full Name',
//                       value: _profile['full_name'] ?? '-',
//                       icon: Icons.person),
//                   const Divider(),
//                   _DetailRow(
//                       label: 'Company',
//                       value: _profile['company'] ?? '-',
//                       icon: Icons.business),
//                   const Divider(),
//                   _DetailRow(
//                       label: 'Job',
//                       value: _profile['job'] ?? '-',
//                       icon: Icons.work),
//                   const Divider(),
//                   _DetailRow(
//                       label: 'Country',
//                       value: _profile['country'] ?? '-',
//                       icon: Icons.flag),
//                   const Divider(),
//                   _DetailRow(
//                       label: 'Address',
//                       value: _profile['address'] ?? '-',
//                       icon: Icons.home),
//                   const Divider(),
//                   _DetailRow(
//                       label: 'Phone',
//                       value: _profile['phone'] ?? '-',
//                       icon: Icons.phone),
//                   const Divider(),
//                   _DetailRow(
//                       label: 'Email',
//                       value: _profile['email'] ?? '-',
//                       icon: Icons.email),
//                   const SizedBox(height: 18),
//                   ElevatedButton(
//                       onPressed: () => Navigator.pop(ctx),
//                       child: const Text('Close')),
//                 ]),
//               );
//             },
//           );
//         });
//   }

//   void _showSnack(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
//   }

//   // -------------------------
//   // BUILD
//   // -------------------------
//   @override
//   Widget build(BuildContext context) {
//     final pageTitle = _profile['full_name']?.isNotEmpty == true
//         ? '${_profile['full_name']}'
//         : 'Client Profile';

//     // computed parallax percent (0..1) where 0 = fully collapsed, 1 = expanded
//     final double collapseRange = _expandedHeight - kToolbarHeight;
//     final double offset = _scrollOffset.clamp(0.0, collapseRange);
//     final double t = 1.0 - (offset / (collapseRange == 0 ? 1 : collapseRange));

//     // avatar size & left/top positions (interpolate)
//     final double avatarSize =
//         (_avatarMinSize + (_avatarMaxSize - _avatarMinSize) * t).clamp(_avatarMinSize, _avatarMaxSize);
//     final double avatarLeft = _avatarLeftPadding * (0.6 + 0.4 * t);
//     final double avatarTop = (kToolbarHeight + (_expandedHeight - kToolbarHeight) * 0.52 * t) - avatarSize / 2;

//     // safe chatBadge read from _profile (handles string/int/null)
//     final int chatBadge = int.tryParse(_profile['chat_badge']?.toString() ?? '') ?? 0;

//     return AppLayout(
//       pageTitle: '$pageTitle Profile',
//       token: widget.token,
//       side: AppSide.client,
//       child: Scaffold(
//         key: _scaffoldKey,
//         // end drawer holds edit or password forms
//         endDrawer: _buildEndDrawer(),
//         backgroundColor: Colors.grey[50],
//         // <-- Add bottom navigation here
//         bottomNavigationBar: ClientBottomNav(
//           currentIndex: 1, // profile index
//           token: widget.token,
//           chatBadge: chatBadge,
//         ),
//         body: NestedScrollView(
//           controller: _scrollController,
//           headerSliverBuilder: (context, innerBoxIsScrolled) {
//             return [
//               SliverAppBar(
//                 pinned: true,
//                 expandedHeight: _expandedHeight,
//                 backgroundColor: Colors.white,
//                 elevation: 0,
//                 systemOverlayStyle: SystemUiOverlayStyle.light,
//                 shape: const RoundedRectangleBorder(
//                   borderRadius:
//                       BorderRadius.vertical(bottom: Radius.circular(18)),
//                 ),
//                 // Title shown when collapsed:
//                 title: AnimatedOpacity(
//                   duration: const Duration(milliseconds: 220),
//                   opacity: t < 0.25 ? 1.0 : 0.0,
//                   child: Row(
//                     children: [
//                       Hero(
//                         tag: 'profile-avatar',
//                         child: CircleAvatar(
//                           radius: 16,
//                           backgroundColor: Colors.white,
//                           child: ClipOval(
//                             child: _profile['profile_image'] != null
//                                 ? CachedNetworkImage(
//                                     imageUrl: _profile['profile_image'],
//                                     width: 32,
//                                     height: 32,
//                                     fit: BoxFit.cover,
//                                   )
//                                 : const Icon(Icons.person, size: 20),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           _profile['full_name'] ?? 'Profile',
//                           overflow: TextOverflow.ellipsis,
//                           style: const TextStyle(
//                               fontWeight: FontWeight.bold, fontSize: 16),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 flexibleSpace: FlexibleSpaceBar(
//                   background: Stack(
//                     children: [
//                       // parallax banner (image or gradient)
//                       Positioned.fill(
//                         child: AnimatedContainer(
//                           duration: const Duration(milliseconds: 600),
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               begin: Alignment(-1 + _gradientTween * 0.3, -1),
//                               end: Alignment(1 - _gradientTween * 0.1, 1),
//                               colors: const [Color(0xFF6A11CB), Color(0xFF2575FC)],
//                             ),
//                           ),
//                           child: _profile['banner_image'] != null
//                               ? CachedNetworkImage(
//                                   imageUrl: _profile['banner_image'],
//                                   fit: BoxFit.cover,
//                                   width: double.infinity,
//                                   height: double.infinity,
//                                   placeholder: (c, u) => Container(
//                                       color: Colors.black12,
//                                       child: const Center(
//                                           child:
//                                               CircularProgressIndicator())),
//                                   errorWidget: (c, u, e) => const SizedBox(),
//                                 )
//                               : null,
//                         ),
//                       ),

//                       // subtle overlay gradient
//                       Positioned.fill(
//                         child: Container(
//                           decoration: BoxDecoration(
//                               gradient: LinearGradient(
//                                   begin: Alignment.topCenter,
//                                   end: Alignment.bottomCenter,
//                                   colors: [
//                                 Colors.black.withOpacity(0.12 * (1 - t)),
//                                 Colors.transparent
//                               ])),
//                         ),
//                       ),

//                       // Full name on top-left when expanded
//                       Positioned(
//                         left: 20,
//                         top: 36,
//                         child: Opacity(
//                           opacity: t,
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 _profile['full_name'] ?? '-',
//                                 style: const TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 20,
//                                     fontWeight: FontWeight.bold),
//                               ),
//                               const SizedBox(height: 6),
//                               Text(
//                                 _profile['job'] ?? '',
//                                 style: const TextStyle(
//                                     color: Colors.white70, fontSize: 13),
//                               )
//                             ],
//                           ),
//                         ),
//                       ),

//                       // avatar overlapping banner (animated by scroll)
//                       Positioned(
//                         left: avatarLeft,
//                         top: avatarTop,
//                         child: GestureDetector(
//                           onTap: _pickImage,
//                           child: Hero(
//                             tag: 'profile-avatar',
//                             child: Material(
//                               color: Colors.transparent,
//                               child: Container(
//                                 width: avatarSize,
//                                 height: avatarSize,
//                                 decoration: BoxDecoration(
//                                   shape: BoxShape.circle,
//                                   border:
//                                       Border.all(color: Colors.white, width: 3),
//                                   boxShadow: const [
//                                     BoxShadow(
//                                         color: Colors.black26,
//                                         blurRadius: 12,
//                                         offset: Offset(0, 8))
//                                   ],
//                                 ),
//                                 child: ClipOval(
//                                   child: _pickedImage != null
//                                       ? Image.file(_pickedImage!,
//                                           fit: BoxFit.cover)
//                                       : (_profile['profile_image'] != null
//                                           ? CachedNetworkImage(
//                                               imageUrl:
//                                                   _profile['profile_image'],
//                                               fit: BoxFit.cover,
//                                               placeholder: (c, u) =>
//                                                   const Center(
//                                                       child:
//                                                           CircularProgressIndicator(
//                                                               color: Color(
//                                                                   0xFF6C63FF))),
//                                               errorWidget:
//                                                   (c, u, e) => const Icon(
//                                                       Icons.person,
//                                                       size: 48,
//                                                       color: Colors.grey),
//                                             )
//                                           : const Icon(Icons.person,
//                                               size: 56, color: Colors.grey)),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 bottom: PreferredSize(
//                   preferredSize: const Size.fromHeight(48),
//                   child: Container(
//                     height: 48,
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                       borderRadius:
//                           BorderRadius.vertical(bottom: Radius.circular(18)),
//                     ),
//                     child: TabBar(
//                       controller: _tabController,
//                       indicator: BoxDecoration(
//                           color: const Color(0xFF6C63FF),
//                           borderRadius: BorderRadius.circular(8)),
//                       labelColor: Colors.white,
//                       unselectedLabelColor: Colors.black54,
//                       isScrollable: true,
//                       tabs: const [
//                         Tab(icon: Icon(Icons.info_outline), text: 'Overview'),
//                         Tab(icon: Icon(Icons.home_work_outlined), text: 'Properties'),
//                         Tab(icon: Icon(Icons.trending_up), text: 'Value'),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ];
//           },
//           body: _isLoading
//               ? const Center(
//                   child: CircularProgressIndicator(
//                       valueColor:
//                           AlwaysStoppedAnimation(Color(0xFF6C63FF))))
//               : Stack(
//                   children: [
//                     TabBarView(
//                       controller: _tabController,
//                       children: [
//                         _buildOverviewTab(t),
//                         _buildPropertiesTab(),
//                         _buildAppreciationTab(),
//                       ],
//                     ),

//                     // Right-side vertical sticky buttons (Edit & Password) with subtle slide animation
//                     Positioned(
//                       right: 12,
//                       top: 120,
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           _floatingAction(label: 'Edit', icon: Icons.edit, onTap: () => _openRightPanel('edit'), delay: 0),
//                           const SizedBox(height: 12),
//                           _floatingAction(label: 'Password', icon: Icons.lock_outline, onTap: () => _openRightPanel('password'), delay: 80),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//         ),
//       ),
//     );
//   }

//   Widget _floatingAction({required String label, required IconData icon, required VoidCallback onTap, int delay = 0}) {
//     return TweenAnimationBuilder<double>(
//       tween: Tween(begin: 0.0, end: 1.0),
//       duration: Duration(milliseconds: 420 + delay),
//       builder: (ctx, val, child) => Transform.translate(offset: Offset(0, (1 - val) * 16), child: Opacity(opacity: val, child: child)),
//       child: GestureDetector(
//         onTap: onTap,
//         child: MouseRegion(
//           cursor: SystemMouseCursors.click,
//           child: Container(
//             padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(30),
//               boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 6))],
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 FloatingActionButton.small(
//                   heroTag: label,
//                   backgroundColor: const Color(0xFF6C63FF),
//                   foregroundColor: Colors.white,
//                   onPressed: onTap,
//                   child: Icon(icon, size: 18),
//                 ),
//                 const SizedBox(width: 8),
//                 RotatedBox(
//                   quarterTurns: 3,
//                   child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // -------------------------
//   // Overview tab (YouTube-ish header + about + details button)
//   // -------------------------
//   Widget _buildOverviewTab(double t) {
//     return RefreshIndicator(
//       onRefresh: _loadAll,
//       child: ListView(
//         padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 40),
//         children: [
//           // small stats row
//           Row(
//             children: [
//               _statTile(title: 'Properties', value: '${_properties.length}'),
//               const SizedBox(width: 10),
//               _statTile(title: 'Appreciation', value: _appreciationSeries.isEmpty ? '-' : '${_appreciationSeries.last['value']}'),
//               const SizedBox(width: 10),
//               _statTile(title: 'Contact', value: _profile['phone'] ?? '-'),
//             ],
//           ),
//           const SizedBox(height: 18),

//           // About card
//           _sectionTitle('About'),
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.04), blurRadius: 10)]),
//             child: AnimatedSwitcher(
//               duration: const Duration(milliseconds: 240),
//               child: Text(
//                 _profile['about'] ?? '-',
//                 key: ValueKey(_profile['about']),
//                 style: const TextStyle(fontSize: 15, height: 1.5),
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),

//           // Profile details button
//           GestureDetector(
//             onTap: _showProfileDetailsSheet,
//             child: Container(
//               width: double.infinity,
//               padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.04), blurRadius: 10)],
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                       const Text('Profile details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                       const SizedBox(height: 6),
//                       Text(_profile['job'] ?? '-', style: const TextStyle(color: Colors.grey)),
//                     ]),
//                   ),
//                   Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFEDEBFF), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF6C63FF))),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 18),

//           // CTA Row (Properties / Value)
//           Row(children: [
//             Expanded(child: ElevatedButton.icon(onPressed: () => _tabController.animateTo(1), icon: const Icon(Icons.home_work), label: const Text('View Properties'))),
//             const SizedBox(width: 12),
//             Expanded(child: OutlinedButton.icon(onPressed: () => _tabController.animateTo(2), icon: const Icon(Icons.trending_up), label: const Text('View Value'))),
//           ]),

//           const SizedBox(height: 24),

//           // Recent properties preview
//           if (_properties.isNotEmpty) _sectionTitle('Recent properties'),
//           const SizedBox(height: 8),
//           ..._properties.take(4).map((p) => _compactPropertyRow(p)).toList(),
//           const SizedBox(height: 16),
//         ],
//       ),
//     );
//   }

//   Widget _statTile({required String title, required String value}) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
//         decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.03), blurRadius: 8)]),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
//             const SizedBox(height: 8),
//             Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _compactPropertyRow(Map<String, dynamic> p) {
//     return TweenAnimationBuilder<double>(
//       tween: Tween(begin: 0.96, end: 1.0),
//       duration: const Duration(milliseconds: 420),
//       builder: (ctx, val, child) => Transform.scale(scale: val, child: child),
//       child: GestureDetector(onTap: () => _showPropertyDetails(p), child: Container(
//         margin: const EdgeInsets.only(bottom: 12),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
//         child: Row(children: [
//           ClipRRect(
//             borderRadius: BorderRadius.circular(10),
//             child: p['image'] != null
//                 ? CachedNetworkImage(imageUrl: p['image'], width: 86, height: 64, fit: BoxFit.cover, placeholder: (c,u)=> Container(color: Colors.grey[100], width: 86, height: 64))
//                 : Container(width: 86, height: 64, color: Colors.grey[200], child: const Icon(Icons.house, color: Colors.grey)),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//               Text(p['title'] ?? 'Property', style: const TextStyle(fontWeight: FontWeight.bold)),
//               const SizedBox(height: 6),
//               Text(p['location'] ?? '-', style: const TextStyle(color: Colors.grey, fontSize: 12)),
//             ]),
//           ),
//           const SizedBox(width: 8),
//           Text(p['price'] != null ? '₦${p['price']}' : '-', style: const TextStyle(fontWeight: FontWeight.bold)),
//         ]),
//       )),
//     );
//   }

//   // -------------------------
//   // Properties & Appreciation
//   // -------------------------
//   Widget _buildPropertiesTab() {
//     if (_isLoadingProperties) {
//       return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF6C63FF))));
//     }

//     if (_properties.isEmpty) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.all(28.0),
//           child: Column(mainAxisSize: MainAxisSize.min, children: [
//             const Icon(Icons.home_work_outlined, size: 64, color: Colors.grey),
//             const SizedBox(height: 12),
//             const Text('No properties found', style: TextStyle(fontSize: 16)),
//             const SizedBox(height: 12),
//             ElevatedButton(onPressed: _loadProperties, child: const Text('Reload')),
//           ]),
//         ),
//       );
//     }

//     return RefreshIndicator(
//       onRefresh: _loadProperties,
//       child: GridView.builder(
//         padding: const EdgeInsets.all(12),
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.78, crossAxisSpacing: 12, mainAxisSpacing: 12),
//         itemCount: _properties.length,
//         itemBuilder: (ctx, i) {
//           final p = _properties[i];
//           return TweenAnimationBuilder<double>(
//             tween: Tween(begin: 0.92, end: 1.0),
//             duration: Duration(milliseconds: 340 + (i * 40)),
//             builder: (ctx, val, child) => Transform.scale(scale: val, child: child),
//             child: _propertyCard(p),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildAppreciationTab() {
//     if (_isLoadingAppreciation) {
//       return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF6C63FF))));
//     }
//     if (_appreciationSeries.isEmpty) {
//       return Center(
//         child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.trending_up, size: 64, color: Colors.grey), const SizedBox(height: 12), const Text('No appreciation data available'), const SizedBox(height: 12), ElevatedButton(onPressed: _loadAppreciation, child: const Text('Reload'))])),
//       );
//     }

//     final values = _appreciationSeries.map<double>((m) => (m['value'] as num).toDouble()).toList();
//     final first = values.first;
//     final last = values.last;
//     final changePercent = ((last - first) / (first == 0 ? 1 : first) * 100);

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(20),
//       child: Column(children: [
//         _sectionTitle('Portfolio Value Trend'),
//         Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.04), blurRadius: 12)]),
//           child: Column(children: [
//             Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//               Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Current portfolio value', style: TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(height: 6), Text('₦${last.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]),
//               Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: changePercent >= 0 ? Colors.green : Colors.red)), const SizedBox(height: 6), Text('${_appreciationSeries.length} points', style: const TextStyle(color: Colors.grey))]),
//             ]),
//             const SizedBox(height: 18),
//             SizedBox(height: 120, child: _Sparkline(values: values)),
//             const SizedBox(height: 12),
//             Align(alignment: Alignment.centerRight, child: Text('From ${_appreciationSeries.first['date']} to ${_appreciationSeries.last['date']}', style: const TextStyle(fontSize: 12, color: Colors.grey))),
//           ]),
//         ),
//         const SizedBox(height: 20),
//       ]),
//     );
//   }

//   // -------------------------
//   // Helper for section titles
//   // -------------------------
//   Widget _sectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 10, top: 8),
//       child: Text(
//         title,
//         style: const TextStyle(
//           fontSize: 17,
//           fontWeight: FontWeight.bold,
//           color: Color(0xFF6C63FF),
//         ),
//       ),
//     );
//   }

//   // -------------------------
//   // End Drawer (right-side animated panel)
//   // -------------------------
//   Widget _buildEndDrawer() {
//     final width = MediaQuery.of(context).size.width * (MediaQuery.of(context).size.width > 800 ? 0.4 : 0.92);
//     return Drawer(
//       elevation: 8,
//       child: Container(
//         width: width,
//         padding: const EdgeInsets.all(16),
//         child: SafeArea(
//           child: Column(
//             children: [
//               Row(
//                 children: [
//                   Expanded(child: Text(_openPanel == 'edit' ? 'Edit Profile' : 'Change Password', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF)))),
//                   IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Expanded(
//                 child: SingleChildScrollView(
//                   child: _openPanel == 'edit' ? _buildEditPanelContent() : _buildPasswordPanelContent(),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildEditPanelContent() {
//     return Form(
//       key: _editFormKey,
//       child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
//         Center(
//           child: Stack(alignment: Alignment.center, children: [
//             Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF6C63FF), width: 3)), child: ClipOval(child: _pickedImage != null ? Image.file(_pickedImage!, fit: BoxFit.cover) : (_profile['profile_image'] != null ? CachedNetworkImage(imageUrl: _profile['profile_image'], fit: BoxFit.cover) : const Icon(Icons.person, size: 48)))),
//             Positioned(bottom: 0, right: 0, child: GestureDetector(onTap: _pickImage, child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFF6C63FF), shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 18)))),
//           ]),
//         ),
//         const SizedBox(height: 18),
//         TextFormField(controller: _fullNameCtrl, decoration: _inputDecoration('Full name', Icons.person), validator: (v) => v == null || v.trim().isEmpty ? 'Please enter full name' : null),
//         const SizedBox(height: 12),
//         TextFormField(controller: _aboutCtrl, decoration: _inputDecoration('About', Icons.note), maxLines: 3),
//         const SizedBox(height: 12),
//         TextFormField(controller: _companyCtrl, decoration: _inputDecoration('Company', Icons.business)),
//         const SizedBox(height: 12),
//         TextFormField(controller: _jobCtrl, decoration: _inputDecoration('Job', Icons.work)),
//         const SizedBox(height: 12),
//         Row(children: [Expanded(child: TextFormField(controller: _countryCtrl, decoration: _inputDecoration('Country', Icons.flag))), const SizedBox(width: 12), Expanded(child: TextFormField(controller: _phoneCtrl, decoration: _inputDecoration('Phone', Icons.phone), keyboardType: TextInputType.phone))]),
//         const SizedBox(height: 12),
//         TextFormField(controller: _addressCtrl, decoration: _inputDecoration('Address', Icons.home)),
//         const SizedBox(height: 12),
//         TextFormField(controller: _emailCtrl, decoration: _inputDecoration('Email', Icons.email), keyboardType: TextInputType.emailAddress, validator: _emailValidator),
//         const SizedBox(height: 20),
//         AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: _isSavingProfile ? ElevatedButton(onPressed: null, child: const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))) : ElevatedButton(onPressed: _saveProfile, child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Save Changes', style: TextStyle(fontSize: 16))))),
//         const SizedBox(height: 30),
//       ]),
//     );
//   }

//   Widget _buildPasswordPanelContent() {
//     return Form(
//       key: _pwFormKey,
//       child: Column(children: [
//         TextFormField(controller: _currentPwCtrl, decoration: _inputDecoration('Current password', Icons.lock), obscureText: true, validator: (v) => (v == null || v.isEmpty) ? 'Enter current password' : null),
//         const SizedBox(height: 12),
//         TextFormField(controller: _newPwCtrl, decoration: _inputDecoration('New password', Icons.lock_outline), obscureText: true, validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 chars' : null),
//         const SizedBox(height: 12),
//         TextFormField(controller: _confirmPwCtrl, decoration: _inputDecoration('Confirm password', Icons.lock_outline), obscureText: true, validator: (v) => (v == null || v != _newPwCtrl.text) ? 'Passwords do not match' : null),
//         const SizedBox(height: 20),
//         AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: _isChangingPassword ? ElevatedButton(onPressed: null, child: const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))) : ElevatedButton(onPressed: _changePassword, child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Change Password', style: TextStyle(fontSize: 16))))),
//       ]),
//     );
//   }

//   // -------------------------
//   // Small helpers & widgets
//   // -------------------------
//   InputDecoration _inputDecoration(String label, IconData icon) {
//     return InputDecoration(labelText: label, prefixIcon: Icon(icon), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF6C63FF)), borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14));
//   }

//   String? _emailValidator(String? email) {
//     if (email == null || email.isEmpty) return null;
//     final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
//     if (!regex.hasMatch(email)) return 'Please enter valid email';
//     return null;
//   }

//   Widget _propertyCard(Map<String, dynamic> p) {
//     final img = p['image'] as String?;
//     final title = p['title'] ?? 'Property';
//     final location = p['location'] ?? '-';
//     final price = p['price'] != null ? '₦${p['price']}' : '-';
//     final appreciation = p['appreciation_percent'] ?? 0;

//     return GestureDetector(onTap: () => _showPropertyDetails(p), child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: const Offset(0, 8))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: img != null ? CachedNetworkImage(imageUrl: img, height: 120, width: double.infinity, fit: BoxFit.cover, placeholder: (c, u) => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))), errorWidget: (c, u, e) => Container(height: 120, color: Colors.grey[200], child: const Icon(Icons.house, size: 36, color: Colors.grey))) : Container(height: 120, color: Colors.grey[200], child: const Icon(Icons.house, size: 36, color: Colors.grey))),
//       Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//         Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//         const SizedBox(height: 6),
//         Text(location, style: const TextStyle(color: Colors.grey, fontSize: 12)),
//         const SizedBox(height: 8),
//         Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//           Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
//           Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: appreciation >= 0 ? Colors.green[50] : Colors.red[50], borderRadius: BorderRadius.circular(8)), child: Row(children: [Icon(appreciation >= 0 ? Icons.trending_up : Icons.trending_down, size: 16, color: appreciation >= 0 ? Colors.green : Colors.red), const SizedBox(width: 6), Text('${appreciation.toString()}%', style: TextStyle(color: appreciation >= 0 ? Colors.green[800] : Colors.red[800], fontWeight: FontWeight.bold))])),
//         ])
//       ])),
//     ])));
//   }

//   void _showPropertyDetails(Map<String, dynamic> property) {
//     showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) {
//       return DraggableScrollableSheet(expand: false, initialChildSize: 0.7, minChildSize: 0.3, maxChildSize: 0.95, builder: (_, controller) {
//         return Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))), child: ListView(controller: controller, children: [
//           Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(property['title'] ?? 'Property', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]),
//           const SizedBox(height: 8),
//           property['image'] != null ? CachedNetworkImage(imageUrl: property['image'], height: 180, fit: BoxFit.cover) : Container(height: 180, color: Colors.grey[200]),
//           const SizedBox(height: 12),
//           Text(property['description'] ?? '-', style: const TextStyle(height: 1.5)),
//           const SizedBox(height: 12),
//           Text('Location: ${property['location'] ?? '-'}'),
//           const SizedBox(height: 8),
//           Text('Price: ₦${property['price'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold)),
//           const SizedBox(height: 16),
//           ElevatedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.message), label: const Text('Contact Agent')),
//         ]));
//       });
//     });
//   }
// }

// // -----------------------
// // Sparkline remains unchanged but kept tidy
// // -----------------------
// class _Sparkline extends StatelessWidget {
//   final List<double> values;
//   const _Sparkline({required this.values});

//   @override
//   Widget build(BuildContext context) {
//     if (values.isEmpty) return const SizedBox.shrink();
//     final maxVal = values.reduce(max);
//     final minVal = values.reduce(min);
//     final range = maxVal - minVal == 0 ? 1 : maxVal - minVal;

//     return LayoutBuilder(builder: (context, constraints) {
//       final width = constraints.maxWidth;
//       return CustomPaint(size: Size(width, constraints.maxHeight), painter: _SparklinePainter(values: values, minVal: minVal.toDouble(), range: range.toDouble()));
//     });
//   }
// }

// class _SparklinePainter extends CustomPainter {
//   final List<double> values;
//   final double minVal;
//   final double range;

//   _SparklinePainter({required this.values, required this.minVal, required this.range});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.4..color = const Color(0xFF6C63FF)..isAntiAlias = true;
//     final path = Path();
//     for (var i = 0; i < values.length; i++) {
//       final dx = (i / (values.length - 1)) * size.width;
//       final normalized = (values[i] - minVal) / range;
//       final dy = (1 - normalized) * size.height;
//       if (i == 0) path.moveTo(dx, dy);
//       else path.lineTo(dx, dy);
//     }
//     final shadow = Paint()..style = PaintingStyle.stroke..strokeWidth = 8..color = const Color(0xFF6C63FF).withOpacity(0.08)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
//     canvas.drawPath(path, shadow);
//     canvas.drawPath(path, paint);
//     final dotPaint = Paint()..color = const Color(0xFF6C63FF);
//     for (var i = 0; i < values.length; i++) {
//       final dx = (i / (values.length - 1)) * size.width;
//       final normalized = (values[i] - minVal) / range;
//       final dy = (1 - normalized) * size.height;
//       canvas.drawCircle(Offset(dx, dy), 3.2, dotPaint);
//     }
//   }

//   @override
//   bool shouldRepaint(covariant _SparklinePainter oldDelegate) => oldDelegate.values != values;
// }

// // -----------------------
// // small re-usable detail row
// // -----------------------
// class _DetailRow extends StatelessWidget {
//   final String label;
//   final String value;
//   final IconData icon;
//   const _DetailRow({required this.label, required this.value, required this.icon});

//   @override
//   Widget build(BuildContext context) {
//     return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       Icon(icon, size: 20, color: const Color(0xFF6C63FF)),
//       const SizedBox(width: 12),
//       Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))])),
//     ]);
//   }
// }


