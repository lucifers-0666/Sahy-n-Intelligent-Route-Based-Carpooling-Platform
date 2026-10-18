import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_colors.dart';

/// Dedicated Travel Date & Time Selection Screen for Sahyan.
/// Provides calendar-based date selection, departure time presets, custom time picking,
/// and clear validation respecting platform scheduling guidelines.
class TravelDateTimeScreen extends StatefulWidget {
  final DateTime initialDate;
  final TimeOfDay initialTime;

  const TravelDateTimeScreen({
    super.key,
    required this.initialDate,
    required this.initialTime,
  });

  @override
  State<TravelDateTimeScreen> createState() => _TravelDateTimeScreenState();
}

class _TravelDateTimeScreenState extends State<TravelDateTimeScreen> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _selectedTime = widget.initialTime;
  }

  void _selectPresetDate(int daysFromToday) {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final target = now.add(Duration(days: daysFromToday));
    setState(() {
      _selectedDate = DateTime(target.year, target.month, target.day);
    });
  }

  void _selectPresetTime(int hour, int minute) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _openCustomTimePicker() async {
    HapticFeedback.selectionClick();
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.deepEmerald,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.primaryText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatDateSummary(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];

    if (diff == 0) return 'Today ($weekday, ${date.day} $month)';
    if (diff == 1) return 'Tomorrow ($weekday, ${date.day} $month)';
    return '$weekday, ${date.day} $month ${date.year}';
  }

  void _confirmAndReturn() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop({
      'date': _selectedDate,
      'time': _selectedTime,
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final minDate = DateTime(now.year, now.month, now.day);
    final maxDate = minDate.add(const Duration(days: 30));
    final formattedTime = _selectedTime.format(context);
    final dateSummary = _formatDateSummary(_selectedDate);

    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = _selectedDate.year == tomorrow.year &&
        _selectedDate.month == tomorrow.month &&
        _selectedDate.day == tomorrow.day;

    return Scaffold(
      backgroundColor: AppColors.canvasLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.primaryText,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Travel Date & Time',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryText,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Quick Date Presets
                    const Text(
                      'DEPARTURE DATE',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        _QuickChip(
                          label: 'Today',
                          isSelected: isToday,
                          onTap: () => _selectPresetDate(0),
                        ),
                        const SizedBox(width: 8),
                        _QuickChip(
                          label: 'Tomorrow',
                          isSelected: isTomorrow,
                          onTap: () => _selectPresetDate(1),
                        ),
                        const SizedBox(width: 8),
                        _QuickChip(
                          label: 'In 2 Days',
                          isSelected: !isToday && !isTomorrow,
                          onTap: () => _selectPresetDate(2),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Calendar Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.border,
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryText.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.deepEmerald,
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: AppColors.primaryText,
                          ),
                        ),
                        child: CalendarDatePicker(
                          initialDate: _selectedDate,
                          firstDate: minDate,
                          lastDate: maxDate,
                          onDateChanged: (newDate) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedDate = newDate;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Section 2: Departure Time
                    const Text(
                      'DEPARTURE TIME',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Time Presets
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _TimePresetChip(
                            label: 'Morning',
                            time: '08:00 AM',
                            isSelected: _selectedTime.hour == 8 &&
                                _selectedTime.minute == 0,
                            onTap: () => _selectPresetTime(8, 0),
                          ),
                          const SizedBox(width: 8),
                          _TimePresetChip(
                            label: 'Afternoon',
                            time: '01:00 PM',
                            isSelected: _selectedTime.hour == 13 &&
                                _selectedTime.minute == 0,
                            onTap: () => _selectPresetTime(13, 0),
                          ),
                          const SizedBox(width: 8),
                          _TimePresetChip(
                            label: 'Evening',
                            time: '05:30 PM',
                            isSelected: _selectedTime.hour == 17 &&
                                _selectedTime.minute == 30,
                            onTap: () => _selectPresetTime(17, 30),
                          ),
                          const SizedBox(width: 8),
                          _TimePresetChip(
                            label: 'Night',
                            time: '08:30 PM',
                            isSelected: _selectedTime.hour == 20 &&
                                _selectedTime.minute == 30,
                            onTap: () => _selectPresetTime(20, 30),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Custom Time Selector Tile
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: _openCustomTimePicker,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.border,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.access_time_rounded,
                                  color: AppColors.deepEmerald,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Selected Time',
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.mutedText,
                                      ),
                                    ),
                                    Text(
                                      formattedTime,
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryText,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.lightSurface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.border,
                                    width: 0.8,
                                  ),
                                ),
                                child: const Text(
                                  'Change',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.deepEmerald,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section 3: Summary Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.softMint.withValues(alpha: 0.6),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: AppColors.deepEmerald,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateSummary,
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.deepEmerald,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Departure at $formattedTime (flexible ±30 min matching window).',
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 11.5,
                                    color: AppColors.primaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom Confirm Button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 0.8),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _confirmAndReturn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepEmerald,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Confirm Date & Time',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: isSelected ? AppColors.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.deepEmerald : AppColors.border,
                width: isSelected ? 1.2 : 0.8,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? AppColors.deepEmerald
                    : AppColors.primaryText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimePresetChip extends StatelessWidget {
  final String label;
  final String time;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimePresetChip({
    required this.label,
    required this.time,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primaryLight : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.deepEmerald : AppColors.border,
              width: isSelected ? 1.2 : 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.deepEmerald
                      : AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: isSelected
                      ? AppColors.deepEmerald
                      : AppColors.primaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
