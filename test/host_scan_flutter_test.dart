import 'package:flutter/foundation.dart';
import 'package:network_tools/network_tools.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_tools_flutter/network_tools_flutter.dart';
import 'package:universal_io/io.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  int port = 0;
  String myOwnHost = "0.0.0.0";
  String interfaceIp = myOwnHost.substring(0, myOwnHost.lastIndexOf('.'));
  late ServerSocket server;
  // Fetching interfaceIp and hostIp
  setUpAll(() async {
    //open a port in shared way because of portscanner using same,
    //if passed false then two hosts come up in search and breaks test.
    server =
        await ServerSocket.bind(InternetAddress.anyIPv4, port, shared: true);
    port = server.port;
    debugPrint('opened port at $port');
    final interfaceList =
        await NetworkInterface.list(); //will give interface list
    if (interfaceList.isNotEmpty) {
      final localInterface =
          interfaceList.elementAt(0); //fetching first interface like en0/eth0
      if (localInterface.addresses.isNotEmpty) {
        final address = localInterface.addresses
            .elementAt(0)
            .address; //gives IP address of GHA local machine.
        myOwnHost = address;
        interfaceIp = address.substring(0, address.lastIndexOf('.'));
        debugPrint("own host $myOwnHost and interfaceIp $interfaceIp");
      }
    }
  });

  group('Testing Host Scanner emits', () {
    test('Running getAllPingableDevices emits tests', () async {
      expectLater(
        //There should be at least one device pingable in network
        HostScannerFlutter.getAllPingableDevices(
          interfaceIp,
        ),
        emits(isA<ActiveHost>()),
      );
      // own host can be 254, 1 sec per host means timeout atleast 260 secs.
    }, timeout: const Timeout(Duration(seconds: 260)));
  });

  group('Testing Host Scanner emitsThrough', () {
    test('Running getAllPingableDevices emitsThrough tests', () async {
      expectLater(
        //Should emit at least our own local machine when pinging all hosts.
        HostScannerFlutter.getAllPingableDevices(
          interfaceIp,
        ),
        emitsThrough(ActiveHost(internetAddress: InternetAddress(myOwnHost))),
      );
      // own host can be 254, 1 sec per host means timeout atleast 260 secs.
    }, timeout: const Timeout(Duration(seconds: 260)));
  });

  tearDownAll(() {
    server.close();
  });
}
