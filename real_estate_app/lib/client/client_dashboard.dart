import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:real_estate_app/client/client_bottom_nav.dart';
import 'package:real_estate_app/shared/app_layout.dart';
import 'package:real_estate_app/shared/app_side.dart';
import 'package:real_estate_app/core/api_service.dart';

class ClientDashboard extends StatefulWidget {
  final String token;
  const ClientDashboard({Key? key, required this.token}) : super(key: key);

  @override
  _ClientDashboardState createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard>
    with TickerProviderStateMixin {
  final ApiService _api = ApiService();

  bool _loading = true;
  String? _error;
  String? _clientName;

  Future<void> _fetchClientName() async {
    try {
      // make profile dynamic so runtime type checks are allowed
      final dynamic profile = await _api.getClientDetailByToken(token: widget.token);

      if (!mounted) return;

      String? name;

      if (profile is Map<String, dynamic>) {
        // try common name/email keys
        name = (profile['full_name'] ??
                profile['fullName'] ??
                profile['name'] ??
                profile['display_name'] ??
                profile['displayName'] ??
                profile['email'])
            ?.toString();

        // fallback to first + last
        if (name == null || name.trim().isEmpty) {
          final first = (profile['first_name'] ?? profile['firstName'])?.toString();
          final last = (profile['last_name'] ?? profile['lastName'])?.toString();
          if ((first?.isNotEmpty == true) || (last?.isNotEmpty == true)) {
            name = '${first ?? ''} ${last ?? ''}'.trim();
          }
        }

        // try nested shapes like { user: { ... } } or { client: { ... } }
        if (name == null || name.trim().isEmpty) {
          if (profile['user'] is Map) {
            final u = Map<String, dynamic>.from(profile['user'] as Map);
            name = (u['full_name'] ?? u['name'] ?? u['email'])?.toString();
          } else if (profile['client'] is Map) {
            final c = Map<String, dynamic>.from(profile['client'] as Map);
            name = (c['full_name'] ?? c['name'] ?? c['email'])?.toString();
          }
        }
      } else if (profile is String) {
        // sometimes the API might (unexpectedly) return a plain string
        name = profile;
      }

      final finalName = (name != null && name.trim().isNotEmpty) ? name.trim() : null;

      if (!mounted) return;
      setState(() {
        _clientName = finalName;
      });
    } catch (e, st) {
      debugPrint('Failed to fetch client name: $e\n$st');
      // leave _clientName null so the UI falls back to "Client Dashboard"
    }
  }

  Map<String, dynamic> _data = {};

  List<Map<String, dynamic>> _activePromos = [];
  List<Map<String, dynamic>> _latestValue = [];

  // Price explorer controls
  final TextEditingController _priceSearchCtr = TextEditingController();
  String _priceSort = 'newest';
  bool _promoOnly = false;

  late final AnimationController _staggerController;
  late final Animation<double> _staggerAnim;
  late final AnimationController _pulseController;

  // Auto carousel for promotions
  Timer? _promoCarouselTimer;
  final PageController _promoPageController =
      PageController(viewportFraction: 0.92);
  int _currentPromoIndex = 0;

  final NumberFormat _ngnFmt =
      NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _staggerAnim =
        CurvedAnimation(parent: _staggerController, curve: Curves.easeOutCubic);
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    // _fetchDashboard();
    _fetchClientName().whenComplete(() => _fetchDashboard());
  }

  @override
  void dispose() {
    _priceSearchCtr.dispose();
    _staggerController.dispose();
    _pulseController.dispose();
    _promoPageController.dispose();
    _promoCarouselTimer?.cancel();
    super.dispose();
  }
  

  // Start auto carousel for promotions
  void _startPromoCarousel() {
    _promoCarouselTimer?.cancel();
    _promoCarouselTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_activePromos.isEmpty) return;

      int nextPage = _currentPromoIndex + 1;
      if (nextPage >= _activePromos.length) {
        nextPage = 0;
      }

