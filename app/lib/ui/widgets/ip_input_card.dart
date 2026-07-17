import 'package:flutter/material.dart';

class IpInputCard extends StatelessWidget {
  const IpInputCard({
    super.key,
    required this.controller,
    required this.onConnect,
    required this.onClear,
    required this.onAddressEdited,
  });

  final TextEditingController controller;
  final VoidCallback onConnect;
  final VoidCallback onClear;
  final ValueChanged<String> onAddressEdited;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE2D8C9).withValues(alpha: 0.3),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.wifi_rounded, size: 18, color: Color(0xFF8A7A66)),
              SizedBox(width: 6),
              Text(
                '局域网测试地址',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5C4B37),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '仅限隔离、可信局域网 IPv4；一次成功响应不代表设备在线或传感器已验证。',
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: Color(0xFF8A7A66),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: '输入 ESP32 局域网 IPv4 地址',
                    hintStyle: const TextStyle(color: Color(0xFFBDB3A6)),
                    filled: true,
                    fillColor: const Color(0xFFF9F6F0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: onAddressEdited,
                  onSubmitted: (_) => onConnect(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: onConnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5A623),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '请求',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('清除本机测试地址'),
            ),
          ),
        ],
      ),
    );
  }
}
