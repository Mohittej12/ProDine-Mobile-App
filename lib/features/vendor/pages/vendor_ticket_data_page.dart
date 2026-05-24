import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pro_dine/features/vendor/widgets/vendor_page_header.dart';
import 'package:pro_dine/features/vendor/widgets/vendor_shell.dart';

class VendorTicketDataPage extends StatefulWidget {
  const VendorTicketDataPage({super.key});

  @override
  State<VendorTicketDataPage> createState() => _VendorTicketDataPageState();
}

class _VendorTicketDataPageState extends State<VendorTicketDataPage> {
  static const Color _primaryRed = Color(0xFFFF1F1F);
  static const Color _darkText = Color(0xFF141827);
  static const Color _mutedText = Color(0xFF667085);
  static const Color _screenBg = Color(0xFFFFFCF8);
  static const Color _softBorder = Color(0xFFF0F0F0);
  static const Color _green = Color(0xFF22C55E);
  static const Color _orange = Color(0xFFFF6A00);

  DateTime _selectedDate = DateTime(2024, 1, 15);

  final List<_TicketReport> _reports = [
    _TicketReport(
      id: 'TKT-2024-0115',
      date: DateTime(2024, 1, 15),
      uploadedAt: '09:23 AM',
      rows: 142,
      fileName: 'ticket_data_2024_01_15.xlsx',
      status: _ReportStatus.ready,
    ),
    _TicketReport(
      id: 'TKT-2024-0114',
      date: DateTime(2024, 1, 14),
      uploadedAt: '10:15 AM',
      rows: 118,
      fileName: 'ticket_data_2024_01_14.xlsx',
      status: _ReportStatus.ready,
    ),
    _TicketReport(
      id: 'TKT-2024-0113',
      date: DateTime(2024, 1, 13),
      uploadedAt: '08:47 AM',
      rows: 96,
      fileName: 'ticket_data_2024_01_13.xlsx',
      status: _ReportStatus.ready,
    ),
    _TicketReport(
      id: 'TKT-2024-0112',
      date: DateTime(2024, 1, 12),
      uploadedAt: '11:32 AM',
      rows: 156,
      fileName: 'ticket_data_2024_01_12.xlsx',
      status: _ReportStatus.ready,
    ),
    _TicketReport(
      id: 'TKT-2024-0111',
      date: DateTime(2024, 1, 11),
      uploadedAt: '09:58 AM',
      rows: 104,
      fileName: 'ticket_data_2024_01_11.xlsx',
      status: _ReportStatus.ready,
    ),
    _TicketReport(
      id: 'TKT-2024-0110',
      date: DateTime(2024, 1, 10),
      uploadedAt: '10:41 AM',
      rows: 89,
      fileName: 'ticket_data_2024_01_10.xlsx',
      status: _ReportStatus.ready,
    ),
    _TicketReport(
      id: 'TKT-2024-0109',
      date: DateTime(2024, 1, 9),
      uploadedAt: '08:22 AM',
      rows: 132,
      fileName: 'ticket_data_2024_01_09.xlsx',
      status: _ReportStatus.ready,
    ),
  ];

  List<_TicketReport> get _visibleReports {
    final selected = _dateOnly(_selectedDate);

    final exactDateReports = _reports.where((report) {
      return _dateOnly(report.date) == selected;
    }).toList();

    if (exactDateReports.isNotEmpty) return exactDateReports;
    return _reports;
  }

  int get _totalRows {
    return _reports.fold<int>(0, (sum, report) => sum + report.rows);
  }

