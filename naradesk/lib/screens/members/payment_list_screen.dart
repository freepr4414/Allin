import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/payment_model.dart';
import '../../providers/payment_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/responsive.dart';
import '../../utils/responsive_font.dart';

class PaymentListScreen extends ConsumerStatefulWidget {
  const PaymentListScreen({super.key});

  @override
  ConsumerState<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends ConsumerState<PaymentListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  PaymentMethod? _selectedMethod;
  PaymentStatus? _selectedStatus;
  PaymentType? _selectedType;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payments = ref.watch(paymentProvider);
    final filteredPayments = _filterPayments(payments);
    final currencyFormatter = NumberFormat('#,###', 'ko_KR');
    final currentThemeMode = ref.watch(currentThemeModeProvider);
    final isDarkMode = currentThemeMode == AppThemeMode.dark;

    return Container(
      padding: EdgeInsets.all(Responsive.getResponsivePadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 페이지 헤더
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.getResponsivePadding(context),
              vertical: Responsive.getResponsiveMargin(context),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.payment,
                  color: Theme.of(context).colorScheme.primary,
                  size: Responsive.getResponsiveValue(
                    context,
                    mobile: 20,
                    tablet: 24,
                    desktop: 28,
                  ),
                ),
                SizedBox(width: Responsive.getResponsiveMargin(context)),
                Text(
                  '결제 내역',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: Responsive.getResponsiveFontSize(
                      context,
                      baseFontSize: 20,
                    ),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '총 ${payments.length}건',
                      style: TextStyle(
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.7)
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: Responsive.getResponsiveFontSize(
                          context,
                          baseFontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      '${currencyFormatter.format(_getTotalAmount(filteredPayments))}원',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: Responsive.getResponsiveFontSize(
                          context,
                          baseFontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: Responsive.getResponsivePadding(context)),

          // 검색 및 필터 섹션
          _buildSearchAndFilters(context, isDarkMode),

          SizedBox(height: Responsive.getResponsivePadding(context)),

          // 결제 테이블
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Responsive.isMobile(context)
                  ? _buildMobileList(
                      filteredPayments,
                      currencyFormatter,
                      isDarkMode,
                    )
                  : _buildDataTable(
                      filteredPayments,
                      currencyFormatter,
                      isDarkMode,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsivePadding(context)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // 검색 필드
          TextField(
            controller: _searchController,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: '회원명, 결제 ID로 검색...',
              hintStyle: TextStyle(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.black54,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.black54,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),

          if (!Responsive.isMobile(context)) ...[
            SizedBox(height: Responsive.getResponsiveMargin(context)),
            // 필터 드롭다운들
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<PaymentMethod?>(
                    value: _selectedMethod,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                    decoration: InputDecoration(
                      labelText: '결제방법',
                      labelStyle: TextStyle(
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.black54,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: [
                      DropdownMenuItem<PaymentMethod?>(
                        value: null,
                        child: Text(
                          '전체',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      ...PaymentMethod.values.map(
                        (method) => DropdownMenuItem(
                          value: method,
                          child: Text(
                            method.displayName,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedMethod = value;
                      });
                    },
                  ),
                ),
                SizedBox(width: Responsive.getResponsiveMargin(context)),
                Expanded(
                  child: DropdownButtonFormField<PaymentType?>(
                    value: _selectedType,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                    decoration: InputDecoration(
                      labelText: '결제유형',
                      labelStyle: TextStyle(
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.black54,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: [
                      DropdownMenuItem<PaymentType?>(
                        value: null,
                        child: Text(
                          '전체',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      ...PaymentType.values.map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                            type.displayName,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value;
                      });
                    },
                  ),
                ),
                SizedBox(width: Responsive.getResponsiveMargin(context)),
                Expanded(
                  child: DropdownButtonFormField<PaymentStatus?>(
                    value: _selectedStatus,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                    decoration: InputDecoration(
                      labelText: '상태',
                      labelStyle: TextStyle(
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.black54,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: [
                      DropdownMenuItem<PaymentStatus?>(
                        value: null,
                        child: Text(
                          '전체',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      ...PaymentStatus.values.map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(
                            status.displayName,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataTable(
    List<Payment> payments,
    NumberFormat currencyFormatter,
    bool isDarkMode,
  ) {
    final headingFontSize = ref.getResponsiveFontSize(
      context,
      baseFontSize: 14,
    );
    final dataFontSize = ref.getResponsiveFontSize(context, baseFontSize: 13);

    return Theme(
      data: Theme.of(context).copyWith(
        dataTableTheme: DataTableThemeData(
          dataTextStyle: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: dataFontSize,
          ),
          headingTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: headingFontSize,
          ),
        ),
      ),
      child: DataTable2(
        columnSpacing: 12,
        horizontalMargin: 12,
        minWidth: 1000,
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black87,
          fontSize: headingFontSize,
        ),
        dataTextStyle: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontSize: dataFontSize,
        ),
        columns: [
          DataColumn2(label: Text('결제 ID'), size: ColumnSize.S),
          DataColumn2(label: Text('회원명'), size: ColumnSize.M),
          DataColumn2(label: Text('금액'), size: ColumnSize.S),
          DataColumn2(label: Text('결제방법'), size: ColumnSize.S),
          DataColumn2(label: Text('유형'), size: ColumnSize.S),
          DataColumn2(label: Text('상태'), size: ColumnSize.S),
          DataColumn2(label: Text('결제일'), size: ColumnSize.M),
          DataColumn2(label: Text('설명'), size: ColumnSize.L),
        ],
        rows: payments.map((payment) {
          final dataFontSize = ref.getResponsiveFontSize(
            context,
            baseFontSize: 13,
          );

          return DataRow2(
            cells: [
              DataCell(
                Text(
                  payment.id,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: dataFontSize,
                  ),
                ),
              ),
              DataCell(
                Text(
                  payment.memberName,
                  style: TextStyle(fontSize: dataFontSize),
                ),
              ),
              DataCell(
                Text(
                  '${currencyFormatter.format(payment.amount)}원',
                  style: TextStyle(fontSize: dataFontSize),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getMethodColor(
                      payment.method,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getMethodColor(
                        payment.method,
                      ).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    payment.method.displayName,
                    style: TextStyle(
                      color: _getMethodColor(payment.method),
                      fontWeight: FontWeight.w500,
                      fontSize: dataFontSize,
                    ),
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getTypeColor(payment.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getTypeColor(payment.type).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    payment.type.displayName,
                    style: TextStyle(
                      color: _getTypeColor(payment.type),
                      fontWeight: FontWeight.w500,
                      fontSize: dataFontSize,
                    ),
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      payment.status,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(
                        payment.status,
                      ).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    payment.status.displayName,
                    style: TextStyle(
                      color: _getStatusColor(payment.status),
                      fontWeight: FontWeight.w500,
                      fontSize: dataFontSize,
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(
                  DateFormat('yyyy.MM.dd HH:mm').format(payment.paymentDate),
                  style: TextStyle(fontSize: dataFontSize),
                ),
              ),
              DataCell(
                Text(
                  payment.description ?? '',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: dataFontSize,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileList(
    List<Payment> payments,
    NumberFormat currencyFormatter,
    bool isDarkMode,
  ) {
    return ListView.builder(
      padding: EdgeInsets.all(Responsive.getResponsivePadding(context)),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        return Card(
          margin: EdgeInsets.only(
            bottom: Responsive.getResponsiveMargin(context),
          ),
          child: Padding(
            padding: EdgeInsets.all(Responsive.getResponsivePadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        payment.memberName,
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveFontSize(
                            context,
                            baseFontSize: 16,
                          ),
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          payment.status,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(
                            payment.status,
                          ).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        payment.status.displayName,
                        style: TextStyle(
                          color: _getStatusColor(payment.status),
                          fontWeight: FontWeight.w500,
                          fontSize: Responsive.getResponsiveFontSize(
                            context,
                            baseFontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.getResponsiveMargin(context) / 2),
                Text(
                  '${currencyFormatter.format(payment.amount)}원',
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveFontSize(
                      context,
                      baseFontSize: 18,
                    ),
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(height: Responsive.getResponsiveMargin(context) / 4),
                if (payment.description != null) ...[
                  Text(
                    payment.description!,
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveFontSize(
                        context,
                        baseFontSize: 14,
                      ),
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.7)
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  SizedBox(height: Responsive.getResponsiveMargin(context) / 4),
                ],
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getMethodColor(
                          payment.method,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getMethodColor(
                            payment.method,
                          ).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        payment.method.displayName,
                        style: TextStyle(
                          color: _getMethodColor(payment.method),
                          fontWeight: FontWeight.w500,
                          fontSize: Responsive.getResponsiveFontSize(
                            context,
                            baseFontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: Responsive.getResponsiveMargin(context) / 2,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getTypeColor(
                          payment.type,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getTypeColor(
                            payment.type,
                          ).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        payment.type.displayName,
                        style: TextStyle(
                          color: _getTypeColor(payment.type),
                          fontWeight: FontWeight.w500,
                          fontSize: Responsive.getResponsiveFontSize(
                            context,
                            baseFontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('MM.dd HH:mm').format(payment.paymentDate),
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveFontSize(
                          context,
                          baseFontSize: 12,
                        ),
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.6)
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Payment> _filterPayments(List<Payment> payments) {
    var filtered = payments;

    // 검색어 필터
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (payment) =>
                payment.memberName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                payment.id.contains(_searchQuery) ||
                (payment.description?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();
    }

    // 결제방법 필터
    if (_selectedMethod != null) {
      filtered = filtered
          .where((payment) => payment.method == _selectedMethod)
          .toList();
    }

    // 결제유형 필터
    if (_selectedType != null) {
      filtered = filtered
          .where((payment) => payment.type == _selectedType)
          .toList();
    }

    // 상태 필터
    if (_selectedStatus != null) {
      filtered = filtered
          .where((payment) => payment.status == _selectedStatus)
          .toList();
    }

    return filtered;
  }

  double _getTotalAmount(List<Payment> payments) {
    return payments
        .where((payment) => payment.status == PaymentStatus.completed)
        .fold(0.0, (sum, payment) => sum + payment.amount);
  }

  Color _getMethodColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Colors.green;
      case PaymentMethod.card:
        return Colors.blue;
      case PaymentMethod.transfer:
        return Colors.orange;
      case PaymentMethod.mobile:
        return Colors.purple;
    }
  }

  Color _getTypeColor(PaymentType type) {
    switch (type) {
      case PaymentType.timePass:
        return Colors.blue;
      case PaymentType.monthlyPass:
        return Colors.green;
      case PaymentType.deposit:
        return Colors.orange;
      case PaymentType.refund:
        return Colors.red;
    }
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.cancelled:
        return Colors.grey;
      case PaymentStatus.failed:
        return Colors.red;
    }
  }
}
