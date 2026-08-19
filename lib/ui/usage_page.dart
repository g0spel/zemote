import 'package:flutter/material.dart';

import '../protocol/zemote_client.dart';
import 'theme.dart';

/// Entitlement / quota usage page (usage-stats.getEntitlementSnapshot).
///
/// Field semantics (verified against the desktop client and a live
/// snapshot):
/// - `remaining`: MCP quota — `count` = remaining calls, `percentage` is a
///   0–1 REMAINING ratio; the total lives on the TIME-LIMIT/unit-5 limit
///   row (`usage` = total, `currentValue` = used).
/// - TOKENS_LIMIT rows: `percentage` is the USED percent (0–100), so
///   remaining = 100 − percentage. unit 3 = 5-hour window, unit 6 = weekly.
/// - subscription `renewTime`/`expireTime` are ISO-8601 strings.

/// The MCP quota limit row (duplicated by the top remaining card).
bool isMcpQuotaLimit(Map<String, dynamic> limit) =>
    limit['type'] == 'TIME_LIMIT' && limit['unit'] == 5;

int? mcpQuotaTotal(List<dynamic> limits) {
  for (final l in limits) {
    if (l is Map && isMcpQuotaLimit(l.cast<String, dynamic>())) {
      return (l['usage'] as num?)?.toInt();
    }
  }
  return null;
}

String limitWindowLabel(Map<String, dynamic> limit) {
  if (limit['type'] == 'TOKENS_LIMIT') {
    if (limit['unit'] == 3) return '五小时剩余';
    if (limit['unit'] == 6) return '每周剩余';
    return '额度剩余';
  }
  return '${limit['type'] ?? ''} · unit ${limit['unit'] ?? '-'}';
}

/// TOKENS percentage = used% → remaining% = 100 − used.
int? tokensRemainingPercent(Map<String, dynamic> limit) {
  final used = (limit['percentage'] as num?)?.toDouble();
  if (used == null) return null;
  return (100 - used).round().clamp(0, 100);
}

/// Subscription times are ISO strings, not millis.
String fmtIsoTime(Object? v) {
  if (v is! String || v.trim().isEmpty) return '-';
  final t = DateTime.tryParse(v.trim());
  if (t == null) return v;
  final local = t.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}
class UsagePage extends StatefulWidget {
  final BridgeSession session;

  const UsagePage({super.key, required this.session});

  @override
  State<UsagePage> createState() => _UsagePageState();
}

class _UsagePageState extends State<UsagePage> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await widget.session.channels.call(
        'usage-stats',
        'getEntitlementSnapshot',
        [
          {'includeSubscription': true},
        ],
      );
      if (mounted) {
        setState(() {
          _data = res is Map ? res.cast<String, dynamic>() : {};
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  String _fmtTime(Object? millis) {
    if (millis is! num) return '-';
    final t =
        DateTime.fromMillisecondsSinceEpoch(millis.toInt()).toLocal();
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-'
        '${t.day.toString().padLeft(2, '0')} '
        '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用量'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('加载失败: $_error'))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final data = _data ?? const {};
    final context_ = data['context'];
    final provider = data['provider'];
    final remaining = data['remaining'];
    final subscription = data['subscription'];
    final quota = data['quota'];
    final limits = quota is Map && quota['limits'] is List
        ? quota['limits'] as List
        : const [];
    final mcpTotal = mcpQuotaTotal(limits);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ZColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.bolt,
                        color: ZColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context_ is Map
                              ? '${context_['displayName'] ?? '-'}'
                              : '-',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          [
                            if (provider is Map)
                              '${provider['name'] ?? ''}',
                            if (quota is Map && quota['level'] != null)
                              '${quota['level']}',
                          ].join(' · '),
                          style: TextStyle(
                              fontSize: 12, color: ZInk.faint(context)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (remaining is Map && remaining['isShow'] == true)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('剩余 MCP 额度',
                            style: TextStyle(fontSize: 14)),
                        Text(
                          mcpTotal == null
                              ? '${remaining['count'] ?? '-'}'
                              : '${remaining['count'] ?? '-'} / $mcpTotal',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: ZColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        // percentage here is a 0–1 REMAINING ratio.
                        value:
                            ((remaining['percentage'] as num?) ?? 0)
                                .toDouble()
                                .clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.08),
                        valueColor: const AlwaysStoppedAnimation(
                            ZColors.primary),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '剩余 ${((((remaining['percentage'] as num?) ?? 0) * 100)).round()}% · '
                      '重置时间 ${_fmtTime(remaining['nextResetTime'])}',
                      style: TextStyle(
                          fontSize: 11, color: ZInk.faint(context)),
                    ),
                  ],
                ),
              ),
            ),
          if (limits.isNotEmpty) ...[
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('配额限制',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    // The MCP quota row is covered by the top card.
                    for (final limit in limits)
                      if (limit is Map &&
                          !isMcpQuotaLimit(limit.cast<String, dynamic>()))
                        _LimitRow(
                            limit: limit.cast<String, dynamic>(),
                            fmtTime: _fmtTime),
                  ],
                ),
              ),
            ),
          ],
          if (subscription is Map &&
              subscription['details'] is List &&
              (subscription['details'] as List).isNotEmpty) ...[
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('订阅',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    for (final d in subscription['details'] as List)
                      if (d is Map) ...[
                        _kv('产品', '${d['productName'] ?? '-'}'),
                        _kv('计费周期', '${d['billingCycle'] ?? '-'}'),
                        _kv('续费时间', fmtIsoTime(d['renewTime'])),
                        _kv('到期时间', fmtIsoTime(d['expireTime'])),
                      ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: ZInk.muted(context))),
          Flexible(
            child: Text(value,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

class _LimitRow extends StatelessWidget {
  final Map<String, dynamic> limit;
  final String Function(Object?) fmtTime;

  const _LimitRow({required this.limit, required this.fmtTime});

  @override
  Widget build(BuildContext context) {
    final label = limitWindowLabel(limit);
    // TOKENS percentage = used%; remaining = 100 − used.
    final remaining = tokensRemainingPercent(limit);
    final percentage = (limit['percentage'] as num?)?.toDouble();
    final usageDetails = limit['usageDetails'];
    final color = remaining == null
        ? ZColors.primary
        : remaining <= 10
            ? ZColors.danger
            : remaining <= 20
                ? ZColors.warning
                : ZColors.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              Text(
                [
                  if (remaining != null) '剩余 $remaining%',
                  if (percentage != null) '已用 ${percentage.round()}%',
                ].join(' · '),
                style: TextStyle(
                    fontSize: 11, color: ZInk.muted(context)),
              ),
            ],
          ),
          if (remaining != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (remaining / 100).clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor:
                      Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
          if (usageDetails is List && usageDetails.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                usageDetails
                    .whereType<Map>()
                    .map((u) => '${u['modelCode']}: ${u['usage']}')
                    .join('  '),
                style: TextStyle(
                    fontSize: 10, color: ZInk.faint(context)),
              ),
            ),
          Text(
            '重置 ${fmtTime(limit['nextResetTime'])}',
            style:
                TextStyle(fontSize: 10, color: ZInk.ghost(context)),
          ),
        ],
      ),
    );
  }
}
