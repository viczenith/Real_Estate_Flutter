import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
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

class _ClientDashboardState extends State<ClientDashboard> with TickerProviderStateMixin {
  final ApiService _api = ApiService();

  bool _loading = true;
  String? _error;
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
  final PageController _promoPageController = PageController(viewportFraction: 0.92);
  int _currentPromoIndex = 0;

  final NumberFormat _ngnFmt = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _staggerAnim = CurvedAnimation(parent: _staggerController, curve: Curves.easeOutCubic);
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _fetchDashboard();
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
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await _api.getClientDashboardData(widget.token);
      // expected keys: total_properties, fully_paid_allocations, not_fully_paid_allocations, active_promotions, latest_value
      setState(() {
        _data = resp;
        _activePromos = List<Map<String, dynamic>>.from(resp['active_promotions'] ?? []);
        _latestValue = List<Map<String, dynamic>>.from(resp['latest_value'] ?? []);
      });
      _staggerController.forward();
      
      // Start the carousel after data is loaded
      if (_activePromos.isNotEmpty) {
        _startPromoCarousel();
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
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
        case 'biggest_up': return (b['percent_change'] ?? 0).compareTo(a['percent_change'] ?? 0);
        case 'biggest_down': return (a['percent_change'] ?? 0).compareTo(b['percent_change'] ?? 0);
        case 'highest_price': return curVal(b).compareTo(curVal(a));
        case 'promo_first':
          final ap = (b['promo'] != null ? 1 : 0) - (a['promo'] != null ? 1 : 0);
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
    } catch (e) { return v.toString(); }
  }

  // Check if a date is in the future
  bool _isFutureDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return date.isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  // Format date to display as "MMM dd, yyyy"
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
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PromotionDetailPage(token: widget.token, promoId: id)));
  }

  Future<void> _openPriceDetail(int id) async {
    showDialog(context: context, builder: (_) => PriceDetailDialog(api: _api, token: widget.token, priceHistoryId: id));
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
                offset: const Offset(0, 4)
              )
            ]
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12)
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: color))
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
        child: wide ? Row(
          children: [
            Expanded(child: card('My Properties Purchased', total, Icons.shopping_cart, Colors.indigo)),
            const SizedBox(width: 12),
            Expanded(child: card('Fully Paid & Allocated', fully, Icons.account_balance_wallet, Colors.teal)),
            const SizedBox(width: 12),
            Expanded(child: card('Not Fully Paid', notFully, Icons.money_off, Colors.orange)),
          ],
        ) : Column(children: [
          card('My Properties Purchased', total, Icons.shopping_cart, Colors.indigo),
          const SizedBox(height: 12),
          card('Fully Paid & Allocated', fully, Icons.account_balance_wallet, Colors.teal),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_offer, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              const Text('No active promotions right now', 
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Check back later or explore all estates.', 
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => EstatesListPage(token: widget.token))
                    ),
                    child: const Text('Browse estates'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PromotionsListPage(token: widget.token, filter: 'past'))
                    ),
                    child: const Text('See past promos'),
                  ),
                ],
              )
            ]
          )
        ),
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
                      ]
                    )
                  ),
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
                                  offset: const Offset(0, 4)
                                )
                              ]
                            ),
                            child: const Icon(Icons.local_offer, size: 36, color: Colors.deepOrange),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  promo['name'] ?? 'Promotion',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  promo['description'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (var e in estates.take(3))
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurple.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          e['name'] ?? '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.deepPurple.shade700,
                                            fontWeight: FontWeight.w600
                                          ),
                                        ),
                                      ),
                                    if (estates.length > 3)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(12),
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
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xffff7a7a), Color(0xffffb46b)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.redAccent.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4)
                                    )
                                  ]
                                ),
                                child: Text(
                                  '-${promo['discount'] ?? 0}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                promo['end'] ?? '',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => EstatesListPage(
                                token: widget.token,
                                promoId: promo['id'],
                              ))
                            ),
                            child: const Text('View Estates'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              backgroundColor: Theme.of(context).colorScheme.primary,
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

  Widget _buildPriceExplorer() {
    final cards = _filteredPriceCards();

    // Remove duplicates by ID to prevent card duplication
    final uniqueCards = <Map<String, dynamic>>[];
    final Set<int> seenIds = <int>{};
    
    for (final card in cards) {
      final id = (card['id'] as num?)?.toInt();
      if (id != null && !seenIds.contains(id)) {
        seenIds.add(id);
        uniqueCards.add(card);
      }
    }

    return Column(
      children: [
        // Responsive header
        LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
            child: isWide 
              ? Row(children: [
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
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade50,
                      ),
                      onChanged: (_) { setState(() {}); },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: _priceSort,
                      items: const [
                        DropdownMenuItem(value: 'newest', child: Text('Newest')),
                        DropdownMenuItem(value: 'biggest_up', child: Text('Largest increase')),
                        DropdownMenuItem(value: 'biggest_down', child: Text('Largest decrease')),
                        DropdownMenuItem(value: 'highest_price', child: Text('Highest price')),
                        DropdownMenuItem(value: 'promo_first', child: Text('Promo first'))
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() { _priceSort = v; });
                      },
                      underline: const SizedBox(),
                      borderRadius: BorderRadius.circular(12),
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Promo only'),
                    selected: _promoOnly,
                    onSelected: (v) => setState(() { _promoOnly = v; }),
                    checkmarkColor: Colors.white,
                    selectedColor: Theme.of(context).colorScheme.primary,
                  )
                ])
              : Column(children: [
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
                      fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade50,
                    ),
                    onChanged: (_) { setState(() {}); },
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButton<String>(
                          value: _priceSort,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'newest', child: Text('Newest')),
                            DropdownMenuItem(value: 'biggest_up', child: Text('Largest increase')),
                            DropdownMenuItem(value: 'biggest_down', child: Text('Largest decrease')),
                            DropdownMenuItem(value: 'highest_price', child: Text('Highest price')),
                            DropdownMenuItem(value: 'promo_first', child: Text('Promo first'))
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() { _priceSort = v; });
                          },
                          underline: const SizedBox(),
                          borderRadius: BorderRadius.circular(12),
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Promo only'),
                      selected: _promoOnly,
                      onSelected: (v) => setState(() { _promoOnly = v; }),
                      checkmarkColor: Colors.white,
                      selectedColor: Theme.of(context).colorScheme.primary,
                    )
                  ])
                ]),
          );
        }),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('${uniqueCards.length} updates', style: const TextStyle(color: Colors.grey)),
          ),
        ),

        const SizedBox(height: 8),

        // grid/list of cards - Fixed the duplication issue
        AnimatedBuilder(
          animation: _staggerAnim,
          builder: (context, _) {
            return LayoutBuilder(builder: (ctx, cons) {
              final cols = cons.maxWidth > 1000 ? 3 : (cons.maxWidth > 600 ? 2 : 1);
              final rows = (uniqueCards.length / cols).ceil();
              final cardHeight = 220.0;
              final spacing = 16.0;
              final totalHeight = rows * cardHeight + (rows - 1) * spacing;
              
              return SizedBox(
                height: totalHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: uniqueCards.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.0,
                      mainAxisExtent: cardHeight
                    ),
                    itemBuilder: (ctx, i) {
                      final c = uniqueCards[i];
                      return _buildPriceCard(c);
                    },
                  ),
                ),
              );
            });
          },
        ),
        const SizedBox(height: 12)
      ],
    );
  }

  Widget _buildPriceCard(Map<String, dynamic> c) {
    final promo = c['promo'];
    final percent = c['percent_change'];
    final up = (percent ?? 0) >= 0;
    final estateName = c['estate_name'] ?? '-';
    final plotSize = (c['plot_unit'] != null && c['plot_unit'] is Map 
        ? (c['plot_unit']['size'] ?? '-').toString() 
        : '-');
    final effectiveDate = c['effective']?.toString() ?? '';
    final isFutureDate = _isFutureDate(effectiveDate);
    
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _openPriceDetail((c['id'] as num).toInt()),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                (up ? Colors.green.shade50 : Colors.red.shade50).withOpacity(0.4),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estate name and size
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          estateName,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          plotSize,
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        )
                      ],
                    ),
                  ),
                  if (promo != null)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xffff7a7a), Color(0xffffb46b)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-${promo['discount']}% Off',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Promo',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        )
                      ],
                    )
                ],
              ),

              const SizedBox(height: 12),

              // Prices
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (promo != null && c['promo_price'] != null)
                        Text(
                          _formatNGN(c['promo_price']),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Colors.deepOrange
                          ),
                        ),
                      if (promo != null && c['promo_price'] != null)
                        Text(
                          _formatNGN(c['current']),
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                            fontSize: 12
                          ),
                        )
                      else
                        Text(
                          _formatNGN(c['current']),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Colors.green
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Prev: ${_formatNGN(c['previous'])}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      )
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Percentage change
                      if (percent != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: up ? Colors.green.shade100 : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: up ? Colors.green : Colors.red,
                              width: 1
                            )
                          ),
                          child: Text(
                            '${percent.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: up ? Colors.green.shade800 : Colors.red.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 14
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 8),
                      
                      // Effective date badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isFutureDate ? const Color(0xFFecffd9) : const Color(0xFFf5f5f6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isFutureDate ? const Color(0xFF0b6b2e).withOpacity(0.08) : const Color(0xFF495057).withOpacity(0.06),
                          )
                        ),
                        child: Column(
                          children: [
                            Text(
                              isFutureDate ? 'Effective on' : 'Effective since',
                              style: TextStyle(
                                fontSize: 10,
                                color: isFutureDate ? const Color(0xFF0b6b2e) : const Color(0xFF495057),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatDateDisplay(effectiveDate),
                              style: TextStyle(
                                fontSize: 10,
                                color: isFutureDate ? const Color(0xFF0b6b2e) : const Color(0xFF495057),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  )
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Notes if available
              if (c['notes'] != null && c['notes'].toString().isNotEmpty)
                Text(
                  c['notes'].toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic
                  ),
                ),
              
              // View button at bottom
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _openPriceDetail((c['id'] as num).toInt()),
                  child: const Text(
                    'View Details',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AppLayout(
      pageTitle: 'Client Dashboard',
      token: widget.token,
      side: AppSide.client,
      child: Scaffold(
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        bottomNavigationBar: ClientBottomNav(currentIndex: 0, token: widget.token, chatBadge: 0),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _fetchDashboard,
            color: Theme.of(context).colorScheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(children: [
                // header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Client Dashboard',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 28,
                              color: isDark ? Colors.white : Colors.grey.shade800
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
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.96, end: 1.04).animate(
                        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _fetchDashboard,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    )
                  ]),
                ),

                if (_loading) 
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
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
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
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
                                  MaterialPageRoute(builder: (_) => PromotionsListPage(token: widget.token))
                                ),
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
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => PromotionsListPage(token: widget.token))
                                ),
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

  const PriceDetailDialog({Key? key, required this.api, required this.token, required this.priceHistoryId}) : super(key: key);

  @override
  _PriceDetailDialogState createState() => _PriceDetailDialogState();
}