      if (_promoPageController.hasClients) {
        _promoPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _fetchDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await _api.getClientDashboardData(widget.token);
      // expected keys: total_properties, fully_paid_allocations, not_fully_paid_allocations, active_promotions, latest_value
      setState(() {
        _data = resp;
        _activePromos =
            List<Map<String, dynamic>>.from(resp['active_promotions'] ?? []);
        _latestValue =
            List<Map<String, dynamic>>.from(resp['latest_value'] ?? []);
      });
      _staggerController.forward();

      // Start the carousel after data is loaded
      if (_activePromos.isNotEmpty) {
        _startPromoCarousel();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // Filter + sort logic similar to Django's JS
  List<Map<String, dynamic>> _filteredPriceCards() {
    final q = _priceSearchCtr.text.trim().toLowerCase();
    List<Map<String, dynamic>> cards = List.from(_latestValue);

    if (_promoOnly) cards = cards.where((c) => c['promo'] != null).toList();
    if (q.isNotEmpty) {
      cards = cards.where((c) {
        final estate = (c['estate_name'] ?? '').toString().toLowerCase();
        final size = (c['plot_unit'] != null && c['plot_unit'] is Map
            ? (c['plot_unit']['size'] ?? '').toString().toLowerCase()
            : '');
        return estate.contains(q) || size.contains(q);
      }).toList();
    }

    int cmpPercent(Map a) => ((a['percent_change'] ?? 0) as num).toInt();
    double curVal(Map a) => (a['current'] ?? 0).toDouble();

    cards.sort((a, b) {
      switch (_priceSort) {
        case 'biggest_up':
          return (b['percent_change'] ?? 0).compareTo(a['percent_change'] ?? 0);
        case 'biggest_down':
          return (a['percent_change'] ?? 0).compareTo(b['percent_change'] ?? 0);
        case 'highest_price':
          return curVal(b).compareTo(curVal(a));
        case 'promo_first':
          final ap =
              (b['promo'] != null ? 1 : 0) - (a['promo'] != null ? 1 : 0);
          if (ap != 0) return ap;
          return (b['percent_change'] ?? 0).compareTo(a['percent_change'] ?? 0);
        case 'newest':
        default:
          final ae = (a['effective'] ?? '').toString();
          final be = (b['effective'] ?? '').toString();
          return be.compareTo(ae);
      }
    });

    return cards;
  }

  String _formatNGN(dynamic v) {
    if (v == null) return '—';
    try {
      final numVal = (v is num) ? v : double.tryParse(v.toString()) ?? 0;
      return _ngnFmt.format(numVal);
    } catch (e) {
      return v.toString();
    }
  }

  bool _isFutureDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return date.isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  String _formatDateDisplay(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _openPromoDetail(Map<String, dynamic> promo) async {
    // push to PromotionDetailPage
    final id = (promo['id'] as num?)?.toInt();
    if (id == null) return;
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PromotionDetailPage(token: widget.token, promoId: id)));
  }

  Future<void> _openPriceDetail(int id) async {
    showDialog(
        context: context,
        builder: (_) => PriceDetailDialog(
            api: _api, token: widget.token, priceHistoryId: id));
  }

  Widget _buildTopStats() {
    final total = (_data['total_properties'] ?? 0).toString();
    final fully = (_data['fully_paid_allocations'] ?? 0).toString();
    final notFully = (_data['not_fully_paid_allocations'] ?? 0).toString();

    Widget card(String title, String value, IconData icon, Color color) {
      return TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 600),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) {
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * 20),
              child: child,
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.12)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ]),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: color))
              ])
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth > 800;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8),
        child: wide
            ? Row(
                children: [
                  Expanded(
                      child: card('My Properties Purchased', total,
                          Icons.shopping_cart, Colors.indigo)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: card('Fully Paid & Allocated', fully,
                          Icons.account_balance_wallet, Colors.teal)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: card('Not Fully Paid', notFully, Icons.money_off,
                          Colors.orange)),
                ],
              )
            : Column(children: [
                card('My Properties Purchased', total, Icons.shopping_cart,
                    Colors.indigo),
                const SizedBox(height: 12),
                card('Fully Paid & Allocated', fully,
                    Icons.account_balance_wallet, Colors.teal),
                const SizedBox(height: 12),
                card('Not Fully Paid', notFully, Icons.money_off, Colors.orange)
              ]),
      );
    });
  }

  Widget _buildPromotionsCarousel() {
    if (_activePromos.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
            padding: const EdgeInsets.all(24),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.local_offer, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              const Text('No active promotions right now',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Check back later or explore all estates.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                EstatesListPage(token: widget.token))),
                    child: const Text('Browse estates'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => PromotionsListPage(
                                token: widget.token, filter: 'past'))),
                    child: const Text('See past promos'),
                  ),
                ],
              )
            ])),
      );
    }

    return SizedBox(
      height: 240,
      child: PageView.builder(
        controller: _promoPageController,
        onPageChanged: (index) {
          setState(() {
            _currentPromoIndex = index;
          });
        },
        itemCount: _activePromos.length,
        itemBuilder: (ctx, i) {
          final promo = _activePromos[i];
          final estates = List.from(promo['estates'] ?? []);
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 400 + (i * 100)),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, t, child) {
              return Opacity(
                opacity: t,
                child: Transform.scale(
                  scale: 0.95 + (t * 0.05),
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.deepPurple.shade50,
                            Colors.blue.shade50,
                          ])),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.deepOrange.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4))
                                ]),
                            child: const Icon(Icons.local_offer,
                                size: 36, color: Colors.deepOrange),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  promo['name'] ?? 'Promotion',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  promo['description'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (var e in estates.take(3))
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurple
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          e['name'] ?? '',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.deepPurple.shade700,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    if (estates.length > 3)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '+${estates.length - 3} more',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      )
                                  ],
                                )
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                        colors: [
                                          Color(0xffff7a7a),
                                          Color(0xffffb46b)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                          color:
                                              Colors.redAccent.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4))
                                    ]),
                                child: Text(
                                  '-${promo['discount'] ?? 0}%',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                promo['end'] ?? '',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              )
                            ],
                          )
                        ]),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: () => _openPromoDetail(promo),
                            child: const Text('View Promo'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () =>
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => EstatesListPage(
                                          token: widget.token,
                                          promoId: promo['id'],
                                        ))),
                            child: const Text('View Estates'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  DateTime? _parseDateDynamic(dynamic v) {
    if (v == null) return null;
    try {
      if (v is DateTime) return v;
      if (v is int) {
        if (v > 1000000000000) return DateTime.fromMillisecondsSinceEpoch(v);
        return DateTime.fromMillisecondsSinceEpoch(v * 1000);
      }
      final s = v.toString();
      return DateTime.parse(s);
    } catch (e) {
      try {
        final s = v.toString().split('T').first;
        final parts = s.split(RegExp(r'[-/]'));
        if (parts.length >= 3) {
          final y = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          final d = int.parse(parts[2]);
          return DateTime(y, m, d);
        }
      } catch (_) {}
    }
    return null;
  }

  bool isCurrentUpdate(Map<String, dynamic> u) {
    final effRaw = u['effective'];
    final effDt = _parseDateDynamic(effRaw);
    if (effDt == null) return false;
    final now = DateTime.now();
    final effDate = DateTime(effDt.year, effDt.month, effDt.day);
    final today = DateTime(now.year, now.month, now.day);
    return !effDate.isAfter(today);
  }

  List<Map<String, dynamic>> pickLatestPerPlotUnit(
      List<Map<String, dynamic>> updates) {
    final Map<String, List<Map<String, dynamic>>> buckets = {};
    for (final u in updates) {
      dynamic pu = u['plot_unit'];
      String key;
      if (pu == null) {
        final est = (u['estate_name'] ?? 'estate').toString();
        final size = (u['plot_unit'] is Map)
            ? (u['plot_unit']['size'] ?? '')
            : (u['size'] ?? '');
        key = '$est|$size';
      } else if (pu is Map && pu['id'] != null) {
        key = pu['id'].toString();
      } else {
        key = pu.toString();
      }
      buckets.putIfAbsent(key, () => []).add(u);
    }

    final List<Map<String, dynamic>> out = [];
    buckets.forEach((key, list) {
      list.sort((a, b) {
        final aEff = _parseDateDynamic(a['effective']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bEff = _parseDateDynamic(b['effective']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final cmpEff = bEff.compareTo(aEff); // newest effective first
        if (cmpEff != 0) return cmpEff;
        final aRec = _parseDateDynamic(a['recorded_at']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bRec = _parseDateDynamic(b['recorded_at']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bRec.compareTo(aRec); // newest recorded_at first
      });
      out.add(list.first);
    });

    // optional: sort final results by recorded_at desc
    out.sort((a, b) {
      final ar = _parseDateDynamic(a['recorded_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final br = _parseDateDynamic(b['recorded_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return br.compareTo(ar);
    });

    return out;
  }

  Widget _buildPriceExplorer() {
    final cards = _filteredPriceCards();

    final List<Map<String, dynamic>> currentOnly =
        cards.where((c) => isCurrentUpdate(c)).toList();

    final uniqueCards = pickLatestPerPlotUnit(currentOnly);
    final displayList = uniqueCards;

    return Column(
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
            child: isWide
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _priceSearchCtr,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: 'Search estate or size',
                            isDense: true,
                            contentPadding: const EdgeInsets.all(14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade400),
                            ),
                            filled: true,
                            fillColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade50,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade800
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButton<String>(
                          value: _priceSort,
                          items: const [
                            DropdownMenuItem(
                                value: 'newest', child: Text('Newest')),
                            DropdownMenuItem(
                                value: 'biggest_up',
                                child: Text('Largest increase')),
                            DropdownMenuItem(
                                value: 'biggest_down',
                                child: Text('Largest decrease')),
                            DropdownMenuItem(
                                value: 'highest_price',
                                child: Text('Highest price')),
                            DropdownMenuItem(
                                value: 'promo_first',
                                child: Text('Promo first'))
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _priceSort = v);
                          },
                          underline: const SizedBox(),
                          borderRadius: BorderRadius.circular(12),
                          style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Promo only'),
                        selected: _promoOnly,
                        onSelected: (v) => setState(() => _promoOnly = v),
                        checkmarkColor: Colors.white,
                        selectedColor: Theme.of(context).colorScheme.primary,
                      )
                    ],
                  )
                : Column(
                    children: [
                      TextField(
                        controller: _priceSearchCtr,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search estate or size',
                          isDense: true,
                          contentPadding: const EdgeInsets.all(14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          filled: true,
                          fillColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade50,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButton<String>(
                                value: _priceSort,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'newest', child: Text('Newest')),
                                  DropdownMenuItem(
                                      value: 'biggest_up',
                                      child: Text('Largest increase')),
                                  DropdownMenuItem(
                                      value: 'biggest_down',
                                      child: Text('Largest decrease')),
                                  DropdownMenuItem(
                                      value: 'highest_price',
                                      child: Text('Highest price')),
                                  DropdownMenuItem(
                                      value: 'promo_first',
                                      child: Text('Promo first'))
                                ],
                                onChanged: (v) {
                                  if (v != null) setState(() => _priceSort = v);
                                },
                                underline: const SizedBox(),
                                borderRadius: BorderRadius.circular(12),
                                style: TextStyle(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Promo only'),
                            selected: _promoOnly,
                            onSelected: (v) => setState(() => _promoOnly = v),
                            checkmarkColor: Colors.white,
                            selectedColor:
                                Theme.of(context).colorScheme.primary,
                          )
                        ],
                      )
                    ],
                  ),
          );
        }),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('${displayList.length} updates',
                style: const TextStyle(color: Colors.grey)),
          ),
        ),

        const SizedBox(height: 8),

        // Grid of cards - let GridView size itself (shrinkWrap: true)
        AnimatedBuilder(
          animation: _staggerAnim,
          builder: (context, _) {
            return LayoutBuilder(builder: (ctx, cons) {
              final cols =
                  cons.maxWidth > 1000 ? 3 : (cons.maxWidth > 600 ? 2 : 1);
              final cardHeight = 220.0;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: displayList.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: cardHeight,
                  ),
                  itemBuilder: (ctx, i) {
                    final c = displayList[i];
                    return _buildPriceCard(
                        c); // now guaranteed to be current + deduped
                  },
                ),
              );
            });
          },
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildPriceCard(Map<String, dynamic> c) {
    if (!isCurrentUpdate(c)) return const SizedBox.shrink();
    final promo = c['promo'];
    final percent = (c['percent_change'] ?? 0) is num
        ? (c['percent_change'] as num).toDouble()
        : 0.0;
    final up = percent >= 0;
    final estateName = c['estate_name'] ?? '-';
    final plotSize = (c['plot_unit'] != null && c['plot_unit'] is Map)
        ? (c['plot_unit']['size'] ?? '-').toString()
        : '-';
    final effectiveDate = c['effective']?.toString() ?? '';
    final isFutureDate = _isFutureDate(effectiveDate);

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _openPriceDetail((c['id'] as num).toInt()),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                (up ? Colors.green.shade50 : Colors.red.shade50)
                    .withOpacity(0.35),
              ],
            ),
          ),
          padding: const EdgeInsets.all(10), // slightly smaller
          child: LayoutBuilder(builder: (context, constraints) {
            final maxBadgeWidth = constraints.maxWidth * 0.26;
            final priceColumnWidth = constraints.maxWidth * 0.56;

            return Column(
              mainAxisSize: MainAxisSize
                  .min, // ensure the column doesn't force extra space
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            estateName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4), // reduced
                          Text(
                            plotSize,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (promo != null) ...[
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                            maxWidth: maxBadgeWidth, maxHeight: 32),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xffff7a7a), Color(0xffffb46b)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '-${promo['discount']}% Off',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      )
                    ]
                  ],
                ),

                const SizedBox(height: 8), // reduced

                // Middle: Prices + percent/effective
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left prices
                    SizedBox(
                      width: priceColumnWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (promo != null && c['promo_price'] != null) ...[
                            Text(
                              _formatNGN(c['promo_price']),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  color: Colors.deepOrange),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _formatNGN(c['current']),
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ] else
                            Text(
                              _formatNGN(c['current']),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  color: Colors.green),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 6),
                          Text(
                            'Prev: ${_formatNGN(c['previous'])}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Right: percent + effective
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (percent != null)
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                                maxWidth: 78, maxHeight: 36),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: up
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: up ? Colors.green : Colors.red,
                                    width: 1),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${percent.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: up
                                        ? Colors.green.shade800
                                        : Colors.red.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                              maxWidth: 110, maxHeight: 48),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: isFutureDate
                                  ? const Color(0xFFecffd9)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isFutureDate
                                    ? const Color(0xFF0b6b2e).withOpacity(0.08)
                                    : Colors.grey.withOpacity(0.12),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    isFutureDate
                                        ? 'Effective on'
                                        : 'Effective since',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isFutureDate
                                          ? const Color(0xFF0b6b2e)
                                          : const Color(0xFF495057),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _formatDateDisplay(effectiveDate),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isFutureDate
                                          ? const Color(0xFF0b6b2e)
                                          : const Color(0xFF495057),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                if (c['notes'] != null && c['notes'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      c['notes'].toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic),
                    ),
                  ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _openPriceDetail((c['id'] as num).toInt()),
                    style: TextButton.styleFrom(
                        minimumSize: const Size(0, 28),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 0)),
                    child: const Text(
                      'View Details',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayName = (_clientName != null && _clientName!.isNotEmpty)
        ? _clientName!
        : 'Client Dashboard';

    return AppLayout(
      pageTitle: 'Dashboard',
      token: widget.token,
      side: AppSide.client,
      child: Scaffold(
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        bottomNavigationBar:
            ClientBottomNav(currentIndex: 0, token: widget.token, chatBadge: 0),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _fetchDashboard,
            color: Theme.of(context).colorScheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(children: [
                // header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 28,
                                  color: isDark ? Colors.white : Colors.grey.shade800,
                                ) ??
                                TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 28,
                                  color: isDark ? Colors.white : Colors.grey.shade800,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Home / Dashboard',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          )
                        ],
                      ),
                    ),

                  ]),
                ),

                if (_loading)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(
                            Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Failed to load: $_error',
                              style: TextStyle(color: Colors.red.shade800),
                            ),
                          ),
                          TextButton(
                            onPressed: _fetchDashboard,
                            child: Text(
                              'Retry',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                // stats
                if (!_loading) _buildTopStats(),

                // active promos
                if (!_loading)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Active Promotional Offers',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800, fontSize: 20),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Running promotions — limited time',
                                    style: TextStyle(color: Colors.grey),
                                  )
                                ],
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            PromotionsListPage(token: widget.token))),
                                child: const Text('View All'),
                              )
                            ],
                          ),
                        ),
                        _buildPromotionsCarousel()
                      ],
                    ),
                  ),

                // price explorer
                if (!_loading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Latest Price Increments',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800, fontSize: 20),
                              ),
                              TextButton.icon(
                                onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            PromotionsListPage(token: widget.token))),
                                icon: const Icon(Icons.local_offer_outlined),
                                label: const Text('Promotions'),
                              )
                            ],
                          ),
                        ),
                        _buildPriceExplorer()
                      ],
                    ),
                  ),

                const SizedBox(height: 24)
              ]),
            ),
          ),
        ),
      ),
    );
  }

}