  int get _readyReports {
    return _reports
        .where((report) => report.status == _ReportStatus.ready)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _screenBg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = _TicketLayout.fromWidth(constraints.maxWidth);
          final bottomSafe = MediaQuery.of(context).padding.bottom;

          return Column(
            children: [
              VendorPageHeader(
                title: 'Ticket Data View',
                maxContentWidth: layout.maxContentWidth,
                horizontalPadding: layout.horizontalPadding,
                isDesktop: layout.isDesktop,
                scale: layout.scale,
                onMenuTap: _openMenu,
              ),
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        layout.horizontalPadding,
                        layout.topPadding,
                        layout.horizontalPadding,
                        layout.bottomPadding + bottomSafe,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: layout.maxContentWidth,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _HeroIntroCard(
                                  layout: layout,
                                  selectedDate: _selectedDate,
                                  reportCount: _reports.length,
                                  totalRows: _totalRows,
                                  readyReports: _readyReports,
                                  onDateTap: _pickDate,
                                ),
                                SizedBox(height: layout.sectionGap),
                                _SectionHeader(
                                  layout: layout,
                                  title: 'Uploaded Reports',
                                  subtitle:
                                      '${_visibleReports.length} report${_visibleReports.length == 1 ? '' : 's'} available',
                                ),
                                SizedBox(height: layout.cardGap),
                                _ReportsGrid(
                                  layout: layout,
                                  reports: _visibleReports,
                                  onExport: _exportReport,
                                  onPreview: _previewReport,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openMenu() {
    if (VendorShell.openDrawer(context)) {
      return;
    }

    _showSnack('Vendor menu');
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime(2026, 12, 31),
      helpText: 'Select ticket upload date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryRed,
              onPrimary: Colors.white,
              onSurface: _darkText,
            ),
            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked == null) return;

    setState(() => _selectedDate = picked);
  }

  void _exportReport(_TicketReport report) {
    _showSnack('Exporting ${report.fileName}');
  }

  void _previewReport(_TicketReport report) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportPreviewSheet(report: report),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _darkText,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 90),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      );
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

class _TicketLayout {
  const _TicketLayout({
    required this.isDesktop,
    required this.isTablet,
    required this.maxContentWidth,
    required this.horizontalPadding,
    required this.topPadding,
    required this.bottomPadding,
    required this.scale,
    required this.sectionGap,
    required this.cardGap,
    required this.gridGap,
    required this.reportColumns,
    required this.statColumns,
  });

  final bool isDesktop;
  final bool isTablet;
  final double maxContentWidth;
  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;
  final double scale;
  final double sectionGap;
  final double cardGap;
  final double gridGap;
  final int reportColumns;
  final int statColumns;

  static _TicketLayout fromWidth(double width) {
    if (width >= 1180) {
      return const _TicketLayout(
        isDesktop: true,
        isTablet: false,
        maxContentWidth: 1180,
        horizontalPadding: 48,
        topPadding: 30,
        bottomPadding: 56,
        scale: 1.08,
        sectionGap: 30,
        cardGap: 18,
        gridGap: 22,
        reportColumns: 2,
        statColumns: 3,
      );
    }

    if (width >= 760) {
      return const _TicketLayout(
        isDesktop: false,
        isTablet: true,
        maxContentWidth: 760,
        horizontalPadding: 36,
        topPadding: 28,
        bottomPadding: 56,
        scale: 1.02,
        sectionGap: 28,
        cardGap: 18,
        gridGap: 20,
        reportColumns: 2,
        statColumns: 3,
      );
    }

    return _TicketLayout(
      isDesktop: false,
      isTablet: false,
      maxContentWidth: 430,
      horizontalPadding: width < 370 ? 14 : 16,
      topPadding: 18,
      bottomPadding: 132,
      scale: width < 370 ? 0.92 : 1,
      sectionGap: 24,
      cardGap: 16,
      gridGap: width < 370 ? 12 : 14,
      reportColumns: 1,
      statColumns: 3,
    );
  }
}

class _HeroIntroCard extends StatelessWidget {
  const _HeroIntroCard({
    required this.layout,
    required this.selectedDate,
    required this.reportCount,
    required this.totalRows,
    required this.readyReports,
    required this.onDateTap,
  });

  final _TicketLayout layout;
  final DateTime selectedDate;
  final int reportCount;
  final int totalRows;
  final int readyReports;
  final VoidCallback onDateTap;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(layout.isDesktop ? 26 : 20 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28 * scale),
        border: Border.all(color: _VendorTicketDataPageState._softBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: layout.isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 9,
                  child: _IntroCopy(scale: scale, layout: layout),
                ),
                SizedBox(width: layout.gridGap),
                Expanded(
                  flex: 10,
                  child: _DateAndStats(
                    layout: layout,
                    selectedDate: selectedDate,
                    reportCount: reportCount,
                    totalRows: totalRows,
                    readyReports: readyReports,
                    onDateTap: onDateTap,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IntroCopy(scale: scale, layout: layout),
                SizedBox(height: 18 * scale),
                _DateAndStats(
                  layout: layout,
                  selectedDate: selectedDate,
                  reportCount: reportCount,
                  totalRows: totalRows,
                  readyReports: readyReports,
                  onDateTap: onDateTap,
                ),
              ],
            ),
    );
  }
}

class _IntroCopy extends StatelessWidget {
  const _IntroCopy({required this.scale, required this.layout});

