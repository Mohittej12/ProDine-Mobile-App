import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pro_dine/features/admin/widgets/admin_shell.dart';

class AdminUploadTicketDataPage extends StatefulWidget {
  const AdminUploadTicketDataPage({super.key});

  @override
  State<AdminUploadTicketDataPage> createState() =>
      _AdminUploadTicketDataPageState();
}

class _AdminUploadTicketDataPageState extends State<AdminUploadTicketDataPage> {
  static const Color _primaryRed = Color(0xFFFF1F1F);
  static const Color _deepRed = Color(0xFFC91818);
  static const Color _darkText = Color(0xFF141827);
  static const Color _mutedText = Color(0xFF667085);
  static const Color _screenBg = Color(0xFFFFFCF8);
  static const Color _softBorder = Color(0xFFE9EDF3);
  static const Color _fieldBg = Color(0xFFF8F9FB);
  static const Color _green = Color(0xFF16A34A);
  static const Color _orange = Color(0xFFFF6A00);

  bool _fileSelected = false;
  bool _uploading = false;
  String? _selectedFileName;

  final List<_UploadRecord> _recentUploads = const [
    _UploadRecord(
      fileName: 'tickets_january_2024.xlsx',
      status: _UploadStatus.success,
      recordsLabel: '1,245 records',
      uploadedAgo: '2 hours ago',
      fileType: 'XLSX',
    ),
    _UploadRecord(
      fileName: 'support_tickets_dec.csv',
      status: _UploadStatus.success,
      recordsLabel: '892 records',
      uploadedAgo: '1 day ago',
      fileType: 'CSV',
    ),
    _UploadRecord(
      fileName: 'ticket_data_invalid.xlsx',
      status: _UploadStatus.failed,
      recordsLabel: 'Invalid format',
      uploadedAgo: '3 days ago',
      fileType: 'XLSX',
    ),
  ];

  bool get _canStartUpload => _fileSelected && !_uploading;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _screenBg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = _UploadLayout.fromWidth(constraints.maxWidth);
          final bottomSafe = MediaQuery.of(context).padding.bottom;

