import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class SystemHealthScreen extends StatefulWidget {
  const SystemHealthScreen({super.key});

  @override
  State<SystemHealthScreen> createState() => _SystemHealthScreenState();
}

class _SystemHealthScreenState extends State<SystemHealthScreen> {
  late Timer _timer;
  double _latency = 14.0;
  double _cpuUsage = 12.0;
  double _memoryUsage = 45.0;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _startSimulatedMonitoring();
  }

  void _startSimulatedMonitoring() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _latency = 10 + _random.nextDouble() * 15;
          _cpuUsage = 8 + _random.nextDouble() * 20;
          _memoryUsage = 42 + _random.nextDouble() * 5;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('System Health', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildStatusHeader(isDark),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildMetricCard('API Latency', '${_latency.toStringAsFixed(1)}ms', Icons.speed_rounded, Colors.blue, isDark)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard('Uptime', '99.98%', Icons.timer_rounded, Colors.green, isDark)),
              ],
            ),
            const SizedBox(height: 16),
            _buildLinearProgressMetric('CPU Usage', _cpuUsage / 100, '${_cpuUsage.toStringAsFixed(1)}%', Colors.orange, isDark),
            const SizedBox(height: 16),
            _buildLinearProgressMetric('Memory Usage', _memoryUsage / 100, '${_memoryUsage.toStringAsFixed(1)}%', Colors.purple, isDark),
            const SizedBox(height: 24),
            _buildServiceStatusList(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1754CF), Color(0xFF64B5F6)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('System Operational', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
              Text('All services are running normally', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
          Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildLinearProgressMetric(String title, double value, String percentage, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              Text(percentage, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceStatusList(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Service Status', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 16),
        _buildServiceItem('Firebase Auth', 'Active', Colors.green, isDark),
        _buildServiceItem('Cloud Firestore', 'Active', Colors.green, isDark),
        _buildServiceItem('Cloudinary Media', 'Active', Colors.green, isDark),
        _buildServiceItem('Push Notifications', 'Active', Colors.green, isDark),
        _buildServiceItem('Email Service', 'Active', Colors.green, isDark),
      ],
    );
  }

  Widget _buildServiceItem(String name, String status, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
        ],
      ),
    );
  }
}
