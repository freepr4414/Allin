import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../screens/main/main_layout.dart';

class SidePanel extends StatelessWidget {
  final SidePanelType sidePanelType;

  const SidePanel({super.key, required this.sidePanelType});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          left: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                Icon(sidePanelType.icon, color: Theme.of(context).colorScheme.primary, size: 20.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    sidePanelType.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 콘텐츠
          Expanded(child: _buildPanelContent(context)),
        ],
      ),
    );
  }

  Widget _buildPanelContent(BuildContext context) {
    switch (sidePanelType) {
      case SidePanelType.dashboard:
        return _buildDashboardPanel(context);
      case SidePanelType.members:
        return _buildMembersPanel(context);
      case SidePanelType.payments:
        return _buildPaymentsPanel(context);
      case SidePanelType.statistics:
        return _buildStatisticsPanel(context);
      case SidePanelType.settings:
        return _buildSettingsPanel(context);
    }
  }

  Widget _buildDashboardPanel(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        _buildSummaryCard(context, '오늘 매출', '₩1,234,567', Icons.attach_money, Colors.green),
        SizedBox(height: 12.h),
        _buildSummaryCard(context, '현재 이용객', '32명', Icons.people, Colors.blue),
        SizedBox(height: 12.h),
        _buildSummaryCard(context, '이용률', '75%', Icons.trending_up, Colors.orange),
        SizedBox(height: 20.h),

        Text(
          '최근 활동',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12.h),

        ...List.generate(
          5,
          (index) => _buildActivityItem(
            context,
            '김회원님이 ${index + 1}번 좌석에 입실했습니다.',
            '${15 - index}분 전',
            Icons.login,
          ),
        ),
      ],
    );
  }

  Widget _buildMembersPanel(BuildContext context) {
    return Column(
      children: [
        // 검색 및 필터
        Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: '회원 검색',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.person_add),
                      label: const Text('회원 추가'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 회원 목록
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: 10,
            itemBuilder: (context, index) => _buildMemberItem(
              context,
              '회원${index + 1}',
              '010-1234-567${index}',
              index % 3 == 0 ? '이용중' : '대기중',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentsPanel(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.payment),
                label: const Text('결제 처리'),
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),

        Text(
          '오늘 결제 내역',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12.h),

        ...List.generate(
          8,
          (index) => _buildPaymentItem(
            context,
            '회원${index + 1}',
            '시간권 3시간',
            '₩15,000',
            '${12 + index}:30',
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsPanel(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        _buildStatCard(context, '일간 통계', '오늘', '₩450,000', '48명'),
        SizedBox(height: 12.h),
        _buildStatCard(context, '주간 통계', '이번 주', '₩2,850,000', '312명'),
        SizedBox(height: 12.h),
        _buildStatCard(context, '월간 통계', '이번 달', '₩12,450,000', '1,247명'),
        SizedBox(height: 20.h),

        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '인기 시간대',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              Text('14:00 - 18:00 (75% 이용률)', style: TextStyle(fontSize: 12.sp)),
              Text('19:00 - 22:00 (82% 이용률)', style: TextStyle(fontSize: 12.sp)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsPanel(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        ListTile(
          leading: const Icon(Icons.store),
          title: const Text('매장 설정'),
          subtitle: const Text('매장 정보 및 운영시간'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.chair),
          title: const Text('좌석 설정'),
          subtitle: const Text('좌석 배치 및 요금'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.payment),
          title: const Text('결제 설정'),
          subtitle: const Text('결제 수단 및 정책'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('알림 설정'),
          subtitle: const Text('알림 및 메시지'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.backup),
          title: const Text('백업 및 복원'),
          subtitle: const Text('데이터 백업'),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, String text, String time, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: Theme.of(context).colorScheme.primary),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: TextStyle(fontSize: 12.sp)),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberItem(BuildContext context, String name, String phone, String status) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 16.r, child: Text(name.substring(0, 1))),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                ),
                Text(
                  phone,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: status == '이용중' ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10.sp,
                color: status == '이용중' ? Colors.green : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(
    BuildContext context,
    String member,
    String item,
    String amount,
    String time,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member,
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                ),
                Text(
                  item,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String period,
    String revenue,
    String visitors,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
          Text(
            period,
            style: TextStyle(
              fontSize: 12.sp,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '매출',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    revenue,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '이용객',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    visitors,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
