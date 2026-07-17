from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding='utf-8')


class SourceContracts(unittest.TestCase):
    def test_platform_and_source_gpio_contract(self):
        self.assertIn('platform = espressif32@6.13.0', read('firmware/platformio.ini'))
        config = read('firmware/src/config.h')
        for value in ['#define DHT11_PIN 4', '#define I2C_SDA 21', '#define I2C_SCL 22', '#define SOUND_PIN 34', '#define MQ2_PIN 35', '#define STATUS_LED_PIN 2']:
            self.assertIn(value, config)

    def test_no_default_network_and_http_stays_off_without_local_file(self):
        config = read('firmware/src/config.h')
        main = read('firmware/src/main.cpp')
        self.assertIn('#if __has_include("wifi_credentials.h")', config)
        self.assertIn('#define WIFI_SSID ""', config)
        self.assertIn('No local credentials: sensor sampling only; HTTP disabled.', main)
        self.assertIn('if (!httpStarted && WiFi.status() == WL_CONNECTED)', main)
        self.assertNotIn('Serial.println(WIFI_SSID)', main)

    def test_api_uses_local_response_and_neutral_labels(self):
        server = read('firmware/src/web_server.cpp')
        self.assertIn('document["status"] = "local_response"', server)
        self.assertIn('document["mq2Raw"]', server)
        self.assertIn('"high_threshold"', server)
        self.assertIn('"unavailable"', server)
        self.assertIn('document["temperatureValid"]', server)
        self.assertIn('document["mq2Valid"]', server)
        self.assertNotIn('Access-Control-Allow-Origin', server)
        self.assertIn('server_.send(405', server)

    def test_flutter_state_does_not_claim_device_online(self):
        home = read('app/lib/ui/home_page.dart')
        self.assertIn("'本次请求成功'", home)
        self.assertNotIn("'已连接'", home)
        self.assertIn('if (_requestInFlight) return;', home)
        self.assertRegex(home, r'_data = null;\s+_lastRequestSucceeded = false;')
        self.assertIn('尚无本次可解析响应，因此不显示缓存或推测传感器读数。', home)
        self.assertIn('不代表设备在线或传感器已验证', read('app/lib/ui/widgets/ip_input_card.dart'))
        self.assertIn('清除本机测试地址', read('app/lib/ui/widgets/ip_input_card.dart'))
        self.assertIn('remove(kStorageKeyIp)', home)
        self.assertIn('int _requestEpoch = 0;', home)
        self.assertIn('requestEpoch != _requestEpoch', home)
        self.assertIn('onAddressEdited: _onAddressEdited', home)
        self.assertIn('onChanged: onAddressEdited', read('app/lib/ui/widgets/ip_input_card.dart'))

    def test_flutter_host_is_constrained_to_private_ipv4(self):
        api = read('app/lib/services/api_service.dart')
        self.assertIn('仅接受可信局域网 IPv4 地址', api)
        self.assertIn("RegExp(r'^(?:0|[1-9][0-9]{0,2})$')", api)
        self.assertIn('_canonicalTrustedLocalHost(host)', api)
        self.assertIn('(a == 172 && b >= 16 && b <= 31)', api)
        self.assertIn('(a == 192 && b == 168)', api)
        self.assertNotIn("endsWith('.local')", api)
        self.assertIn('..followRedirects = false', api)
        self.assertIn('..maxRedirects = 0', api)
        self.assertIn('client.close()', api)
        manifest = read('app/android/app/src/main/AndroidManifest.xml')
        self.assertIn('android:allowBackup="false"', manifest)
        self.assertIn('应用数据备份', read('app/README.md'))

    def test_invalid_sensor_samples_are_not_rendered_as_reference(self):
        sensors = read('firmware/src/sensors.cpp')
        labels = read('firmware/src/sensors.h')
        home = read('app/lib/ui/home_page.dart')
        payload = read('app/lib/models/status.dart')
        self.assertIn('SampleLabel::Unavailable', sensors)
        self.assertIn('temperature_ = temperatureValid_ ? t : NAN;', sensors)
        self.assertIn('lightLux_ = lightValid_ ? lux : NAN;', sensors)
        self.assertIn('pressureHpa_ = pressureValid_ ? p : NAN;', sensors)
        self.assertIn('mq2SampleReady_ = static_cast<long>(millis() - preheatDoneMs_) >= 0;', sensors)
        self.assertIn('Unavailable = 3', labels)
        self.assertIn("'unavailable'", payload)
        self.assertIn("'未提供'", home)
        self.assertIn('currentData.temperatureValid', home)
        self.assertIn('currentData.mq2Valid', home)
        self.assertIn("label == 'unavailable'", read('app/lib/ui/widgets/alert_banner.dart'))
        self.assertIn('不作状态结论', read('app/lib/ui/widgets/alert_banner.dart'))
        self.assertIn('soundLevel < -1', payload)
        self.assertIn('pressureHistoryCount < 0', payload)
        self.assertIn('(soundValid && soundLevel < 0)', payload)
        self.assertIn('_labelMatchesValidity', payload)
        self.assertIn('!temperatureValid && temperature != null', payload)
        self.assertIn("StatusPayload.tryParse", read('app/test/status_test.dart'))

    def test_verifier_and_ci_require_dart_format(self):
        self.assertIn('dart format --output=none --set-exit-if-changed lib test', read('scripts/verify.sh'))
        self.assertIn('dart format --output=none --set-exit-if-changed lib test', read('.github/workflows/validate.yml'))

    def test_widget_test_tracks_visible_title(self):
        self.assertIn("find.text('蜂箱传感器采样')", read('app/test/widget_test.dart'))
        self.assertIn("'蜂箱传感器采样'", read('app/lib/ui/home_page.dart'))

    def test_safe_source_manifest_is_reproducible_without_credential_config(self):
        allowlist = read('docs/source-allowlist.txt')
        manifest = read('scripts/source_manifest.py')
        self.assertNotIn('firmware/src/config.h\n', allowlist)
        self.assertIn("'firmware/src/config.h'", manifest)
        self.assertIn("'firmware/src/wifi_credentials.h'", manifest)
        self.assertIn("'app/android/local.properties'", manifest)
        self.assertIn('safe_paths()', manifest)


if __name__ == '__main__':
    unittest.main()
