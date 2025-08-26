 Widget _performanceContent(Map<String, dynamic> profile) {
    final performance = (profile['performance'] as Map<String, dynamic>?) ?? {};
    final currentYear = profile['current_year'] ?? DateTime.now().year;

    final closedDeals = _toInt(performance['closed_deals']);
    final commissionEarned = _toDouble(performance['commission_earned']);
    final commissionRate = (_toDouble(performance['commission_rate']).clamp(0.0, 100.0));
    final yearlyTargetAchievementRaw = performance['yearly_target_achievement'];
    final yearlyTargetAchievement = yearlyTargetAchievementRaw != null ? _toDouble(yearlyTargetAchievementRaw).clamp(0.0, 100.0) : null;

    // animation durations
    const animDur = Duration(milliseconds: 900);
    const delayShort = Duration(milliseconds: 120);

    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 720;
      // clamp sizes relative to available width
      final circleSmall = (isNarrow ? 56.0 : 64.0).clamp(56.0, 80.0);
      final circleBig = (isNarrow ? 96.0 : 120.0).clamp(80.0, 140.0);

      Widget closedDealsCard() => TweenAnimationBuilder<double>(
        duration: animDur,
        tween: Tween(begin: 0.0, end: closedDeals.toDouble()),
        builder: (context, value, child) {
          return Container(
            padding: const EdgeInsets.all(14),
            // remove fixed right margin to avoid overflow inside rows; spacing handled outside
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(colors: [Colors.white, Colors.white.withOpacity(0.95)]),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 10))],
              border: Border.all(color: Colors.grey.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                // icon + glow
                Container(
                  width: circleSmall,
                  height: circleSmall,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [const Color(0xFFE9FFF6), const Color(0xFFDFF7EF)]),
                    boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.14), blurRadius: 16, spreadRadius: 1)],
                  ),
                  child: Center(child: Icon(Icons.check_circle_outline, size: circleSmall * 0.47, color: const Color(0xFF10B981))),
                ),
                const SizedBox(width: 12),
                // allow text area to shrink properly
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Closed Deals', style: GoogleFonts.sora(fontSize: 13, color: Colors.grey[700])),
                      const SizedBox(height: 6),
                      Text('${value.toInt()}', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.sora(fontSize: 28, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      Text('Deals closed this year', style: GoogleFonts.sora(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );

      Widget commissionCard() => TweenAnimationBuilder<double>(
        duration: animDur,
        tween: Tween(begin: 0.0, end: commissionEarned),
        builder: (context, value, child) {
          final pct = (commissionRate / 100.0).clamp(0.0, 1.0);
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(colors: [const Color(0xFFEEF2FF), Colors.white]),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18, offset: const Offset(0, 10))],
              border: Border.all(color: Colors.grey.withOpacity(0.04)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  // animated circular percent
                  SizedBox(
                    width: circleSmall,
                    height: circleSmall,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: pct),
                          duration: animDur,
                          builder: (context, v, _) => CircularProgressIndicator(
                            value: v,
                            strokeWidth: 6,
                            backgroundColor: Colors.white,
                            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF4154F1)),
                          ),
                        ),
                        Text('${(commissionRate).toStringAsFixed(0)}%', style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Commission Earned', style: GoogleFonts.sora(fontSize: 13, color: Colors.grey[700])),
                      const SizedBox(height: 6),
                      // Prevent overflow by allowing the number to wrap or ellipsize
                      Text(formatCurrency(value, decimalDigits: 0), maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('Based on current rate', style: GoogleFonts.sora(fontSize: 12, color: Colors.grey[500])),
                    ]),
                  ),
                ]),
                const SizedBox(height: 12),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: pct),
                  duration: animDur,
                  builder: (context, v, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: v,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF4154F1)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

      Widget topMetrics;
      if (isNarrow) {
        topMetrics = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            closedDealsCard(),
            const SizedBox(height: 12),
            commissionCard(),
          ],
        );
      } else {
        topMetrics = Row(
          children: [
            Expanded(child: closedDealsCard()),
            const SizedBox(width: 12),
            Expanded(child: commissionCard()),
          ],
        );
      }

      // large card (Yearly target + breakdown)
      Widget largeCard = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, scale, child) {
          return Transform.scale(scale: 0.98 + 0.02 * scale, child: Opacity(opacity: scale, child: child));
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(colors: [Colors.white, Colors.white]),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 12))],
          ),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // stacked: big circular then breakdown below
                    Text('Yearly Target Achievement', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Row(children: [
                      SizedBox(
                        width: circleBig,
                        height: circleBig,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: yearlyTargetAchievement != null ? (yearlyTargetAchievement / 100.0).clamp(0.0, 1.0) : 0.0),
                          duration: const Duration(milliseconds: 900),
                          builder: (context, v, _) {
                            final displayPct = yearlyTargetAchievement != null ? yearlyTargetAchievement.toStringAsFixed(0) : '—';
                            return Stack(alignment: Alignment.center, children: [
                              SizedBox(
                                width: circleBig,
                                height: circleBig,
                                child: CircularProgressIndicator(
                                  value: v,
                                  strokeWidth: 10,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF10B981)),
                                ),
                              ),
                              Column(mainAxisSize: MainAxisSize.min, children: [
                                Text(yearlyTargetAchievement != null ? '$displayPct%' : '—', style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 6),
                                Text(yearlyTargetAchievement != null ? 'of target' : 'No target', style: GoogleFonts.sora(fontSize: 12, color: Colors.grey[600])),
                              ]),
                            ]);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // compact description for narrow screens
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Progress toward annual sales target', style: GoogleFonts.sora(fontSize: 13, color: Colors.grey[700])),
                          const SizedBox(height: 12),
                          Wrap(spacing: 10, runSpacing: 8, children: [
                            _smallStatBox(title: 'Target Achievement', value: yearlyTargetAchievement != null ? '${yearlyTargetAchievement.toStringAsFixed(0)}%' : '—'),
                            _smallStatBox(title: 'Commission Rate', value: '${commissionRate.toStringAsFixed(1)}%'),
                          ]),
                          const SizedBox(height: 12),
                          Text('Legend', style: GoogleFonts.sora(fontSize: 12, color: Colors.grey[600])),
                          const SizedBox(height: 6),
                          Row(children: [
                            _legendDot(color: const Color(0xFF10B981), label: 'Achieved'),
                            const SizedBox(width: 8),
                            _legendDot(color: Colors.grey.shade300, label: 'Remaining'),
                          ]),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    Divider(),
                    const SizedBox(height: 12),
                    Text('Commission Breakdown', style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    _animatedMetricRow(label: 'Total Earned', value: formatCurrency(commissionEarned, decimalDigits: 0), delay: delayShort),
                    const SizedBox(height: 10),
                    _animatedMetricRow(label: 'Commission Rate', value: '${commissionRate.toStringAsFixed(1)}%'),
                    const SizedBox(height: 10),
                    _animatedMetricRow(label: 'Closed Deals', value: '$closedDeals'),
                    const SizedBox(height: 18),
                    // wrap button to avoid overflow
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: ElevatedButton.icon(
                          onPressed: () => _tabController.animateTo(3),
                          icon: const Icon(Icons.trending_up),
                          label: Text('Adjust Profile / Targets', style: GoogleFonts.sora(fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                            backgroundColor: const Color(0xFF4154F1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Yearly Target Achievement', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Row(children: [
                          SizedBox(
                            width: circleBig,
                            height: circleBig,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: yearlyTargetAchievement != null ? (yearlyTargetAchievement / 100.0).clamp(0.0, 1.0) : 0.0),
                              duration: const Duration(milliseconds: 900),
                              builder: (context, v, _) {
                                final displayPct = yearlyTargetAchievement != null ? yearlyTargetAchievement.toStringAsFixed(0) : '—';
                                return Stack(alignment: Alignment.center, children: [
                                  SizedBox(
                                    width: circleBig,
                                    height: circleBig,
                                    child: CircularProgressIndicator(
                                      value: v,
                                      strokeWidth: 10,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF10B981)),
                                    ),
                                  ),
                                  Column(mainAxisSize: MainAxisSize.min, children: [
                                    Text(yearlyTargetAchievement != null ? '$displayPct%' : '—', style: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 6),
                                    Text(yearlyTargetAchievement != null ? 'of target' : 'No target', style: GoogleFonts.sora(fontSize: 12, color: Colors.grey[600])),
                                  ]),
                                ]);
                              },
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Progress toward annual sales target', style: GoogleFonts.sora(fontSize: 13, color: Colors.grey[700])),
                              const SizedBox(height: 12),
                              Row(children: [
                                _smallStatBox(title: 'Target Achievement', value: yearlyTargetAchievement != null ? '${yearlyTargetAchievement.toStringAsFixed(0)}%' : '—'),
                                const SizedBox(width: 10),
                                _smallStatBox(title: 'Commission Rate', value: '${commissionRate.toStringAsFixed(1)}%'),
                              ]),
                              const SizedBox(height: 12),
                              Text('Legend', style: GoogleFonts.sora(fontSize: 12, color: Colors.grey[600])),
                              const SizedBox(height: 6),
                              Row(children: [
                                _legendDot(color: const Color(0xFF10B981), label: 'Achieved'),
                                const SizedBox(width: 8),
                                _legendDot(color: Colors.grey.shade300, label: 'Remaining'),
                              ]),
                            ]),
                          ),
                        ]),
                      ]),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 4,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Commission Breakdown', style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        _animatedMetricRow(label: 'Total Earned', value: formatCurrency(commissionEarned, decimalDigits: 0), delay: delayShort),
                        const SizedBox(height: 10),
                        _animatedMetricRow(label: 'Commission Rate', value: '${commissionRate.toStringAsFixed(1)}%'),
                        const SizedBox(height: 10),
                        _animatedMetricRow(label: 'Closed Deals', value: '$closedDeals'),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: () => _tabController.animateTo(3),
                          icon: const Icon(Icons.trending_up),
                          label: Text('Adjust Profile / Targets', style: GoogleFonts.sora(fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                            backgroundColor: const Color(0xFF4154F1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        )
                      ]),
                    ),
                  ],
                ),
        ),
      );

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Title + subtle subtitle
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Flexible(child: Text('Your Performance', style: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.w800))),
            const SizedBox(width: 8),
            Opacity(
              opacity: 0.65,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• latest insights', style: GoogleFonts.sora(fontSize: 13)),
              ),
            ),
            const Spacer(),
            // small last-updated chip
            Chip(
              label: Text('$currentYear', style: GoogleFonts.sora(fontSize: 12, color: Colors.white)),
              backgroundColor: const Color(0xFF2DD4BF),
              visualDensity: VisualDensity.compact,
            )
          ]),
          const SizedBox(height: 18),
          topMetrics,
          const SizedBox(height: 18),
          largeCard,
        ]),
      );
    });
  }