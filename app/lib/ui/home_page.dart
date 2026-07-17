import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/status.dart';
import '../services/api_service.dart';
import 'widgets/alert_banner.dart';
import 'widgets/ip_input_card.dart';
import 'widgets/sensor_card.dart';

const String kStorageKeyIp = 'beehive_monitor_ip';
const Duration kPollInterval = Duration(seconds: 3);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _ipController = TextEditingController();
  final BeehiveApiService _api = BeehiveApiService();
  StatusPayload? _data;
  String? _errorMsg;
  bool _lastRequestSucceeded = false;
  bool _requestInFlight = false;
  int _requestEpoch = 0;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadSavedIp();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedIp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(kStorageKeyIp);
      if (saved != null && saved.isNotEmpty && mounted) {
        _ipController.text = saved;
      }
    } catch (_) {}
    await _fetchStatus();
    if (!mounted) {
      return;
    }
    _startPoll();
  }

  String _normalizeHost(String raw) {
    var value = raw.trim().replaceFirst(
      RegExp(r'^https?://', caseSensitive: false),
      '',
    );
    final slash = value.indexOf('/');
    if (slash >= 0) {
      value = value.substring(0, slash);
    }
    return value;
  }

  void _startPoll() {
    _pollTimer?.cancel();
    if (_normalizeHost(_ipController.text).isEmpty) {
      return;
    }
    _pollTimer = Timer.periodic(kPollInterval, (_) => _fetchStatus());
  }

  void _onAddressEdited(String _) {
    _requestEpoch++;
    _pollTimer?.cancel();
    if (!mounted) {
      return;
    }
    setState(() {
      _data = null;
      _errorMsg = null;
      _lastRequestSucceeded = false;
    });
  }

  Future<void> _fetchStatus() async {
    if (_requestInFlight) return;
    final host = _normalizeHost(_ipController.text);
    final requestEpoch = _requestEpoch;
    if (host.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMsg = '请先填写局域网测试地址';
          _lastRequestSucceeded = false;
        });
      }
      return;
    }
    _requestInFlight = true;
    try {
      final payload = await _api.fetchStatus(host);
      if (!mounted ||
          requestEpoch != _requestEpoch ||
          host != _normalizeHost(_ipController.text)) {
        return;
      }
      setState(() {
        _data = payload;
        _errorMsg = null;
        _lastRequestSucceeded = true;
      });
    } catch (error) {
      if (!mounted ||
          requestEpoch != _requestEpoch ||
          host != _normalizeHost(_ipController.text)) {
        return;
      }
      setState(() {
        _data = null;
        _lastRequestSucceeded = false;
        _errorMsg = error.toString();
      });
    } finally {
      _requestInFlight = false;
    }
  }

  Future<void> _clearSavedIp() async {
    _requestEpoch++;
    _pollTimer?.cancel();
    _ipController.clear();
    try {
      await (await SharedPreferences.getInstance()).remove(kStorageKeyIp);
    } catch (_) {}
    if (!mounted) {
      return;
    }
    setState(() {
      _data = null;
      _errorMsg = '已清除本机测试地址';
      _lastRequestSucceeded = false;
    });
  }

  Future<void> _onConnect() async {
    _requestEpoch++;
    final host = _normalizeHost(_ipController.text);
    if (host.isNotEmpty) {
      _ipController.text = host;
      try {
        await (await SharedPreferences.getInstance()).setString(
          kStorageKeyIp,
          host,
        );
      } catch (_) {}
    }
    await _fetchStatus();
    if (!mounted) {
      return;
    }
    _startPoll();
  }

  String _formatNumber(double? value) =>
      value == null || !value.isFinite ? '—' : value.toStringAsFixed(1);

  String _labelText(String label) {
    switch (label) {
      case 'reference':
        return '参考内';
      case 'high_threshold':
        return '高阈值';
      case 'attention':
        return '参考外';
      case 'unavailable':
        return '未提供';
      default:
        return '未提供';
    }
  }

  BadgeStyle _labelStyle(String label) {
    switch (label) {
      case 'high_threshold':
        return BadgeStyle.bad;
      case 'attention':
        return BadgeStyle.warn;
      case 'reference':
      case 'unavailable':
        return BadgeStyle.muted;
      default:
        return BadgeStyle.muted;
    }
  }

  String _valueOrUnavailable(num? value, bool valid) {
    if (!valid || value == null) return '—';
    return value is int ? value.toString() : _formatNumber(value.toDouble());
  }

  String _labelOrUnavailable(String label, bool valid) =>
      valid ? _labelText(label) : '未提供';

  BadgeStyle _labelStyleOrUnavailable(String label, bool valid) =>
      valid ? _labelStyle(label) : BadgeStyle.muted;

  String _pressureDescription(StatusPayload? data) {
    final trend = data?.pressureTrend;
    final kind = data?.pressureTrendKind;
    if (trend == null || kind == null || kind == 'unknown') {
      return '正在收集数值趋势样本；这不是天气预测。';
    }
    return '源码归一化趋势：${trend.toStringAsFixed(1)} hPa / 3h（$kind，演示标签，不是天气预测）。';
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F2),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchStatus,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              '蜂箱传感器采样',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2D1F11),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _lastRequestSucceeded
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _lastRequestSucceeded ? '本次请求成功' : '未取得本次响应',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _lastRequestSucceeded
                                    ? const Color(0xFF065F46)
                                    : const Color(0xFF4B5563),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 16),
                        child: Text(
                          '实验性传感器输入与固定阈值标签；不代表蜂群健康、蜂箱安全、天气、烟雾浓度或设备在线。',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Color(0xFF8A7A66),
                          ),
                        ),
                      ),
                      SampleLabelBanner(label: data?.overallLabel),
                      IpInputCard(
                        controller: _ipController,
                        onConnect: _onConnect,
                        onClear: _clearSavedIp,
                        onAddressEdited: _onAddressEdited,
                      ),
                      if (_errorMsg != null && _errorMsg!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _errorMsg!,
                            style: const TextStyle(
                              color: Color(0xFF991B1B),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      if (data case final currentData?) ...[
                        _sensorGrid(
                          SensorCard(
                            icon: '🌡',
                            title: '温度',
                            valueText: _valueOrUnavailable(
                              currentData.temperature,
                              currentData.temperatureValid,
                            ),
                            unit: '°C',
                            description: currentData.temperatureValid
                                ? 'DHT11 本次实验读数；固定阈值不是蜂群健康判断。'
                                : 'DHT11 本次未取得有效读数；不显示旧值。',
                            badgeText: _labelOrUnavailable(
                              currentData.labels.temperature,
                              currentData.temperatureValid,
                            ),
                            badgeStyle: _labelStyleOrUnavailable(
                              currentData.labels.temperature,
                              currentData.temperatureValid,
                            ),
                          ),
                          SensorCard(
                            icon: '💧',
                            title: '湿度',
                            valueText: _valueOrUnavailable(
                              currentData.humidity,
                              currentData.humidityValid,
                            ),
                            unit: '%',
                            description: currentData.humidityValid
                                ? 'DHT11 本次实验读数；固定阈值不是蜂箱环境标准。'
                                : 'DHT11 本次未取得有效读数；不显示旧值。',
                            badgeText: _labelOrUnavailable(
                              currentData.labels.humidity,
                              currentData.humidityValid,
                            ),
                            badgeStyle: _labelStyleOrUnavailable(
                              currentData.labels.humidity,
                              currentData.humidityValid,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _sensorGrid(
                          SensorCard(
                            icon: '☀',
                            title: '光照',
                            valueText: _valueOrUnavailable(
                              currentData.light,
                              currentData.lightValid,
                            ),
                            unit: 'lux',
                            description: currentData.lightValid
                                ? 'BH1750 本次实验读数；不能推断箱盖、蜂群或安全状态。'
                                : currentData.bh1750Ok
                                ? 'BH1750 本次未取得有效读数；不显示旧值。'
                                : '当前响应报告 BH1750 初始化失败；不显示读数。',
                            badgeText: _labelOrUnavailable(
                              currentData.labels.light,
                              currentData.lightValid,
                            ),
                            badgeStyle: _labelStyleOrUnavailable(
                              currentData.labels.light,
                              currentData.lightValid,
                            ),
                          ),
                          SensorCard(
                            icon: '🔊',
                            title: '声音幅度',
                            valueText: _valueOrUnavailable(
                              currentData.soundLevel,
                              currentData.soundValid,
                            ),
                            unit: 'ADC',
                            description: currentData.soundValid
                                ? 'LM386 峰峰 ADC 输入；不是蜂群健康、攻击行为或异常诊断。'
                                : '声音幅度本次未提供；不显示推测值。',
                            badgeText: _labelOrUnavailable(
                              currentData.labels.sound,
                              currentData.soundValid,
                            ),
                            badgeStyle: _labelStyleOrUnavailable(
                              currentData.labels.sound,
                              currentData.soundValid,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _sensorGrid(
                          SensorCard(
                            icon: '〽',
                            title: 'MQ-2 原始 ADC',
                            valueText: _valueOrUnavailable(
                              currentData.mq2Raw,
                              currentData.mq2Valid,
                            ),
                            unit: 'ADC',
                            description: currentData.mq2Valid
                                ? '未经浓度校准的原始输入；不是烟雾/燃气/火灾检测或安全告警。'
                                : 'MQ-2 仍在预热或本次未提供；不显示推测值。',
                            badgeText: _labelOrUnavailable(
                              currentData.labels.mq2,
                              currentData.mq2Valid,
                            ),
                            badgeStyle: _labelStyleOrUnavailable(
                              currentData.labels.mq2,
                              currentData.mq2Valid,
                            ),
                          ),
                          SensorCard(
                            icon: '🎈',
                            title: '气压',
                            valueText: _valueOrUnavailable(
                              currentData.pressure,
                              currentData.pressureValid,
                            ),
                            unit: 'hPa',
                            description: currentData.pressureValid
                                ? _pressureDescription(data)
                                : currentData.bmp280Ok
                                ? 'BMP280 本次未取得有效读数；不显示旧值，也不推断趋势。'
                                : '当前响应报告 BMP280 初始化失败；不显示读数。',
                            badgeText: _labelOrUnavailable(
                              currentData.labels.pressure,
                              currentData.pressureValid,
                            ),
                            badgeStyle: _labelStyleOrUnavailable(
                              currentData.labels.pressure,
                              currentData.pressureValid,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _MetaFooter(data: data),
                      ] else
                        const _NoResponseState(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sensorGrid(Widget left, Widget right) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: left),
      const SizedBox(width: 16),
      Expanded(child: right),
    ],
  );
}

class _MetaFooter extends StatelessWidget {
  const _MetaFooter({required this.data});
  final StatusPayload? data;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF0EBE1)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '本次本地响应信息',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8A7A66),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          data?.uptime != null ? '运行时间字段：${data!.uptime}s' : '运行时间字段：—',
          style: const TextStyle(fontSize: 13, color: Color(0xFF8A7A66)),
        ),
        const SizedBox(height: 4),
        Text(
          'BH1750 初始化标志：${data?.bh1750Ok == true
              ? "true"
              : data?.bh1750Ok == false
              ? "false"
              : "—"}',
          style: const TextStyle(fontSize: 13, color: Color(0xFF8A7A66)),
        ),
        const SizedBox(height: 4),
        Text(
          'BMP280 初始化标志：${data?.bmp280Ok == true
              ? "true"
              : data?.bmp280Ok == false
              ? "false"
              : "—"}',
          style: const TextStyle(fontSize: 13, color: Color(0xFF8A7A66)),
        ),
      ],
    ),
  );
}

class _NoResponseState extends StatelessWidget {
  const _NoResponseState();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF0EBE1)),
    ),
    child: const Text(
      '尚无本次可解析响应，因此不显示缓存或推测传感器读数。',
      style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF8A7A66)),
    ),
  );
}