          return SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: layout.maxContentWidth),
                child: Column(
                  children: [
                    _Header(layout: layout, onMenuTap: _openMenu),
                    Expanded(
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              layout.horizontalPadding,
                              layout.contentTopPadding,
                              layout.horizontalPadding,
                              24 + bottomSafe,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: layout.isDesktop
                                  ? Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 9,
                                          child: Column(
                                            children: [
                                              _UploadBox(
                                                layout: layout,
                                                selectedFileName:
                                                    _selectedFileName,
                                                fileSelected: _fileSelected,
                                                onBrowse: _browseFile,
                                              ),
                                              SizedBox(
                                                height: layout.sectionGap,
                                              ),
                                              _RequirementsCard(layout: layout),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: layout.gridGap),
                                        Expanded(
                                          flex: 11,
                                          child: Column(
                                            children: [
                                              _RecentUploadsSection(
                                                layout: layout,
                                                uploads: _recentUploads,
                                                onViewAll: _viewAllUploads,
                                                onRecordAction:
                                                    _showUploadOptions,
                                              ),
                                              SizedBox(
                                                height: layout.sectionGap,
                                              ),
                                              _SummaryGrid(layout: layout),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _UploadBox(
                                          layout: layout,
                                          selectedFileName: _selectedFileName,
                                          fileSelected: _fileSelected,
                                          onBrowse: _browseFile,
                                        ),
                                        SizedBox(height: layout.sectionGap),
                                        _RequirementsCard(layout: layout),
                                        SizedBox(height: layout.sectionGap),
                                        _RecentUploadsSection(
                                          layout: layout,
                                          uploads: _recentUploads,
                                          onViewAll: _viewAllUploads,
                                          onRecordAction: _showUploadOptions,
                                        ),
                                        SizedBox(height: layout.sectionGap),
                                        _SummaryGrid(layout: layout),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _BottomUploadBar(
                      layout: layout,
                      bottomSafe: bottomSafe,
                      enabled: _canStartUpload,
                      uploading: _uploading,
                      onStart: _startUpload,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openMenu() {
    if (AdminShell.openDrawer(context)) {
      return;
    }

    _showSnack('Admin menu');
  }

  void _browseFile() {
    HapticFeedback.selectionClick();

    setState(() {
      _fileSelected = true;
      _selectedFileName = 'employee_ticket_data_january.xlsx';
    });

    _showSnack('Excel file selected');
  }

  Future<void> _startUpload() async {
    if (!_canStartUpload) {
      _showSnack('Please select an Excel or CSV file first');
      return;
    }

    setState(() => _uploading = true);

    await Future<void>.delayed(const Duration(milliseconds: 850));

    if (!mounted) return;

    setState(() {
      _uploading = false;
      _fileSelected = false;
      _selectedFileName = null;
    });

    _showSnack('Ticket data upload started successfully');
  }

  void _viewAllUploads() {
    _showSnack('Showing all recent uploads');
  }

  void _showUploadOptions(_UploadRecord record) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UploadOptionsSheet(record: record),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _darkText,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 92),
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
}

class _UploadLayout {
  const _UploadLayout({
    required this.isDesktop,
    required this.isTablet,
    required this.maxContentWidth,
    required this.horizontalPadding,
    required this.headerPadding,
    required this.contentTopPadding,
    required this.bottomBarPadding,
    required this.scale,
    required this.sectionGap,
    required this.cardGap,
    required this.gridGap,
  });

  final bool isDesktop;
  final bool isTablet;
  final double maxContentWidth;
  final double horizontalPadding;
  final double headerPadding;
  final double contentTopPadding;
  final double bottomBarPadding;
  final double scale;
  final double sectionGap;
  final double cardGap;
  final double gridGap;

  static _UploadLayout fromWidth(double width) {
    if (width >= 1180) {
      return const _UploadLayout(
        isDesktop: true,
        isTablet: false,
        maxContentWidth: 1180,
        horizontalPadding: 48,
        headerPadding: 36,
        contentTopPadding: 30,
        bottomBarPadding: 48,
        scale: 1.06,
        sectionGap: 26,
        cardGap: 16,
        gridGap: 26,
      );
    }

    if (width >= 760) {
      return const _UploadLayout(
        isDesktop: false,
        isTablet: true,
        maxContentWidth: 760,
        horizontalPadding: 36,
        headerPadding: 30,
        contentTopPadding: 26,
        bottomBarPadding: 36,
        scale: 1,
        sectionGap: 24,
        cardGap: 16,
        gridGap: 20,
      );
    }

    return _UploadLayout(
      isDesktop: false,
      isTablet: false,
      maxContentWidth: 430,
      horizontalPadding: width < 370 ? 16 : 22,
      headerPadding: width < 370 ? 18 : 22,
      contentTopPadding: 20,
      bottomBarPadding: width < 370 ? 16 : 22,
      scale: width < 370 ? 0.92 : 1,
      sectionGap: 22,
      cardGap: 14,
      gridGap: 14,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.layout, required this.onMenuTap});

  final _UploadLayout layout;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Container(
      padding: EdgeInsets.fromLTRB(
        layout.headerPadding,
        18 + MediaQuery.of(context).padding.top,
        layout.headerPadding,
        18,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: const Color(0xFFFFEFEF),
            borderRadius: BorderRadius.circular(16 * scale),
            child: InkWell(
              onTap: onMenuTap,
              borderRadius: BorderRadius.circular(16 * scale),
              child: SizedBox(
                width: layout.isDesktop ? 50 : 46 * scale,
                height: layout.isDesktop ? 50 : 46 * scale,
                child: Icon(
                  Icons.menu_rounded,
                  color: _AdminUploadTicketDataPageState._primaryRed,
                  size: 28 * scale,
                ),
              ),
            ),
          ),
          SizedBox(width: 14 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload Ticket Data',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _AdminUploadTicketDataPageState._darkText,
                    fontSize: layout.isDesktop ? 31 : 24 * scale,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
                SizedBox(height: 7 * scale),
                Text(
                  'Import your raised ticket IDs from Excel files',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _AdminUploadTicketDataPageState._mutedText,
                    fontSize: layout.isDesktop ? 14 : 12.5 * scale,
                    height: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadBox extends StatelessWidget {
  const _UploadBox({
    required this.layout,
    required this.selectedFileName,
    required this.fileSelected,
    required this.onBrowse,
  });

  final _UploadLayout layout;
  final String? selectedFileName;
  final bool fileSelected;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(layout.isDesktop ? 24 : 18 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28 * scale),
        border: Border.all(color: _AdminUploadTicketDataPageState._softBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: fileSelected
              ? _AdminUploadTicketDataPageState._primaryRed.withOpacity(0.45)
              : const Color(0xFFD6DCE5),
          radius: 24 * scale,
        ),
        child: Material(
          color: fileSelected
              ? const Color(0xFFFFF4F4)
              : const Color(0xFFFAFBFC),
          borderRadius: BorderRadius.circular(24 * scale),
          child: InkWell(
            onTap: onBrowse,
            borderRadius: BorderRadius.circular(24 * scale),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 18 * scale,
                vertical: layout.isDesktop ? 42 : 34 * scale,
              ),
              child: Column(
                children: [
                  Container(
                    width: layout.isDesktop ? 76 : 68 * scale,
                    height: layout.isDesktop ? 76 : 68 * scale,
                    decoration: BoxDecoration(
                      color: fileSelected
                          ? _AdminUploadTicketDataPageState._primaryRed
                          : const Color(0xFFFFEFEF),
                      borderRadius: BorderRadius.circular(22 * scale),
                      boxShadow: fileSelected
                          ? [
                              BoxShadow(
                                color: _AdminUploadTicketDataPageState
                                    ._primaryRed
                                    .withOpacity(0.22),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      fileSelected
                          ? Icons.check_rounded
                          : Icons.upload_file_rounded,
                      color: fileSelected
                          ? Colors.white
                          : _AdminUploadTicketDataPageState._primaryRed,
                      size: 34 * scale,
                    ),
                  ),
                  SizedBox(height: 18 * scale),
                  Text(
                    fileSelected ? 'File Ready to Upload' : 'Upload Excel File',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _AdminUploadTicketDataPageState._darkText,
                      fontSize: layout.isDesktop ? 22 : 18 * scale,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.35,
                    ),
                  ),
                  SizedBox(height: 9 * scale),
                  Text(
                    fileSelected
                        ? selectedFileName ?? 'Selected file'
                        : 'Drag & drop or tap to browse',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fileSelected
                          ? _AdminUploadTicketDataPageState._primaryRed
                          : _AdminUploadTicketDataPageState._mutedText,
                      fontSize: 13 * scale,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 18 * scale),
                  SizedBox(
                    height: layout.isDesktop ? 48 : 46 * scale,
                    child: ElevatedButton.icon(
                      onPressed: onBrowse,
                      icon: Icon(
                        fileSelected
                            ? Icons.swap_horiz_rounded
                            : Icons.folder_open_rounded,
                        size: 18 * scale,
                      ),
                      label: Text(
                        fileSelected ? 'Change File' : 'Browse Files',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _AdminUploadTicketDataPageState._primaryRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 20 * scale),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15 * scale),
                        ),
                        textStyle: TextStyle(
                          fontSize: 13.5 * scale,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 14 * scale),
                  Text(
                    'Supported: .xlsx, .xls, .csv • Max 10MB',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF98A2B3),
                      fontSize: 11.5 * scale,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RequirementsCard extends StatelessWidget {
  const _RequirementsCard({required this.layout});

  final _UploadLayout layout;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(layout.isDesktop ? 22 : 18 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24 * scale),
        border: Border.all(color: _AdminUploadTicketDataPageState._softBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitleRow(
            icon: Icons.info_rounded,
            iconColor: _AdminUploadTicketDataPageState._orange,
            iconBg: const Color(0xFFFFF3E8),
            title: 'File Requirements',
            scale: scale,
          ),
          SizedBox(height: 18 * scale),
          const _RequirementItem(
            title: 'Required Columns',
            subtitle: 'Employee ID, Employee Name, Ticket ID',
            icon: Icons.check_circle_rounded,
          ),
          SizedBox(height: 14 * scale),
          const _RequirementItem(
            title: 'Data Validation',
            subtitle: 'No duplicate ticket IDs allowed',
            icon: Icons.verified_rounded,
          ),
          SizedBox(height: 14 * scale),
          const _RequirementItem(
            title: 'Accepted Formats',
            subtitle: '.xlsx, .xls, and .csv files up to 10MB',
            icon: Icons.file_present_rounded,
          ),
        ],
      ),
    );
  }
}

class _RequirementItem extends StatelessWidget {
  const _RequirementItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: Color(0xFFEFFFF4),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: _AdminUploadTicketDataPageState._green,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _AdminUploadTicketDataPageState._darkText,
                  fontSize: 13.5,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _AdminUploadTicketDataPageState._mutedText,
                  fontSize: 12,
                  height: 1.25,
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

class _RecentUploadsSection extends StatelessWidget {
  const _RecentUploadsSection({
    required this.layout,
    required this.uploads,
    required this.onViewAll,
    required this.onRecordAction,
  });

  final _UploadLayout layout;
  final List<_UploadRecord> uploads;
  final VoidCallback onViewAll;
  final ValueChanged<_UploadRecord> onRecordAction;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(layout.isDesktop ? 22 : 18 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24 * scale),
        border: Border.all(color: _AdminUploadTicketDataPageState._softBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SectionTitleRow(
                  icon: Icons.history_rounded,
                  iconColor: _AdminUploadTicketDataPageState._primaryRed,
                  iconBg: const Color(0xFFFFEFEF),
                  title: 'Recent Uploads',
                  scale: scale,
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  foregroundColor: _AdminUploadTicketDataPageState._primaryRed,
                  padding: EdgeInsets.symmetric(
                    horizontal: 10 * scale,
                    vertical: 8 * scale,
                  ),
                ),
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12.5 * scale,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16 * scale),
          ...uploads.map(
            (upload) => Padding(
              padding: EdgeInsets.only(bottom: layout.cardGap),
              child: _UploadRecordCard(
                layout: layout,
                record: upload,
                onMore: () => onRecordAction(upload),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadRecordCard extends StatelessWidget {
  const _UploadRecordCard({
    required this.layout,
    required this.record,
    required this.onMore,
  });

  final _UploadLayout layout;
  final _UploadRecord record;
  final VoidCallback onMore;

  bool get _isError => record.status == _UploadStatus.failed;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;
    final statusColor = _isError
        ? _AdminUploadTicketDataPageState._primaryRed
        : _AdminUploadTicketDataPageState._green;

    return Container(
      padding: EdgeInsets.all(14 * scale),
      decoration: BoxDecoration(
        color: _AdminUploadTicketDataPageState._fieldBg,
        borderRadius: BorderRadius.circular(18 * scale),
        border: Border.all(color: const Color(0xFFF0F2F5)),
      ),
      child: Row(
        children: [
          Container(
            width: 48 * scale,
            height: 48 * scale,
            decoration: BoxDecoration(
              color: _isError
                  ? const Color(0xFFFFEFEF)
                  : const Color(0xFFEFFFF4),
              borderRadius: BorderRadius.circular(14 * scale),
            ),
            child: Center(
              child: Text(
                record.fileType,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10 * scale,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          SizedBox(width: 13 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _AdminUploadTicketDataPageState._darkText,
                    fontSize: layout.isDesktop ? 14.5 : 13.5 * scale,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8 * scale),
                Wrap(
                  spacing: 8 * scale,
                  runSpacing: 6 * scale,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 9 * scale,
                        vertical: 5 * scale,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _isError ? 'Failed' : 'Success',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11 * scale,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      record.recordsLabel,
                      style: TextStyle(
                        color: _AdminUploadTicketDataPageState._mutedText,
                        fontSize: 11.5 * scale,
                        height: 1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 7 * scale),
                Text(
                  record.uploadedAgo,
                  style: TextStyle(
                    color: const Color(0xFF98A2B3),
                    fontSize: 11 * scale,
                    height: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8 * scale),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14 * scale),
            child: InkWell(
              onTap: onMore,
              borderRadius: BorderRadius.circular(14 * scale),
              child: SizedBox(
                width: 40 * scale,
                height: 40 * scale,
                child: Icon(
                  Icons.more_vert_rounded,
                  color: _AdminUploadTicketDataPageState._mutedText,
                  size: 22 * scale,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.layout});

  final _UploadLayout layout;

  @override
  Widget build(BuildContext context) {
    final stats = [
      const _SummaryStat(
        icon: Icons.cloud_upload_rounded,
        value: '24',
        label: 'Total Uploads',
        color: _AdminUploadTicketDataPageState._primaryRed,
        bgColor: Color(0xFFFFEFEF),
      ),
      const _SummaryStat(
        icon: Icons.storage_rounded,
        value: '18.5K',
        label: 'Total Records',
        color: _AdminUploadTicketDataPageState._green,
        bgColor: Color(0xFFEFFFF4),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = layout.isDesktop ? 2 : 2;
        final gap = layout.gridGap;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: stats.map((stat) {
            return SizedBox(
              width: width,
              child: _SummaryCard(layout: layout, stat: stat),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.layout, required this.stat});

  final _UploadLayout layout;
  final _SummaryStat stat;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Container(
      padding: EdgeInsets.all(layout.isDesktop ? 22 : 18 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22 * scale),
        border: Border.all(color: _AdminUploadTicketDataPageState._softBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42 * scale,
            height: 42 * scale,
            decoration: BoxDecoration(
              color: stat.bgColor,
              borderRadius: BorderRadius.circular(14 * scale),
            ),
            child: Icon(stat.icon, color: stat.color, size: 22 * scale),
          ),
          SizedBox(height: 18 * scale),
          Text(
            stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _AdminUploadTicketDataPageState._darkText,
              fontSize: layout.isDesktop ? 28 : 24 * scale,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          SizedBox(height: 7 * scale),
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _AdminUploadTicketDataPageState._mutedText,
              fontSize: 12.5 * scale,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomUploadBar extends StatelessWidget {
  const _BottomUploadBar({
    required this.layout,
    required this.bottomSafe,
    required this.enabled,
    required this.uploading,
    required this.onStart,
  });

  final _UploadLayout layout;
  final double bottomSafe;
  final bool enabled;
  final bool uploading;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Container(
      padding: EdgeInsets.fromLTRB(
        layout.bottomBarPadding,
        14,
        layout.bottomBarPadding,
        14 + bottomSafe,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        border: const Border(top: BorderSide(color: Color(0xFFF0F1F3))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: layout.isDesktop ? 56 : 54 * scale,
        child: ElevatedButton.icon(
          onPressed: enabled ? onStart : null,
          icon: uploading
              ? SizedBox(
                  width: 20 * scale,
                  height: 20 * scale,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(Icons.upload_rounded, size: 20 * scale),
          label: Text(uploading ? 'Uploading...' : 'Start Upload Process'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _AdminUploadTicketDataPageState._deepRed,
            disabledBackgroundColor: const Color(0xFFE4E7EC),
            foregroundColor: Colors.white,
            disabledForegroundColor: const Color(0xFF98A2B3),
            elevation: enabled ? 10 : 0,
            shadowColor: _AdminUploadTicketDataPageState._deepRed.withOpacity(
              0.28,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18 * scale),
            ),
            textStyle: TextStyle(
              fontSize: layout.isDesktop ? 16 : 15.5 * scale,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitleRow extends StatelessWidget {
  const _SectionTitleRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.scale,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34 * scale,
          height: 34 * scale,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(11 * scale),
          ),
          child: Icon(icon, color: iconColor, size: 18 * scale),
        ),
        SizedBox(width: 10 * scale),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _AdminUploadTicketDataPageState._darkText,
              fontSize: 16 * scale,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _UploadOptionsSheet extends StatelessWidget {
  const _UploadOptionsSheet({required this.record});

  final _UploadRecord record;

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 520),
        padding: EdgeInsets.fromLTRB(22, 16, 22, 22 + bottomSafe),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
              Text(
                record.fileName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _AdminUploadTicketDataPageState._darkText,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${record.recordsLabel} • ${record.uploadedAgo}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _AdminUploadTicketDataPageState._mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 22),
              _SheetActionButton(
                icon: Icons.visibility_rounded,
                label: 'Preview Upload',
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 10),
              _SheetActionButton(
                icon: Icons.file_download_outlined,
                label: 'Download File',
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 10),
              _SheetActionButton(
                icon: Icons.close_rounded,
                label: 'Close',
                isDestructive: true,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetActionButton extends StatelessWidget {
  const _SheetActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? _AdminUploadTicketDataPageState._primaryRed
        : _AdminUploadTicketDataPageState._darkText;

    return Material(
      color: isDestructive ? const Color(0xFFFFEFEF) : const Color(0xFFF8F9FB),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
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

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final rRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rRect);
    final metrics = path.computeMetrics();

    const dashWidth = 4.5;
    const dashSpace = 5.5;

    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class _SummaryStat {
  const _SummaryStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color bgColor;
}

enum _UploadStatus { success, failed }

class _UploadRecord {
  const _UploadRecord({
    required this.fileName,
    required this.status,
    required this.recordsLabel,
    required this.uploadedAgo,
    required this.fileType,
  });

  final String fileName;
  final _UploadStatus status;
  final String recordsLabel;
  final String uploadedAgo;
  final String fileType;
}