class _PriceDetailDialogState extends State<PriceDetailDialog> with SingleTickerProviderStateMixin {
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
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await widget.api.getPriceUpdateById(widget.priceHistoryId, token: widget.token);
      setState(() { _data = resp; });
      _animationController.forward();
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally { setState(() { _loading = false; }); }
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
                        Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                        const SizedBox(height: 16),
                        Text('Error: $_error', style: const TextStyle(color: Colors.red)),
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

    final promo = (_data!['promo'] is Map) ? Map<String, dynamic>.from(_data!['promo']) : null;
    final dynamic promoPriceRaw = _data!['promo_price'] ?? _data!['promo_price'];
    final bool promoActive = promo != null && promo['active'] == true;
    final int? discountPct = promo != null && (promo['discount_pct'] is num || promo['discount'] is num)
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
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  'Price Update Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Title (takes remaining space, truncates if too long)
                    Expanded(
                      child: Text(
                        _data!['estate_name'] ?? '',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(width: 8),

                    if (promoActive || discountPct != null)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 110),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xffff7a7a), Color(0xffffb46b)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.redAccent.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  '-${discountPct ?? promo?['discount'] ?? ''}% Off',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              if ((promoActive || promoPriceRaw != null) && (_data!['current'] != null))
                _buildCurrentWithPromo(
                  current: _format(_data!['current']),
                  promoPrice: promoPriceRaw != null ? _format(promoPriceRaw) : null,
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
            const Text('Current', style: TextStyle(fontWeight: FontWeight.w600)),
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
              const Text('Promo price', style: TextStyle(fontWeight: FontWeight.w600)),
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

  Widget _buildDetailRow(String label, String value, {bool isPercent = false, double? percent}) {
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
      return NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0).format(numVal);
    } catch (_) { return v.toString(); }
  }
}

