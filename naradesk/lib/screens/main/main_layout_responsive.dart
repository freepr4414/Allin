import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../layouts/responsive_layout.dart';
import '../../providers/auth_provider.dart';
import '../../providers/seat_provider.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  @override
  void initState() {
    super.initState();
    // 앱 시작 시 저장된 좌석 배치도 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(seatProvider.notifier).initializeWithSavedLayout();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (!authState.isAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return const ResponsiveLayout();
  }
}