// ---------------------------
// Price Detail Dialog
// ---------------------------
class PriceDetailDialog extends StatefulWidget {
  final ApiService api;
  final String token;
  final int priceHistoryId;

  const PriceDetailDialog(
      {Key? key,
      required this.api,
      required this.token,
      required this.priceHistoryId})
      : super(key: key);

  @override
  _PriceDetailDialogState createState() => _PriceDetailDialogState();
}

class _PriceDetailDialogState extends State<PriceDetailDialog>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  Map<String, dynamic>? _data;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _load();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await widget.api
          .getPriceUpdateById(widget.priceHistoryId, token: widget.token);
      setState(() {
        _data = resp;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : (_error != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: Colors.red.shade400),
                        const SizedBox(height: 16),
                        Text('Error: $_error',
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        )
                      ],
                    )
                  : ScaleTransition(
                      scale: _animation,
                      child: _buildContent(),
                    )),
        ),
      ),
    );
  }

  String _formatDateOnly(dynamic v) {
    if (v == null) return '-';
    try {
      if (v is String) {
        final dt = DateTime.tryParse(v);
        if (dt != null) return DateFormat('yyyy-MM-dd').format(dt.toLocal());
        // fallback: strip time if it looks like "2025-08-29T12:34:56"
        if (v.contains('T')) return v.split('T').first;
        return v;
      }
      if (v is DateTime) return DateFormat('yyyy-MM-dd').format(v.toLocal());
      return v.toString();
    } catch (_) {
      return v.toString();
    }
  }

  Widget _buildContent() {
    if (_data == null) return const SizedBox.shrink();

    final promo = (_data!['promo'] is Map)
        ? Map<String, dynamic>.from(_data!['promo'])
        : null;
    final dynamic promoPriceRaw =
        _data!['promo_price'] ?? _data!['promo_price'];
    final bool promoActive = promo != null && promo['active'] == true;
    final int? discountPct = promo != null &&
            (promo['discount_pct'] is num || promo['discount'] is num)
        ? ((promo['discount_pct'] ?? promo['discount']) as num).round()
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row with optional promo badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price Update Details',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Title (takes remaining space, truncates if too long)
                        Expanded(
                          child: Text(
                            _data!['estate_name'] ?? '',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(width: 8),

                        if (promoActive || discountPct != null)
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 110),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xffff7a7a),
                                    Color(0xffffb46b)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.redAccent.withOpacity(0.12),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2))
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      '-${discountPct ?? promo?['discount'] ?? ''}% Off',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    )
                  ]),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            )
          ],
        ),

        const SizedBox(height: 8),
        Text(
          'Recorded: ${_formatDateOnly(_data!['recorded_at'])}',
          style: const TextStyle(color: Colors.grey),
        ),

        const SizedBox(height: 16),

        // Price detail box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildDetailRow('Previous', _format(_data!['previous'])),
              const SizedBox(height: 8),
              if ((promoActive || promoPriceRaw != null) &&
                  (_data!['current'] != null))
                _buildCurrentWithPromo(
                  current: _format(_data!['current']),
                  promoPrice:
                      promoPriceRaw != null ? _format(promoPriceRaw) : null,
                )
              else
                _buildDetailRow('Current', _format(_data!['current'])),
              const SizedBox(height: 8),
              _buildDetailRow(
                'Change',
                '${(_data!['percent_change'] ?? '-').toString()}%',
                isPercent: true,
                percent: (_data!['percent_change'] as num?)?.toDouble(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        const Text(
          'Notes',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          _data!['notes'] ?? '—',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        )
      ],
    );
  }

  Widget _buildCurrentWithPromo({required String current, String? promoPrice}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Current',
                style: TextStyle(fontWeight: FontWeight.w600)),
            Text(
              current,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.lineThrough,
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (promoPrice != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Promo price',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text(
                promoPrice,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Colors.green,
                ),
              ),
            ],
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isPercent = false, double? percent}) {
    Color color = Colors.black;
    if (isPercent && percent != null) {
      color = percent >= 0 ? Colors.green : Colors.red;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: color,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  String _format(dynamic v) {
    if (v == null) return '—';
    try {
      final numVal = (v is num) ? v : double.parse(v.toString());
      return NumberFormat.currency(
              locale: 'en_NG', symbol: '₦', decimalDigits: 0)
          .format(numVal);
    } catch (_) {
      return v.toString();
    }
  }
}

// ---------------------------
// Promotions List Page
// ---------------------------
class PromotionsListPage extends StatefulWidget {
  final String token;
  final String? filter;
  const PromotionsListPage({Key? key, required this.token, this.filter})
      : super(key: key);

  @override
  _PromotionsListPageState createState() => _PromotionsListPageState();
}

class _PromotionsListPageState extends State<PromotionsListPage>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  bool _loading = true;
  String? _error;
  List<dynamic> _active = [];
  Map<String, dynamic>? _paginated;
  int _page = 1;
  String _filter = 'all';
  String _q = '';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _filter = widget.filter ?? 'all';
    _load();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _load({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await _api.listPromotions(
          token: widget.token, filter: _filter, q: _q, page: page);
      setState(() {
        _active = resp['active_promotions'] ?? [];
        _paginated = resp['promotions'];
        _page = page;
      });
      _animationController.forward();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotions'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onBackground,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error'))
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        if (_active.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Currently active',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 18),
                              ),
                              const SizedBox(height: 12),
                              ..._active.map((p) {
                                return FadeTransition(
                                  opacity: _animationController,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(-1, 0),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: _animationController,
                                      curve: Curves.easeOutCubic,
                                    )),
                                    child: Card(
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.all(16),
                                        leading: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.deepOrange.shade50,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.local_offer,
                                            color: Colors.deepOrange,
                                          ),
                                        ),
                                        title: Text(
                                          p['name'] ?? '',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700),
                                        ),
                                        subtitle: Text(
                                          p['description'] ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: Chip(
                                          label: Text(
                                            '-${p['discount']}%',
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                          backgroundColor: Colors.deepOrange,
                                        ),
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => PromotionDetailPage(
                                              token: widget.token,
                                              promoId: (p['id'] as num).toInt(),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        Expanded(
                          child: _buildPromotionsList(),
                        )
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildPromotionsList() {
    if (_paginated == null) return const SizedBox.shrink();
    final results = List.from(_paginated!['results'] ?? []);
    final pageNum = _paginated!['page'] ?? _page;
    final totalPages = _paginated!['total_pages'] ??
        (_paginated!['count'] != null
            ? ((_paginated!['count'] as int) / 12).ceil()
            : 1);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: results.length,
            itemBuilder: (ctx, i) {
              final p = results[i];
              final isActive = p['is_active'] ?? false;
              return FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(0.1 * i, 1.0, curve: Curves.easeIn),
                  ),
                ),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(0.1 * i, 1.0, curve: Curves.easeOut),
                    ),
                  ),
                  child: Opacity(
                    opacity: isActive ? 1.0 : 0.6,
                    child: Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.blue.shade50
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.local_offer_outlined,
                            color: isActive ? Colors.blue : Colors.grey,
                          ),
                        ),
                        title: Text(
                          p['name'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isActive ? null : Colors.grey,
                          ),
                        ),
                        subtitle: Text(
                          (p['description'] ?? '').toString().truncate(120),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isActive ? null : Colors.grey,
                          ),
                        ),
                        trailing: Chip(
                          label: Text(
                            '-${p['discount']}%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isActive ? null : 12,
                            ),
                          ),
                          backgroundColor: isActive ? Colors.blue : Colors.grey,
                        ),
                        onTap: isActive
                            ? () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PromotionDetailPage(
                                      token: widget.token,
                                      promoId: (p['id'] as num).toInt(),
                                    ),
                                  ),
                                )
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: pageNum > 1
                  ? () {
                      _load(page: pageNum - 1);
                    }
                  : null,
            ),
            Text('Page $pageNum of $totalPages'),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: pageNum < totalPages
                  ? () {
                      _load(page: pageNum + 1);
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------
// Promotion Detail Page
// ---------------------------
class PromotionDetailPage extends StatefulWidget {
  final String token;
  final int promoId;
  const PromotionDetailPage(
      {Key? key, required this.token, required this.promoId})
      : super(key: key);

  @override
  _PromotionDetailPageState createState() => _PromotionDetailPageState();
}

class _PromotionDetailPageState extends State<PromotionDetailPage>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _promo;
  late final AnimationController _animationController;

  late final Animation<double> _headerFade;
  late final Animation<double> _chipPulse;

  int? _expandedEstateId;

  final Map<int, GlobalKey> _estateKeys = {};
  final ScrollController _listController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _headerFade = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );

    _chipPulse = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.92, end: 1.05)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 60),
      TweenSequenceItem(
          tween: Tween(begin: 1.05, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 40),
    ]).animate(CurvedAnimation(
        parent: _animationController, curve: const Interval(0.2, 0.5)));

    _load();
  }

  @override
  void dispose() {
    _listController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final resp =
          await _api.getPromotionDetail(widget.promoId, token: widget.token);
      setState(() => _promo = resp);
      await Future.delayed(const Duration(milliseconds: 120));
      _animationController.forward();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _toggleEstateExpansion(int estateId) {
    setState(() {
      if (_expandedEstateId == estateId) {
        _expandedEstateId = null;
      } else {
        _expandedEstateId = estateId;
      }
    });
  }

  String _formatNGN(dynamic v) {
    try {
      if (v == null) return '—';
      final numVal = v is num ? v : num.parse(v.toString());
      return NumberFormat.currency(
              locale: 'en_NG', symbol: '₦', decimalDigits: 0)
          .format(numVal);
    } catch (_) {
      return v?.toString() ?? '—';
    }
  }

  /// Expand & scroll to estate index (safe fallback if key not yet attached)
  Future<void> _scrollToEstateIndex(int index, int estateId) async {
    final key = _estateKeys[estateId];
    // Expand first so height is stable
    setState(() => _expandedEstateId = estateId);

    await Future.delayed(const Duration(milliseconds: 80));
    if (key != null && key.currentContext != null) {
      await Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
      return;
    }
    // fallback approximate scroll
    try {
      final approxHeight = 120.0;
      final offset = (index * (approxHeight + 16))
          .clamp(0.0, _listController.position.maxScrollExtent);
      await _listController.animateTo(offset,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic);
    } catch (_) {}
  }

  Widget _promoHeader(BuildContext context) {
    final name = _promo?['name'] ?? '';
    final discount = _promo?['discount'] ?? 0;
    final start = _promo?['start'] ?? '';
    final end = _promo?['end'] ?? '';

    final overlayStyle = SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: FadeTransition(
        opacity: _headerFade,
        child: AnimatedBuilder(
          animation: _chipPulse,
          builder: (ctx, child) {
            final topPadding = MediaQuery.of(context).padding.top;
            return Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16, 16 + topPadding, 16, 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.18),
                    Colors.white.withOpacity(0.95)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.2) ??
                              const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Valid: $start → $end',
                          style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.grey[600]) ??
                              TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: _chipPulse.value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFFF8A65), Color(0xFFFFD180)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('-$discount% OFF',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _promoDescription(BuildContext context) {
    final desc = _promo?['description'] ?? '';

    // keep previous behavior: tapping description scrolls to first estate
    void onDescriptionTap() {
      final estates = (_promo?['estates'] as List?) ?? [];
      if (estates.isEmpty) return;
      final first = Map<String, dynamic>.from(estates[0] as Map);
      final estateId = first['id'] as int;
      _scrollToEstateIndex(0, estateId);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InkWell(
              onTap: onDescriptionTap,
              borderRadius: BorderRadius.circular(6),
              child: AnimatedOpacity(
                opacity: _animationController.value < 0.2 ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 400),
                child: Text(
                  desc.isNotEmpty ? desc : '(No description provided)',
                  style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontSize: 15, height: 1.45) ??
                      const TextStyle(fontSize: 15, height: 1.45),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutBack,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => EstatesListPage(
                        token: widget.token,
                      ))),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Browse estates'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotion details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onBackground,
        systemOverlayStyle:
            SystemUiOverlayStyle.dark, // ensures status bar icons contrast
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error'))
                : Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _promoHeader(context),
                        const SizedBox(height: 12),
                        _promoDescription(context),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              'Applies to estates',
                              style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800) ??
                                  const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            if ((_promo?['estates'] as List?)?.isNotEmpty ??
                                false)
                              Text(
                                '(${(_promo!['estates'] as List).length})',
                                style: TextStyle(color: Colors.grey[600]),
                              )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: LayoutBuilder(builder: (ctx, cons) {
                            final estates = (_promo?['estates'] as List?) ?? [];
                            if (estates.isEmpty) {
                              return Center(
                                  child: Text(
                                'No estates attached to this promotion',
                                style: TextStyle(color: Colors.grey[700]),
                              ));
                            }

                            return ListView.builder(
                              controller: _listController,
                              itemCount: estates.length,
                              itemBuilder: (context, i) {
                                final e = Map<String, dynamic>.from(
                                    estates[i] as Map);
                                final estateId = e['id'] as int;
                                final isExpanded =
                                    _expandedEstateId == estateId;
                                final key = _estateKeys.putIfAbsent(
                                    estateId, () => GlobalKey());

                                final start = 0.15 + (i * 0.06);
                                final end = (start + 0.45).clamp(0.0, 1.0);
                                final itemAnim = CurvedAnimation(
                                  parent: _animationController,
                                  curve: Interval(start, end,
                                      curve: Curves.easeOut),
                                );

                                return FadeTransition(
                                  opacity: itemAnim,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                            begin: const Offset(-0.25, 0),
                                            end: Offset.zero)
                                        .animate(itemAnim),
                                    child: ScaleTransition(
                                      scale:
                                          Tween<double>(begin: 0.98, end: 1.0)
                                              .animate(itemAnim),
                                      child: Card(
                                        key: key,
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        elevation: 3,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Column(
                                            children: [
                                              ListTile(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 12),
                                                leading: Container(
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: const Icon(
                                                      Icons.apartment,
                                                      color: Colors.blue),
                                                ),
                                                title: Text(e['name'] ?? '',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700)),
                                                subtitle: Text(
                                                    e['location'] ?? '',
                                                    style: TextStyle(
                                                        color:
                                                            Colors.grey[600])),
                                                trailing: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(isExpanded
                                                          ? Icons.expand_less
                                                          : Icons.expand_more),
                                                      onPressed: () =>
                                                          _toggleEstateExpansion(
                                                              estateId),
                                                    ),
                                                  ],
                                                ),
                                                onTap: () =>
                                                    _toggleEstateExpansion(
                                                        estateId),
                                              ),

                                              // NEW: clickable description label inside the estate card
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16),
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: TextButton.icon(
                                                    onPressed: () =>
                                                        _scrollToEstateIndex(
                                                            i, estateId),
                                                    icon: const Icon(
                                                        Icons.price_check,
                                                        size: 18),
                                                    label: const Text(
                                                      'CLICK TO VIEW PLOT PRICES',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .primary,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4),
                                                      alignment:
                                                          Alignment.centerLeft,
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              AnimatedCrossFade(
                                                firstChild:
                                                    const SizedBox.shrink(),
                                                secondChild:
                                                    _buildEstateSizes(e),
                                                crossFadeState: isExpanded
                                                    ? CrossFadeState.showSecond
                                                    : CrossFadeState.showFirst,
                                                duration: const Duration(
                                                    milliseconds: 420),
                                                firstCurve: Curves.easeOut,
                                                secondCurve: Curves.easeIn,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildEstateSizes(Map<String, dynamic> estate) {
    final sizes = List<Map<String, dynamic>>.from(estate['sizes'] ?? []);
    final discount = (_promo?['discount'] as num?)?.toDouble() ?? 0.0;

    return AnimatedSize(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeInOut,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Plot Sizes & Prices:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            // show all sizes; tag no price as NO AMOUNT SET
            ...sizes.map((size) {
              // Some payloads store price as 'current' or 'amount' — check both
              final curr = size['current'] ?? size['amount'];
              final currHas = curr != null;
              final currStr = currHas ? _formatNGN(curr) : 'NO AMOUNT SET';
              final promoPrice =
                  currHas ? ((curr as num) * (100 - discount) / 100) : null;
              final promoStr =
                  promoPrice != null ? _formatNGN(promoPrice) : 'NO AMOUNT SET';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(size['size']?.toString() ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          promoStr,
                          style: promoPrice != null
                              ? const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)
                              : const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currStr,
                          style: currHas
                              ? (promoPrice != null
                                  ? const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey)
                                  : const TextStyle(
                                      fontWeight: FontWeight.bold))
                              : const TextStyle(color: Colors.orange),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------
// Estates List Page
// ---------------------------
class EstatesListPage extends StatefulWidget {
  final String token;
  final int? promoId;

  const EstatesListPage({Key? key, required this.token, this.promoId})
      : super(key: key);

  @override
  _EstatesListPageState createState() => _EstatesListPageState();
}

class _EstatesListPageState extends State<EstatesListPage>
    with TickerProviderStateMixin {
  final ApiService _api = ApiService();
  bool _loading = true;
  String? _error;
  List<dynamic> _estates = [];
  Map<String, dynamic>? _paginated;
  int _page = 1;
  String _q = '';
  final TextEditingController _searchController = TextEditingController();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _staggerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _staggerAnimation;
  final ScrollController _scrollController = ScrollController();

  /// estateId -> highest active discount percentage
  Map<int, int> _estateDiscounts = {};

  Timer? _searchDebounce;
  VoidCallback? _searchListener;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _staggerAnimation = CurvedAnimation(
      parent: _staggerController,
      curve: Curves.easeOutCubic,
    );

    // Search controller listener (debounced)
    _searchListener = () {
      final trimmed = _searchController.text.trim();
      if (trimmed != _q) {
        _q = trimmed;
        // debounce network calls
        _searchDebounce?.cancel();
        _searchDebounce = Timer(const Duration(milliseconds: 400), () {
          if (mounted) _loadEstates(page: 1);
        });
      } else {
        // still cause rebuild for UI bits like clear button visibility
        if (mounted) setState(() {});
      }
    };
    _searchController.addListener(_searchListener!);

    // initial UI fades in
    _fadeController.forward();

    // initial load
    _loadEstates();

    _scrollController.addListener(() {
      if (mounted) setState(() {}); // toggles FAB visibility
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    if (_searchListener != null) _searchController.removeListener(_searchListener!);
    _searchController.dispose();
    _fadeController.dispose();
    _staggerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Explicit search trigger (keyboard submit or icon)
  void _doSearch() {
    _searchDebounce?.cancel();
    _q = _searchController.text.trim();
    FocusScope.of(context).unfocus();
    _loadEstates(page: 1);
  }

  // Helper: parse discount values from many shapes
  int? _parseDiscount(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    final s = v.toString();
    final n = num.tryParse(s);
    return n != null ? n.round() : null;
  }

  // Inspect estate payload and active promos to build estate -> top discount map
  Future<void> _computeDiscountsFromEstates(List<dynamic> estatesList) async {
    final Map<int, int> discounts = {};

    for (var e in estatesList) {
      if (e is Map) {
        final dynamic idRaw = e['id'];
        int? id;
        if (idRaw is num) id = idRaw.toInt();
        else if (idRaw != null) id = int.tryParse(idRaw.toString());
        if (id == null) continue;

        int? best;
        for (final listKey in [
          'promotional_offers',
          'promos',
          'promotions',
          'promotional_offers_preview',
          'promotions_preview',
          'estates_promos'
        ]) {
          final pList = e[listKey];
          if (pList is List) {
            for (final p in pList) {
              if (p is Map) {
                final cand = _parseDiscount(p['discount_pct'] ?? p['discount'] ?? p['percent']);
                if (cand != null) {
                  if (best == null || cand > best) best = cand;
                }
              } else {
                final cand = _parseDiscount(p);
                if (cand != null) {
                  if (best == null || cand > best) best = cand;
                }
              }
            }
          }
        }

        final estateLevel = _parseDiscount(e['discount'] ?? e['discount_pct']);
        if (estateLevel != null) {
          if (best == null || estateLevel > best) best = estateLevel;
        }

        if (best != null) discounts[id] = best;
      }
    }

    // Fallback: call active promotions endpoint and map estates -> discounts
    try {
      final activePromos = await _api.listActivePromotions(token: widget.token);
      if (activePromos is List) {
        for (final p in activePromos) {
          if (p is Map) {
            final dVal = p['discount_pct'] ?? p['discount'];
            final disc = _parseDiscount(dVal);
            if (disc == null) continue;
            final estatesForPromo = p['estates'];
            if (estatesForPromo is List) {
              for (final estEntry in estatesForPromo) {
                if (estEntry is Map && estEntry['id'] != null) {
                  int? eid;
                  final idRaw = estEntry['id'];
                  if (idRaw is num) eid = idRaw.toInt();
                  else eid = int.tryParse(idRaw.toString());
                  if (eid == null) continue;
                  final existing = discounts[eid];
                  if (existing == null || disc > existing) discounts[eid] = disc;
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Active promos fetch failed: $e');
    }

    if (mounted) setState(() => _estateDiscounts = discounts);
  }

  /// Loads estates (handles list, paginated maps, single object shapes)
  Future<void> _loadEstates({int page = 1}) async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    debugPrint('Estates -> loading page=$page q="$_q"');

    try {
      final dynamic resp = await _api.listEstates(
        token: widget.token,
        q: _q.isEmpty ? null : _q,
        page: page,
      );

      debugPrint('Estates -> response type: ${resp.runtimeType}');

      if (resp is List) {
        final list = List.from(resp);
        if (mounted) {
          setState(() {
            _estates = list;
            _paginated = {
              'results': _estates,
              'count': _estates.length,
              'next': null,
              'previous': null,
              'total_pages': 1,
            };
            _page = page;
          });
        }
      } else if (resp is Map) {
        final map = Map<String, dynamic>.from(resp);
        final dynamic maybeResults = map['results'];
        if (maybeResults is List) {
          if (mounted) {
            setState(() {
              _estates = List.from(maybeResults);
              _paginated = map;
              _page = page;
            });
          }
        } else if (map.containsKey('id') || map.containsKey('name')) {
          // single estate returned
          if (mounted) {
            setState(() {
              _estates = [map];
              _paginated = {
                'results': _estates,
                'count': 1,
                'next': null,
                'previous': null,
                'total_pages': 1,
              };
              _page = page;
            });
          }
        } else {
          // attempt to find list-like keys
          List<dynamic>? candidateList;
          for (final key in ['results', 'data', 'items']) {
            if (map[key] is List) {
              candidateList = List.from(map[key] as List);
              break;
            }
          }
          if (candidateList != null) {
            if (mounted) {
              setState(() {
                _estates = candidateList!;
                _paginated = map;
                _page = page;
              });
            }
          } else {
            // unknown map shape - treat as empty results but keep pagination metadata
            if (mounted) {
              setState(() {
                _estates = [];
                _paginated = map;
                _page = page;
              });
            }
          }
        }
      } else {
        // unknown shape
        if (mounted) {
          setState(() {
            _estates = [];
            _paginated = null;
            _page = page;
          });
        }
      }

      // compute discounts & run animations
      await _computeDiscountsFromEstates(_estates);
      _staggerController.reset();
      await Future.delayed(const Duration(milliseconds: 60));
      _staggerController.forward();
      _fadeController.forward(from: 0.0);
    } catch (e, st) {
      debugPrint('Estates -> error: $e\n$st');
      if (mounted) setState(() => _error = e.toString());
      _fadeController.forward(from: 0.0);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showEstateSizesModal(Map<String, dynamic> estate) async {
    await showDialog(
      context: context,
      builder: (context) => EstateSizesModal(token: widget.token, estate: estate),
    );
  }

  // Robust date extractor & formatter
  String _formatAddedDate(dynamic candidate) {
    try {
      if (candidate == null) return 'N/A';
      if (candidate is String) {
        final parsed = DateTime.tryParse(candidate);
        if (parsed != null) return DateFormat('yyyy-MM-dd').format(parsed);
        final match = RegExp(r'(\d{4}-\d{2}-\d{2})').firstMatch(candidate);
        if (match != null) return match.group(0)!;
      } else if (candidate is DateTime) {
        return DateFormat('yyyy-MM-dd').format(candidate);
      } else if (candidate is int) {
        // seconds or milliseconds
        try {
          if (candidate > 9999999999) {
            final dt = DateTime.fromMillisecondsSinceEpoch(candidate);
            return DateFormat('yyyy-MM-dd').format(dt);
          } else {
            final dt = DateTime.fromMillisecondsSinceEpoch(candidate * 1000);
            return DateFormat('yyyy-MM-dd').format(dt);
          }
        } catch (_) {}
      } else {
        final s = candidate.toString();
        final parsed = DateTime.tryParse(s);
        if (parsed != null) return DateFormat('yyyy-MM-dd').format(parsed);
      }
    } catch (_) {}
    return 'N/A';
  }

  bool get _showScrollToTop =>
      _scrollController.hasClients && _scrollController.offset > 300;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        title: const Text('All Estates'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onBackground,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: colorScheme.primary),
            onPressed: () {},
          ),
        ],
      ),

      floatingActionButton: AnimatedScale(
        duration: const Duration(milliseconds: 300),
        scale: _showScrollToTop ? 1.0 : 0.0,
        child: FloatingActionButton(
          onPressed: () {
            _scrollController.animateTo(0,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic);
          },
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.arrow_upward),
          elevation: 4,
        ),
      ),

      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: () => _loadEstates(page: 1),
            color: colorScheme.primary,
            child: _loading
                ? _buildLoadingState()
                : _error != null
                    ? _buildErrorState()
                    : _buildContentState(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Loading estates...', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text('Error loading estates', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(_error ?? 'Unknown error', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => _loadEstates(page: 1), child: const Text('Try Again')),
        ],
      ),
    );
  }

  Widget _buildContentState() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 20),
          if (_estates.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Text(
                    '${_estates.length} ${_estates.length == 1 ? 'Estate' : 'Estates'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width > 1000 ? 3 : (width > 600 ? 2 : 1);
              final gap = 16.0;
              final totalGapWidth = gap * (crossAxisCount - 1);
              final cardWidth = (width - totalGapWidth) / crossAxisCount;
              final desiredCardHeight = 240.0;
              final childAspectRatio = (cardWidth / desiredCardHeight).clamp(0.6, 2.5);

              return GridView.builder(
                controller: _scrollController,
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: gap,
                  mainAxisSpacing: gap,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: _estates.length,
                itemBuilder: (ctx, i) {
                  final estate = _estates[i];
                  final Map<String, dynamic> map =
                      (estate is Map) ? Map<String, dynamic>.from(estate) : {'name': estate?.toString() ?? 'Estate'};

                  // compute discount from pre-fetched map
                  final dynamic idRaw = map['id'];
                  int? estateId;
                  if (idRaw is num) estateId = idRaw.toInt();
                  else if (idRaw != null) estateId = int.tryParse(idRaw.toString());
                  final int? discount = estateId != null ? _estateDiscounts[estateId] : null;

                  // build per-item stagger animation
                  final start = (i * 0.05).clamp(0.0, 0.9);
                  final end = (start + 0.6).clamp(0.0, 1.0);

                  final anim = CurvedAnimation(
                    parent: _staggerController,
                    curve: Interval(start, end, curve: Curves.easeOut),
                  );

                  return AnimatedEstateCard(
                    animation: anim,
                    map: map,
                    addedDate: _formatAddedDate(map['created_at'] ?? map['date_added'] ?? map['date'] ?? map['added_at']),
                    discount: discount,
                    onTap: () => _showEstateSizesModal(map),
                  );
                },
              );
            }),
          ),
          if (_paginated != null && (_paginated!['next'] != null || _paginated!['previous'] != null))
            _buildPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: Theme.of(context).hintColor),
                hintText: 'Search estates...',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _doSearch(),
            ),
          ),

          // Clear button visible when there's text
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (context, val, child) {
              final hasText = val.text.isNotEmpty;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: hasText
                    ? IconButton(
                        key: const ValueKey('clear_btn'),
                        icon: Icon(Icons.clear, color: Theme.of(context).hintColor),
                        onPressed: () {
                          _searchController.clear();
                          _doSearch();
                        },
                      )
                    : const SizedBox(key: ValueKey('empty'), width: 8),
              );
            },
          ),

          IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
            onPressed: _doSearch,
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _page > 1
                ? () {
                    _loadEstates(page: _page - 1);
                  }
                : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Page $_page of ${_paginated!['total_pages'] ?? 1}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _page < (_paginated!['total_pages'] ?? 1)
                ? () {
                    _loadEstates(page: _page + 1);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

// ---------------------------
// Animated Estate Card
// ---------------------------
class AnimatedEstateCard extends StatelessWidget {
  final Animation<double> animation;
  final Map<String, dynamic> map;
  final VoidCallback onTap;
  final String addedDate;
  final int? discount;

  const AnimatedEstateCard({
    Key? key,
    required this.animation,
    required this.map,
    required this.onTap,
    required this.addedDate,
    this.discount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        ),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(animation),
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
              .animate(animation),
          child: _EstateCard(
            map: map,
            onTap: onTap,
            addedDate: addedDate,
            discount: discount,
          ),
        ),
      ),
    );
  }
}

// ---------------------------
// Estate Card
// ---------------------------
class _EstateCard extends StatefulWidget {
  final Map<String, dynamic> map;
  final VoidCallback onTap;
  final String addedDate;
  final int? discount;

  const _EstateCard({
    Key? key,
    required this.map,
    required this.onTap,
    required this.addedDate,
    this.discount,
  }) : super(key: key);

  @override
  State<_EstateCard> createState() => _EstateCardState();
}

class _EstateCardState extends State<_EstateCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final name = widget.map['name'] ?? 'Estate';
    final location = widget.map['location'] ?? '';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..scale(_isHovering ? 1.02 : 1.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: theme.cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovering ? 0.1 : 0.05),
                blurRadius: _isHovering ? 16 : 8,
                offset: Offset(0, _isHovering ? 8 : 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with icon and text
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary.withOpacity(0.2),
                                  colorScheme.primary.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Icon(
                              Icons.apartment,
                              color: colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  location,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Added date
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Added: ${widget.addedDate}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Action button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: widget.onTap,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('View Details'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Discount badge
                if (widget.discount != null && widget.discount! > 0)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF7A7A), Color(0xFFFFB46B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '-${widget.discount}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
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
}

// ---------------------------
// Estate Sizes Modal
// ---------------------------
class EstateSizesModal extends StatefulWidget {
  final String token;
  final Map<String, dynamic> estate;

  const EstateSizesModal({Key? key, required this.token, required this.estate}) : super(key: key);

  @override
  _EstateSizesModalState createState() => _EstateSizesModalState();
}

class _EstateSizesModalState extends State<EstateSizesModal> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _estateDetails;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    
    _animationController.forward();
    _loadEstateDetails();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  
  Future<void> _loadEstateDetails() async {
    setState(() { _loading = true; _error = null; });
    try {
      final idRaw = widget.estate['id'];
      int? estateId;
      if (idRaw is num) estateId = idRaw.toInt();
      else estateId = int.tryParse(idRaw?.toString() ?? '');
      if (estateId == null) throw Exception('Missing estate id');

      final resp = await _api.getEstateModalJson(estateId, token: widget.token);

      Map<String, dynamic> details = {};
      if (resp is Map<String, dynamic>) details = Map<String, dynamic>.from(resp);
      else details = {'estate_name': widget.estate['name'], 'sizes': resp, 'promo': null};

      // normalize sizes
      if (details.containsKey('sizes') && details['sizes'] is List) {
        final raw = details['sizes'] as List;
        final List<Map<String, dynamic>> sizesOut = [];
        for (var s in raw) {
          if (s is Map) {
            final sizeName = s['size']?.toString() ?? s['plot_size']?.toString() ?? '';
            final amount = _toDouble(s['amount'] ?? s['current'] ?? s['price']);
            final discounted = _toDouble(s['discounted'] ?? s['promo_price'] ?? s['discounted_price']);
            int? discountPct = _toInt(s['discount_pct'] ?? s['discount']);
            if (discountPct == null && details['promo'] is Map) discountPct = _toInt((details['promo'] as Map)['discount_pct'] ?? (details['promo'] as Map)['discount']);
            sizesOut.add({'size': sizeName, 'amount': amount, 'discounted': discounted, 'discount_pct': discountPct});
          } else {
            sizesOut.add({'size': s?.toString() ?? '', 'amount': null, 'discounted': null, 'discount_pct': null});
          }
        }
        details['sizes'] = sizesOut;
      } else {
        details['sizes'] = [];
      }

      setState(() { _estateDetails = details; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v);
    return null;
  }

  String _fmtCurrency(dynamic v) {
    try {
      if (v == null) return 'NO AMOUNT SET';
      final numVal = (v is num) ? v : num.tryParse(v.toString());
      if (numVal == null) return 'NO AMOUNT SET';
      return NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0).format(numVal);
    } catch (_) {
      return v?.toString() ?? 'NO AMOUNT SET';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Plot Sizes & Prices',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                Center(child: Text('Error: $_error'))
              else if (_estateDetails == null)
                const Center(child: Text('No details available'))
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _estateDetails!['estate_name']?.toString() ?? widget.estate['name']?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_estateDetails!['promo'] != null && 
                            _estateDetails!['promo'] is Map && 
                            (_estateDetails!['promo'] as Map)['active'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade100),
                            ),
                            child: Text(
                              'Promotion: -${(_estateDetails!['promo'] as Map)['discount_pct'] ?? (_estateDetails!['promo'] as Map)['discount']}% off',
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        const Text(
                          'Available Plot Sizes:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_estateDetails!['sizes'] is List && (_estateDetails!['sizes'] as List).isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Table(
                                columnWidths: const {
                                  0: FlexColumnWidth(2),
                                  1: FlexColumnWidth(2),
                                  2: FlexColumnWidth(2)
                                },
                                border: TableBorder(
                                  horizontalInside: BorderSide(
                                    color: Theme.of(context).dividerColor,
                                    width: 1,
                                  ),
                                ),
                                children: [
                                  TableRow(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).highlightColor,
                                    ),
                                    children: const [
                                      Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: Text(
                                          'Size',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: Text(
                                          'Price',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: Text(
                                          'Promo Price',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  for (var size in (_estateDetails!['sizes'] as List))
                                    TableRow(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Text(size['size']?.toString() ?? ''),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Text(size['amount'] != null ? _fmtCurrency(size['amount']) : '—'),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (size['discounted'] != null)
                                                Text(
                                                  _fmtCurrency(size['discounted']),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green,
                                                  ),
                                                )
                                              else
                                                const Text('—'),
                                              if (size['discount_pct'] != null)
                                                Text(
                                                  '-${size['discount_pct']}% promo',
                                                  style: TextStyle(
                                                    color: Theme.of(context).hintColor,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No plot sizes available for this estate.'),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ... (rest of your existing methods remain exactly the same)
}


// Truncate helper in extension
extension _StringExt on String {
  String truncate(int n) => length > n ? '${substring(0, n - 1)}…' : this;
}