// ---------------------------
// Promotions List Page
// ---------------------------
class PromotionsListPage extends StatefulWidget {
  final String token;
  final String? filter;
  const PromotionsListPage({Key? key, required this.token, this.filter}) : super(key: key);

  @override
  _PromotionsListPageState createState() => _PromotionsListPageState();
}

class _PromotionsListPageState extends State<PromotionsListPage> with SingleTickerProviderStateMixin {
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
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await _api.listPromotions(token: widget.token, filter: _filter, q: _q, page: page);
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
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
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
                                        contentPadding: const EdgeInsets.all(16),
                                        leading: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.deepOrange.shade50,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.local_offer,
                                            color: Colors.deepOrange,
                                          ),
                                        ),
                                        title: Text(
                                          p['name'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                        subtitle: Text(
                                          p['description'] ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: Chip(
                                          label: Text(
                                            '-${p['discount']}%',
                                            style: const TextStyle(color: Colors.white),
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
                            color: isActive ? Colors.blue.shade50 : Colors.grey.shade50,
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
                        onTap: isActive ? () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PromotionDetailPage(
                              token: widget.token,
                              promoId: (p['id'] as num).toInt(),
                            ),
                          ),
                        ) : null,
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
  const PromotionDetailPage({Key? key, required this.token, required this.promoId}) : super(key: key);

  @override
  _PromotionDetailPageState createState() => _PromotionDetailPageState();
}

class _PromotionDetailPageState extends State<PromotionDetailPage> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _promo;
  late AnimationController _animationController;
  int? _expandedEstateId;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _load();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final resp = await _api.getPromotionDetail(widget.promoId, token: widget.token);
      setState(() => _promo = resp);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotion details'),
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
                    padding: const EdgeInsets.all(16),
                    child: FadeTransition(
                      opacity: _animationController,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.easeOutCubic,
                        )),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _promo!["name"] ?? "",
                                            style: const TextStyle(
                                                fontSize: 20, fontWeight: FontWeight.w800),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Valid: ${_promo!["start"] ?? ""} → ${_promo!["end"] ?? ""}',
                                            style: const TextStyle(color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Chip(
                                      label: Text(
                                        '-${_promo!["discount"]}%',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      backgroundColor: Colors.deepOrange,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Description',
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _promo!["description"] ?? "",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Applies to estates',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ListView.builder(
                                itemCount: (_promo!["estates"] as List?)?.length ?? 0,
                                itemBuilder: (ctx, i) {
                                  final e = _promo!["estates"][i] as Map;
                                  final estateId = e["id"] as int;
                                  final isExpanded = _expandedEstateId == estateId;
                                  
                                  return FadeTransition(
                                    opacity: Tween<double>(begin: 0, end: 1).animate(
                                      CurvedAnimation(
                                        parent: _animationController,
                                        curve: Interval(0.1 * i, 1.0, curve: Curves.easeIn),
                                      ),
                                    ),
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(-0.5, 0),
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: _animationController,
                                          curve: Interval(0.1 * i, 1.0, curve: Curves.easeOut),
                                        ),
                                      ),
                                      child: Card(
                                        margin: const EdgeInsets.symmetric(vertical: 8),
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          children: [
                                            ListTile(
                                              contentPadding: const EdgeInsets.all(16),
                                              leading: Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade50,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.apartment,
                                                  color: Colors.green,
                                                ),
                                              ),
                                              title: Text(e["name"] ?? ""),
                                              subtitle: Text(e["location"] ?? ""),
                                              trailing: IconButton(
                                                icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                                                onPressed: () => _toggleEstateExpansion(estateId),
                                              ),
                                              onTap: () => _toggleEstateExpansion(estateId),
                                            ),
                                            if (isExpanded)
                                              _buildEstateSizes(e as Map<String, dynamic>)
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildEstateSizes(Map<String, dynamic> estate) {
    final sizes = List.from(estate['sizes'] ?? []);
    final discount = _promo!['discount'] as num;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Plot Sizes & Prices:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2),
            },
            border: TableBorder.all(
              color: Colors.grey.shade300,
              width: 1,
              borderRadius: BorderRadius.circular(8),
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Size', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Original Price', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Promo Price', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              for (var size in sizes)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(size['size'] ?? ''),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        size['current'] != null 
                          ? NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0)
                              .format(size['current'])
                          : '—',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        size['current'] != null
                          ? NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0)
                              .format(size['current'] * (100 - discount) / 100)
                          : '—',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
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
  
  const EstatesListPage({Key? key, required this.token, this.promoId}) : super(key: key);

  @override
  _EstatesListPageState createState() => _EstatesListPageState();
}

class _EstatesListPageState extends State<EstatesListPage> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  bool _loading = true;
  String? _error;
  List<dynamic> _estates = [];
  Map<String, dynamic>? _paginated;
  int _page = 1;
  String _q = '';
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadEstates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Future<void> _loadEstates({int page = 1}) async {
  //   setState(() { _loading = true; _error = null; });
  //   try {
  //     final resp = await _api.listEstates(
  //       token: widget.token, 
  //       q: _q, 
  //       page: page,
  //     );
  //     setState(() {
  //       _estates = List.from(resp['results'] ?? []);
  //       _paginated = resp;
  //       _page = page;
  //     });
  //     _animationController.forward();
  //   } catch (e) {
  //     setState(() => _error = e.toString());
  //   } finally {
  //     setState(() => _loading = false);
  //   }
  // }

  Future<void> _loadEstates({int page = 1}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final dynamic resp = await _api.listEstates(
        token: widget.token,
        q: _q,
        page: page,
      );

      if (resp is List) {
        final list = List.from(resp);
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
      } else if (resp is Map<String, dynamic>) {
        // Prefer 'results' if present, but fall back to single-object coercion
        final dynamic maybeResults = resp['results'];
        if (maybeResults is List) {
          setState(() {
            _estates = List.from(maybeResults);
            _paginated = resp;
            _page = page;
          });
        } else if (resp.containsKey('id') || resp.containsKey('name')) {
          // server returned a single estate object as a Map
          setState(() {
            _estates = [resp];
            _paginated = {
              'results': _estates,
              'count': 1,
              'next': null,
              'previous': null,
              'total_pages': 1,
            };
            _page = page;
          });
        } else {
          // unknown map shape — fall back safely
          setState(() {
            _estates = [];
            _paginated = resp;
            _page = page;
          });
        }
      } else {
        // Unexpected shape
        setState(() {
          _estates = [];
          _paginated = null;
          _page = page;
        });
      }

      _animationController.forward();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }


  Future<void> _showEstateSizesModal(Map<String, dynamic> estate) async {
    showDialog(
      context: context,
      builder: (context) => EstateSizesModal(
        token: widget.token,
        estate: estate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Estates'),
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
                        // Search bar
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search),
                              hintText: 'Search estates...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _q = '';
                                  _loadEstates();
                                },
                              ),
                            ),
                            onSubmitted: (value) {
                              _q = value;
                              _loadEstates();
                            },
                          ),
                        ),
                        
                        Expanded(
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: _estates.length,
                            itemBuilder: (ctx, i) {
                              final estate = _estates[i];
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
                                  child: Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: InkWell(
                                      onTap: () => _showEstateSizesModal(estate),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              estate['name'] ?? 'Estate',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              estate['location'] ?? '',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Added: ${estate['created_at'] != null ? DateFormat('yyyy-MM-dd').format(DateTime.parse(estate['created_at'])) : 'N/A'}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const Spacer(),
                                            Center(
                                              child: ElevatedButton(
                                                onPressed: () => _showEstateSizesModal(estate),
                                                child: const Text('View Plots & Prices'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                                  foregroundColor: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        
                        // Pagination
                        if (_paginated != null && (_paginated!['next'] != null || _paginated!['previous'] != null))
                          Padding(
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
                                Text('Page $_page of ${_paginated!['total_pages'] ?? 1}'),
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
                          ),
                      ],
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

class _EstateSizesModalState extends State<EstateSizesModal> {
  final ApiService _api = ApiService();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _estateDetails;

  @override
  void initState() {
    super.initState();
    _loadEstateDetails();
  }

  Future<void> _loadEstateDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final resp = await _api.getEstateModalJson(widget.estate['id'], token: widget.token);
      
      // Handle the expected response structure
      Map<String, dynamic> details = {};
      if (resp is Map<String, dynamic>) {
        details = resp;
        
        // Normalize sizes data
        if (details.containsKey('sizes') && details['sizes'] is List) {
          final List<dynamic> rawSizes = details['sizes'];
          final List<Map<String, dynamic>> processedSizes = [];
          
          for (var size in rawSizes) {
            if (size is Map<String, dynamic>) {
              // Extract and normalize size data
              final String sizeName = size['size']?.toString() ?? '';
              final double? amount = _toDouble(size['amount'] ?? size['current'] ?? size['price']);
              final double? discounted = _toDouble(size['discounted'] ?? size['promo_price']);
              final int? discountPct = _toInt(size['discount_pct']);
              
              processedSizes.add({
                'size': sizeName,
                'amount': amount,
                'discounted': discounted,
                'discount_pct': discountPct,
              });
            }
          }
          details['sizes'] = processedSizes;
        }
      }

      setState(() {
        _estateDetails = details;
      });
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

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Plot Sizes & Prices',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
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
                          _estateDetails!['estate_name'] ?? widget.estate['name'] ?? '',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 16),
                        if (_estateDetails!['promo'] != null && 
                            _estateDetails!['promo'] is Map && 
                            (_estateDetails!['promo'] as Map)['active'] == true)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.deepOrange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.deepOrange.shade100),
                              ),
                              child: Text(
                                'Promotion: -${(_estateDetails!['promo'] as Map)['discount']}% off',
                                style: TextStyle(
                                  color: Colors.deepOrange.shade800,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        const Text(
                          'Available Plot Sizes:',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        if (_estateDetails!['sizes'] != null && (_estateDetails!['sizes'] as List).isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Table(
                                columnWidths: const {
                                  0: FlexColumnWidth(2),
                                  1: FlexColumnWidth(2),
                                  2: FlexColumnWidth(2),
                                },
                                border: TableBorder.symmetric(
                                  inside: BorderSide(color: Colors.grey.shade200, width: 1),
                                  outside: BorderSide(color: Colors.grey.shade300, width: 1),
                                ),
                                children: [
                                  TableRow(
                                    decoration: BoxDecoration(color: Colors.grey.shade100),
                                    children: const [
                                      Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text('Size', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text('Promo Price', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  for (var size in (_estateDetails!['sizes'] as List))
                                    TableRow(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(size['size']?.toString() ?? ''),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            size['amount'] != null ? currencyFormatter.format(size['amount']) : '—',
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            size['discounted'] != null ? currencyFormatter.format(size['discounted']) : '—',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: size['discounted'] != null ? Colors.green : Colors.grey,
                                            ),
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
}


// class EstateSizesModal extends StatefulWidget {
//   final String token;
//   final Map<String, dynamic> estate;

//   const EstateSizesModal({Key? key, required this.token, required this.estate}) : super(key: key);

//   @override
//   _EstateSizesModalState createState() => _EstateSizesModalState();
// }

// class _EstateSizesModalState extends State<EstateSizesModal> {
//   final ApiService _api = ApiService();
//   bool _loading = true;
//   String? _error;
//   Map<String, dynamic>? _estateDetails;

//   @override
//   void initState() {
//     super.initState();
//     _loadEstateDetails();
//   }

//   // Safe helper: if collection is List return first element, if Map return first value, else null
//   dynamic _safeFirst(dynamic collection) {
//     if (collection is List) return collection.isNotEmpty ? collection.first : null;
//     if (collection is Map) return collection.values.isNotEmpty ? collection.values.first : null;
//     return null;
//   }

//   // Turn many possible server shapes into a List<Map<String,dynamic>>
//   List<Map<String, dynamic>> _normalizeToSizesList(dynamic raw) {
//     if (raw == null) return <Map<String, dynamic>>[];

//     if (raw is List) {
//       return raw.map<Map<String, dynamic>>((e) {
//         if (e is Map) return Map<String, dynamic>.from(e);
//         return <String, dynamic>{'size': e?.toString() ?? ''};
//       }).toList();
//     }

//     if (raw is Map) {
//       final typed = Map<String, dynamic>.from(raw);
//       // If the map itself looks like a single size object, wrap it
//       if (typed.containsKey('size') ||
//           typed.containsKey('amount') ||
//           typed.containsKey('current') ||
//           typed.containsKey('price') ||
//           typed.containsKey('plot_unit_id') ||
//           typed.containsKey('plot_unit')) {
//         return [typed];
//       }
//       // Otherwise treat the map's values as items
//       return typed.values.map<Map<String, dynamic>>((e) {
//         if (e is Map) return Map<String, dynamic>.from(e);
//         return <String, dynamic>{'size': e?.toString() ?? ''};
//       }).toList();
//     }

//     // Scalar -> single item
//     return <Map<String, dynamic>>[<String, dynamic>{'size': raw.toString()}];
//   }

//   double? _toDoubleNullable(dynamic v) {
//     if (v == null) return null;
//     if (v is num) return v.toDouble();
//     if (v is String) {
//       final cleaned = v.replaceAll(',', '');
//       return double.tryParse(cleaned);
//     }
//     return null;
//   }

//   Future<void> _loadEstateDetails() async {
//     setState(() {
//       _loading = true;
//       _error = null;
//     });

//     try {
//       final resp = await _api.getEstateModalJson(widget.estate['id'], token: widget.token);

//       // debug
//       try {
//         debugPrint('getEstateModalJson runtimeType: ${resp.runtimeType}');
//         debugPrint('getEstateModalJson body: ${jsonEncode(resp)}');
//       } catch (_) {
//         debugPrint('getEstateModalJson raw: $resp');
//       }

//       Map<String, dynamic> details = {};
//       List<Map<String, dynamic>> sizes = [];

//       // find an estate object inside collections
//       Map<String, dynamic>? _findEstateInIterable(dynamic iterable) {
//         if (iterable is List) {
//           for (var item in iterable) {
//             if (item is Map && (item['id']?.toString() == widget.estate['id']?.toString())) {
//               return Map<String, dynamic>.from(item);
//             }
//           }
//         } else if (iterable is Map) {
//           for (var v in iterable.values) {
//             if (v is Map && (v['id']?.toString() == widget.estate['id']?.toString())) {
//               return Map<String, dynamic>.from(v);
//             }
//           }
//         }
//         return null;
//       }

//       bool _looksLikeSizesList(dynamic cand) {
//         final first = _safeFirst(cand); // safe for List or Map
//         return first is Map &&
//             (first.containsKey('size') ||
//                 first.containsKey('amount') ||
//                 first.containsKey('current') ||
//                 first.containsKey('price') ||
//                 first.containsKey('plot_unit') ||
//                 first.containsKey('plot_unit_id'));
//       }

//       if (resp is Map) {
//         final respMap = Map<String, dynamic>.from(resp);

//         // Direct sizes key
//         if (respMap.containsKey('sizes') && _looksLikeSizesList(respMap['sizes'])) {
//           details = Map<String, dynamic>.from(respMap);
//           details['sizes'] = _normalizeToSizesList(respMap['sizes']);
//         }
//         // available_floor_plans (common alt key)
//         else if (respMap.containsKey('available_floor_plans') && _looksLikeSizesList(respMap['available_floor_plans'])) {
//           details = Map<String, dynamic>.from(respMap);
//           details['sizes'] = _normalizeToSizesList(respMap['available_floor_plans']);
//         }
//         // Paginated-like or results key
//         else if (respMap.containsKey('results')) {
//           final rawResults = respMap['results'];
//           final first = _safeFirst(rawResults);
//           final looksLike = first is Map &&
//               (first.containsKey('size') ||
//                   first.containsKey('amount') ||
//                   first.containsKey('current') ||
//                   first.containsKey('plot_unit') ||
//                   first.containsKey('price'));
//           if (looksLike) {
//             sizes = _normalizeToSizesList(rawResults);
//             details = {'estate_name': widget.estate['name'], 'sizes': sizes, 'promo': respMap['promo'] ?? null};
//           } else {
//             final found = _findEstateInIterable(rawResults);
//             if (found != null) {
//               details = Map<String, dynamic>.from(found);
//               details['sizes'] = _normalizeToSizesList(found['sizes'] ?? found['available_floor_plans']);
//             } else {
//               // try other common keys inside respMap
//               dynamic candidate;
//               for (var k in ['sizes', 'plot_units', 'units', 'plots', 'items', 'data', 'available_floor_plans', 'property_prices']) {
//                 if (respMap.containsKey(k) && _looksLikeSizesList(respMap[k])) {
//                   candidate = respMap[k];
//                   break;
//                 }
//               }
//               if (candidate != null) {
//                 sizes = _normalizeToSizesList(candidate);
//                 details = {'estate_name': widget.estate['name'], 'sizes': sizes, 'promo': respMap['promo'] ?? null};
//               } else {
//                 // no sizes found in this response map
//                 details = {'estate_name': widget.estate['name'], 'sizes': <Map<String, dynamic>>[], 'promo': respMap['promo'] ?? null};
//               }
//             }
//           }
//         } else {
//           // treat respMap as a single estate object; normalize any sizes key or available_floor_plans
//           details = Map<String, dynamic>.from(respMap);
//           details['sizes'] = _normalizeToSizesList(respMap['sizes'] ?? respMap['available_floor_plans'] ?? respMap['property_prices']);
//         }
//       } else if (resp is List) {
//         // Use _safeFirst so code is consistent and safe
//         final first = _safeFirst(resp);
//         final looksLike = first is Map &&
//             (first.containsKey('size') ||
//                 first.containsKey('amount') ||
//                 first.containsKey('current') ||
//                 first.containsKey('plot_unit') ||
//                 first.containsKey('price'));

//         if (looksLike) {
//           sizes = _normalizeToSizesList(resp);
//           details = {'estate_id': widget.estate['id'], 'estate_name': widget.estate['name'], 'promo': null, 'sizes': sizes};
//         } else {
//           final found = _findEstateInIterable(resp);
//           if (found != null) {
//             details = Map<String, dynamic>.from(found);
//             details['sizes'] = _normalizeToSizesList(details['sizes'] ?? found['available_floor_plans'] ?? found['property_prices']);
//           } else {
//             details = {'estate_name': widget.estate['name'], 'sizes': _normalizeToSizesList(resp), 'promo': null};
//           }
//         }
//       } else {
//         // unknown shape: safe empty
//         details = {'estate_name': widget.estate['name'], 'sizes': <Map<String, dynamic>>[]};
//       }

//       // Ensure sizes is a List before processing
//       final dynamic rawSizes = details['sizes'];
//       final List normalizedInputSizes = rawSizes is List ? rawSizes : (rawSizes is Map ? rawSizes.values.toList() : [rawSizes]);

//       // Post-process sizes: unify numeric fields and compute discounted where promo exists
//       final promo = (details['promo'] is Map) ? Map<String, dynamic>.from(details['promo']) : null;
//       final int? promoPct = promo != null && (promo['discount_pct'] is num || promo['discount'] is num)
//           ? ((promo['discount_pct'] ?? promo['discount']) as num).round()
//           : null;

//       final List<Map<String, dynamic>> finalSizes = [];
//       for (var raw in normalizedInputSizes) {
//         if (raw is Map) {
//           final Map<String, dynamic> s = Map<String, dynamic>.from(raw);
//           final double? amount = _toDoubleNullable(s['amount'] ?? s['current'] ?? s['price'] ?? s['value']);
//           double? discounted;
//           if (amount != null && promoPct != null) {
//             discounted = ((amount * (100 - promoPct)) / 100);
//           } else {
//             discounted = _toDoubleNullable(s['discounted'] ?? s['promo_price'] ?? s['promo']);
//           }
//           s['amount'] = amount;
//           s['discounted'] = discounted;
//           // ensure discount_pct exists on the size so UI can display percent badge
//           if (!s.containsKey('discount_pct')) {
//             s['discount_pct'] = promoPct;
//           }
//           if (!s.containsKey('size')) {
//             s['size'] = s['plot_unit_label'] ?? s['plot_unit_name'] ?? s['plot_unit'] ?? s['size'] ?? '';
//           }
//           finalSizes.add(s);
//         } else {
//           finalSizes.add({'size': raw?.toString() ?? ''});
//         }
//       }

//       details['sizes'] = finalSizes;

//       debugPrint('EstateSizesModal -> normalized sizes count: ${finalSizes.length}');
//       if (finalSizes.isNotEmpty) debugPrint('First normalized size sample: ${jsonEncode(finalSizes.first)}');

//       setState(() {
//         _estateDetails = details;
//       });
//     } catch (e, st) {
//       debugPrint('Error loading estate details: $e\n$st');
//       setState(() {
//         _error = e.toString();
//       });
//     } finally {
//       setState(() {
//         _loading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currencyFormatter = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       child: Container(
//         constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//                 Text('Plot Sizes & Prices', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
//                 IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close))
//               ]),
//               const SizedBox(height: 16),
//               if (_loading)
//                 const Center(child: CircularProgressIndicator())
//               else if (_error != null)
//                 Center(child: Text('Error: $_error'))
//               else if (_estateDetails == null)
//                 const Center(child: Text('No details available'))
//               else
//                 Expanded(
//                   child: SingleChildScrollView(
//                     child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                       Text(_estateDetails!['estate_name'] ?? widget.estate['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
//                       const SizedBox(height: 16),
//                       if (_estateDetails!['promo'] != null && _estateDetails!['promo'] is Map && (_estateDetails!['promo'] as Map)['active'] == true)
//                         Padding(
//                           padding: const EdgeInsets.only(bottom: 16.0),
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                             decoration: BoxDecoration(color: Colors.deepOrange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.deepOrange.shade100)),
//                             child: Text('Promotion: -${(_estateDetails!['promo'] as Map)['discount']}% off',
//                                 style: TextStyle(color: Colors.deepOrange.shade800, fontWeight: FontWeight.w600)),
//                           ),
//                         ),
                      

//                       const Text('Available Plot Sizes:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
//                       const SizedBox(height: 8),
//                       if (_estateDetails!['sizes'] != null && (_estateDetails!['sizes'] as List).isNotEmpty)
//                         Container(
//                           decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
//                           child: ClipRRect(
//                             borderRadius: BorderRadius.circular(10),
//                             child: Table(
//                               columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(2), 2: FlexColumnWidth(2)},
//                               border: TableBorder.symmetric(inside: BorderSide(color: Colors.grey.shade200, width: 1), outside: BorderSide(color: Colors.grey.shade300, width: 1)),
//                               children: [
//                                 TableRow(decoration: BoxDecoration(color: Colors.grey.shade100), children: const [
//                                   Padding(padding: EdgeInsets.all(8.0), child: Text('Size', style: TextStyle(fontWeight: FontWeight.bold))),
//                                   Padding(padding: EdgeInsets.all(8.0), child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold))),
//                                   Padding(padding: EdgeInsets.all(8.0), child: Text('Promo Price', style: TextStyle(fontWeight: FontWeight.bold))),
//                                 ]),
//                                 for (var size in (_estateDetails!['sizes'] as List))
//                                   TableRow(children: [
//                                     Padding(padding: const EdgeInsets.all(8.0), child: Text(size['size']?.toString() ?? '')),
//                                     Padding(padding: const EdgeInsets.all(8.0), child: Text(size['amount'] != null ? currencyFormatter.format(size['amount']) : '—')),
//                                     Padding(
//                                       padding: const EdgeInsets.all(8.0),
//                                       child: Text(size['discounted'] != null ? currencyFormatter.format(size['discounted']) : '—',
//                                           style: TextStyle(fontWeight: FontWeight.bold, color: size['discounted'] != null ? Colors.green : Colors.grey)),
//                                     ),
//                                   ]),
//                               ],
//                             ),
//                           ),
//                         )
//                       else
//                         const Padding(padding: EdgeInsets.all(16.0), child: Text('No plot sizes available for this estate.')),
//                     ]),
//                   ),
//                 ),
//               const SizedBox(height: 16),
//               Align(alignment: Alignment.centerRight, child: ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')))
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }



// Truncate helper in extension
extension _StringExt on String {
  String truncate(int n) => length > n ? '${substring(0, n - 1)}…' : this;
}