  final double scale;
  final _TicketLayout layout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Uploaded Ticket Data',
          style: TextStyle(
            color: _VendorTicketDataPageState._darkText,
            fontSize: layout.isDesktop ? 30 : 23 * scale,
            height: 1.1,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
          ),
        ),
        SizedBox(height: 8 * scale),
        Text(
          'View, validate, and export ticket data uploaded by admin for daily meal-pass reconciliation.',
          style: TextStyle(
            color: _VendorTicketDataPageState._mutedText,
            fontSize: layout.isDesktop ? 14 : 13 * scale,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DateAndStats extends StatelessWidget {
  const _DateAndStats({
    required this.layout,
    required this.selectedDate,
    required this.reportCount,
    required this.totalRows,
    required this.readyReports,
    required this.onDateTap,
  });

  final _TicketLayout layout;
  final DateTime selectedDate;
  final int reportCount;
  final int totalRows;
  final int readyReports;
  final VoidCallback onDateTap;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date',
          style: TextStyle(
            color: _VendorTicketDataPageState._darkText,
            fontSize: 13 * scale,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 10 * scale),
        Material(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(18 * scale),
          child: InkWell(
            onTap: onDateTap,
            borderRadius: BorderRadius.circular(18 * scale),
            child: Container(
              height: layout.isDesktop ? 58 : 54 * scale,
              padding: EdgeInsets.symmetric(horizontal: 15 * scale),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18 * scale),
                border: Border.all(color: const Color(0xFFE7E9EE)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: _VendorTicketDataPageState._primaryRed,
                    size: 19 * scale,
                  ),
                  SizedBox(width: 11 * scale),
                  Expanded(
                    child: Text(
                      _formatIsoDate(selectedDate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _VendorTicketDataPageState._darkText,
                        fontSize: layout.isDesktop ? 15.5 : 14.5 * scale,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _VendorTicketDataPageState._mutedText,
                    size: 24 * scale,
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 14 * scale),
        _StatsGrid(
          layout: layout,
          reportCount: reportCount,
          totalRows: totalRows,
          readyReports: readyReports,
        ),
      ],
    );
  }

  String _formatIsoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.layout,
    required this.reportCount,
    required this.totalRows,
    required this.readyReports,
  });

  final _TicketLayout layout;
  final int reportCount;
  final int totalRows;
  final int readyReports;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _TicketStat(
        label: 'Reports',
        value: '$reportCount',
        icon: Icons.description_rounded,
        color: _VendorTicketDataPageState._primaryRed,
        bgColor: const Color(0xFFFFEFEF),
      ),
      _TicketStat(
        label: 'Rows',
        value: '$totalRows',
        icon: Icons.table_rows_rounded,
        color: _VendorTicketDataPageState._orange,
        bgColor: const Color(0xFFFFF3E8),
      ),
      _TicketStat(
        label: 'Ready',
        value: '$readyReports',
        icon: Icons.check_circle_rounded,
        color: _VendorTicketDataPageState._green,
        bgColor: const Color(0xFFEFFFF4),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = math.min(layout.statColumns, stats.length);
        final gap = layout.gridGap;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: stats.map((stat) {
            return SizedBox(
              width: width,
              child: _StatCard(layout: layout, stat: stat),
            );
          }).toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.layout, required this.stat});

  final _TicketLayout layout;
  final _TicketStat stat;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Container(
      padding: EdgeInsets.all(layout.isDesktop ? 15 : 11 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(17 * scale),
        border: Border.all(color: const Color(0xFFF1F2F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: layout.isDesktop ? 36 : 31 * scale,
            height: layout.isDesktop ? 36 : 31 * scale,
            decoration: BoxDecoration(
              color: stat.bgColor,
              borderRadius: BorderRadius.circular(11 * scale),
            ),
            child: Icon(stat.icon, color: stat.color, size: 18 * scale),
          ),
          SizedBox(height: 11 * scale),
          Text(
            stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _VendorTicketDataPageState._darkText,
              fontSize: layout.isDesktop ? 20 : 17 * scale,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 5 * scale),
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _VendorTicketDataPageState._mutedText,
              fontSize: layout.isDesktop ? 12 : 10.5 * scale,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.layout,
    required this.title,
    required this.subtitle,
  });

  final _TicketLayout layout;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: _VendorTicketDataPageState._darkText,
                  fontSize: layout.isDesktop ? 28 : 22 * scale,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              SizedBox(height: 7 * scale),
              Text(
                subtitle,
                style: TextStyle(
                  color: _VendorTicketDataPageState._mutedText,
                  fontSize: 12.5 * scale,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportsGrid extends StatelessWidget {
  const _ReportsGrid({
    required this.layout,
    required this.reports,
    required this.onExport,
    required this.onPreview,
  });

  final _TicketLayout layout;
  final List<_TicketReport> reports;
  final ValueChanged<_TicketReport> onExport;
  final ValueChanged<_TicketReport> onPreview;

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const _EmptyReportsState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = math.min(layout.reportColumns, reports.length);
        final gap = layout.gridGap;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: reports.map((report) {
            return SizedBox(
              width: width,
              child: _ReportCard(
                layout: layout,
                report: report,
                onExport: () => onExport(report),
                onPreview: () => onPreview(report),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.layout,
    required this.report,
    required this.onExport,
    required this.onPreview,
  });

  final _TicketLayout layout;
  final _TicketReport report;
  final VoidCallback onExport;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Container(
      padding: EdgeInsets.all(layout.isDesktop ? 18 : 16 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24 * scale),
        border: Border.all(color: _VendorTicketDataPageState._softBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48 * scale,
                height: 48 * scale,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFEF),
                  borderRadius: BorderRadius.circular(15 * scale),
                ),
                child: Icon(
                  Icons.insert_drive_file_rounded,
                  color: _VendorTicketDataPageState._primaryRed,
                  size: 24 * scale,
                ),
              ),
              SizedBox(width: 13 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatLongDate(report.date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _VendorTicketDataPageState._darkText,
                        fontSize: layout.isDesktop ? 17 : 15.5 * scale,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.25,
                      ),
                    ),
                    SizedBox(height: 7 * scale),
                    Text(
                      'Uploaded at ${report.uploadedAt}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _VendorTicketDataPageState._mutedText,
                        fontSize: 12 * scale,
                        height: 1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _ReadyBadge(scale: scale),
            ],
          ),
          SizedBox(height: 15 * scale),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(13 * scale),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(17 * scale),
              border: Border.all(color: const Color(0xFFF1F2F4)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ReportMeta(
                    label: 'Rows',
                    value: '${report.rows}',
                    scale: scale,
                  ),
                ),
                Container(
                  width: 1,
                  height: 30 * scale,
                  color: const Color(0xFFEDEDED),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.only(left: 12 * scale),
                    child: _ReportMeta(
                      label: 'File',
                      value: report.fileName,
                      scale: scale,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 15 * scale),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPreview,
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text('Preview'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.fromHeight(
                      layout.isDesktop ? 48 : 46 * scale,
                    ),
                    foregroundColor: _VendorTicketDataPageState._darkText,
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15 * scale),
                    ),
                    textStyle: TextStyle(
                      fontSize: 13 * scale,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10 * scale),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onExport,
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: const Text('Export'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.fromHeight(
                      layout.isDesktop ? 48 : 46 * scale,
                    ),
                    backgroundColor: _VendorTicketDataPageState._primaryRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15 * scale),
                    ),
                    textStyle: TextStyle(
                      fontSize: 13 * scale,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatLongDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _ReadyBadge extends StatelessWidget {
  const _ReadyBadge({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale,
        vertical: 6 * scale,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFFF4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Ready',
        style: TextStyle(
          color: _VendorTicketDataPageState._green,
          fontSize: 11 * scale,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ReportMeta extends StatelessWidget {
  const _ReportMeta({
    required this.label,
    required this.value,
    required this.scale,
  });

  final String label;
  final String value;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _VendorTicketDataPageState._mutedText,
            fontSize: 10.5 * scale,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 6 * scale),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _VendorTicketDataPageState._darkText,
            fontSize: 12.5 * scale,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ReportPreviewSheet extends StatelessWidget {
  const _ReportPreviewSheet({required this.report});

  final _TicketReport report;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          22,
          16,
          22,
          22 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 22),
              const Icon(
                Icons.insert_drive_file_rounded,
                color: _VendorTicketDataPageState._primaryRed,
                size: 38,
              ),
              const SizedBox(height: 12),
              Text(
                report.fileName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _VendorTicketDataPageState._darkText,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${report.rows} ticket rows • Uploaded at ${report.uploadedAt}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _VendorTicketDataPageState._mutedText,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _VendorTicketDataPageState._primaryRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyReportsState extends StatelessWidget {
  const _EmptyReportsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 42),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _VendorTicketDataPageState._softBorder),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            color: _VendorTicketDataPageState._primaryRed,
            size: 38,
          ),
          SizedBox(height: 12),
          Text(
            'No reports found',
            style: TextStyle(
              color: _VendorTicketDataPageState._darkText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try selecting a different upload date.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _VendorTicketDataPageState._mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketStat {
  const _TicketStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
}

enum _ReportStatus { ready }

class _TicketReport {
  const _TicketReport({
    required this.id,
    required this.date,
    required this.uploadedAt,
    required this.rows,
    required this.fileName,
    required this.status,
  });

  final String id;
  final DateTime date;
  final String uploadedAt;
  final int rows;
  final String fileName;
  final _ReportStatus status;
}
