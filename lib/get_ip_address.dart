import 'dart:io';

Future<String?> getLocalIpv4() async {
  final interfaces = await NetworkInterface.list(
    includeLoopback: false,
    type: InternetAddressType.IPv4,
  );

  for (final interface in interfaces) {
    for (final addr in interface.addresses) {
      final ip = addr.address;

      // docker, virbr, veth 같은 가상 인터페이스를 대충 제외하고 싶을 때
      final name = interface.name.toLowerCase();
      final isVirtual =
          name.startsWith('docker') ||
          name.startsWith('veth') ||
          name.startsWith('virbr') ||
          name.startsWith('br-') ||
          name.startsWith('lo');

      if (!isVirtual) {
        return ip;
      }
    }
  }

  return null;
}
