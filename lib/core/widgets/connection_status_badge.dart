import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/configuration/app_config.dart';
import '../../app/theme/ember_theme.dart';
import '../../data/providers/app_providers.dart';
import '../networking/websocket_client.dart';

class ConnectionStatusBadge extends ConsumerWidget {
  final bool compact;
  const ConnectionStatusBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appModeProvider);
    final wsClient = ref.watch(realtimeClientProvider);

    return StreamBuilder<WsConnectionStatus>(
      stream: wsClient.statusStream,
      initialData: wsClient.status,
      builder: (context, snapshot) {
        final status = snapshot.data ?? wsClient.status;

        Color dotColor;
        String text;

        if (mode == AppMode.fixture) {
          dotColor = EmberColors.warning;
          text = compact ? 'OFFLINE' : 'OFFLINE (FIXTURE DEMO)';
        } else {
          switch (status) {
            case WsConnectionStatus.connected:
              dotColor = EmberColors.success;
              text = compact ? 'LIVE' : 'CONNECTED';
              break;
            case WsConnectionStatus.connecting:
              dotColor = EmberColors.warning;
              text = compact ? 'CONNECTING' : 'CONNECTING...';
              break;
            case WsConnectionStatus.reconnecting:
              dotColor = EmberColors.warning;
              text = compact ? 'SYNCING' : 'RECONNECTING...';
              break;
            case WsConnectionStatus.disconnected:
              dotColor = EmberColors.error;
              text = compact ? 'DISCONNECTED' : 'DISCONNECTED';
              break;
          }
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: dotColor,
              ),
            ),
          ],
        );
      },
    );
  }
}
