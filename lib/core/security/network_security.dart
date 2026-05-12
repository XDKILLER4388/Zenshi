/// Documents the network security configuration.
/// The actual config is in android/app/src/main/res/xml/network_security_config.xml
/// which enforces HTTPS for all connections.
class NetworkSecurityConfig {
  static const bool enforceHttps = true;
  static const String minTlsVersion = '1.2';
}
