import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../models/task_model.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/task_modal.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().fetchTasks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Task> _getTasksForDay(DateTime day) {
    final allTasks = context.read<TaskProvider>().tasks;
    return allTasks.where((task) {
      if (task.dueBelow == null) return false;
      return isSameDay(task.dueBelow, day);
    }).toList();
  }

  // --- Widgets for the Custom Design ---

  Widget _buildHeader(BuildContext context) {
    // ignore: unused_local_variable
    final user = context.watch<AuthProvider>().user;
    
    return Column(
      children: [
        // Simple Month/Year Header (Clean)
        Row(
          mainAxisAlignment: MainAxisAlignment.start, // Left align or center? Design implies left usually.
          children: [
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 32,
                  color: AppColors.textPrimary,
                  fontFamily: 'Clash Display', 
                ),
                children: [
                  TextSpan(text: DateFormat('MMMM ').format(_focusedDay).toUpperCase()),
                  TextSpan(
                    text: DateFormat('yyyy').format(_focusedDay),
                    style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ).animate().fade(duration: 600.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Navigation (Prev/Reset/Next)
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary, size: 18),
                onPressed: () {
                  setState(() {
                    if (_calendarFormat == CalendarFormat.week) {
                      _focusedDay = _focusedDay.subtract(const Duration(days: 7));
                    } else {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                    }
                  });
                },
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _focusedDay = DateTime.now();
                    _selectedDay = _focusedDay;
                  });
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    'Today',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
                onPressed: () {
                  setState(() {
                    if (_calendarFormat == CalendarFormat.week) {
                      _focusedDay = _focusedDay.add(const Duration(days: 7));
                    } else {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                    }
                  });
                },
              ),
            ],
          ),
        ),
        
        // View Toggle
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            children: [
              _buildToggleButton('MONTH', _calendarFormat == CalendarFormat.month, () {
                setState(() => _calendarFormat = CalendarFormat.month);
              }),
              _buildToggleButton('WEEK', _calendarFormat == CalendarFormat.week, () {
                setState(() => _calendarFormat = CalendarFormat.week);
              }),
            ],
          ),
        ),
      ],
    ).animate().fade().slideX();
  }

  Widget _buildToggleButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? Border.all(color: AppColors.primary.withOpacity(0.3)) : null,
          boxShadow: isActive ? [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 8)] : null,
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isActive ? AppColors.primary : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime day, List<Task> tasks, {bool isSelected = false, bool isToday = false, bool isOutside = false}) {
    return Container(
      // CRITICAL: Margin to create the gap
      margin: const EdgeInsets.all(4), 
      decoration: BoxDecoration(
        color: isSelected 
             ? AppColors.surfaceHighlight
             : (isOutside ? AppColors.surface.withOpacity(0.2) : AppColors.surfaceElevated.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
               ? AppColors.primary // Selected border
               : (isToday ? AppColors.primary.withOpacity(0.5) : Colors.white.withOpacity(0.08)), // Subtle border
          width: isSelected ? 1 : 1,
        ),
        // Glassmorphism feel
        boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.2), 
             blurRadius: 4, 
             offset: const Offset(0, 2)
           ),
           if (isSelected)
             BoxShadow(
               color: AppColors.primary.withOpacity(0.1), 
               blurRadius: 10, 
               spreadRadius: 1
             ),
        ],
      ),
      child: Stack(
        children: [
           // Date Number
           Positioned(
             top: 6,
             left: 8,
             child: Text(
               '${day.day}',
               style: TextStyle(
                 color: isSelected 
                      ? Colors.white 
                      : (isOutside ? AppColors.textDisabled : AppColors.textSecondary),
                 fontWeight: FontWeight.bold,
                 fontSize: 13,
               ),
             ),
           ),
           
           // Tasks List (Chips) & More Indicator
           Positioned.fill(
             top: 24, 
             child: Padding(
               padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                   ...(() {
                     // Sort by priority: High (3) > Medium (2) > Low (1)
                     final sorted = List<Task>.from(tasks);
                     int getWeight(String p) {
                       switch (p.toLowerCase().trim()) {
                         case 'high': return 3;
                         case 'medium': return 2;
                         case 'low': return 1;
                         default: return 0;
                       }
                     }
                     // Descending order (Higher weight first)
                     sorted.sort((a, b) {
                        return getWeight(b.priority).compareTo(getWeight(a.priority));
                     });
                     
                     // Constrain based on View Format
                     final int maxItems = _calendarFormat == CalendarFormat.month ? 2 : 20;
                     
                     final visible = sorted.take(maxItems);
                     final overflow = tasks.length > maxItems ? tasks.length - maxItems : 0;
                     
                     return [
                       ...visible.map((task) => Container(
                         margin: const EdgeInsets.only(bottom: 1), // Tighter spacing
                         decoration: BoxDecoration(
                           color: (() {
                              switch(task.priority.toLowerCase()) {
                                case 'high': return AppColors.error.withOpacity(0.2);
                                case 'medium': return AppColors.warning.withOpacity(0.2);
                                default: return AppColors.primary.withOpacity(0.1);
                              }
                           })(), 
                           border: Border.all(
                             color: (() {
                                switch(task.priority.toLowerCase()) {
                                  case 'high': return AppColors.error.withOpacity(0.4);
                                  case 'medium': return AppColors.warning.withOpacity(0.4);
                                  default: return AppColors.primary.withOpacity(0.3);
                                }
                             })(),
                             width: 0.5,
                           ),
                           borderRadius: BorderRadius.circular(4),
                         ),
                         padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                         child: Row(
                            children: [
                              Container(
                                width: 4, height: 4, 
                                decoration: BoxDecoration(
                                  color: (() {
                                    switch(task.priority.toLowerCase()) {
                                      case 'high': return AppColors.error;
                                      case 'medium': return AppColors.warning;
                                      default: return AppColors.primary;
                                    }
                                  })(), 
                                  shape: BoxShape.circle
                                )
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                   task.title.toUpperCase(),
                                   style: TextStyle(
                                     fontSize: 8,
                                     fontWeight: FontWeight.w700,
                                     color: (() {
                                       switch(task.priority.toLowerCase()) {
                                         case 'high': return AppColors.error;
                                         case 'medium': return AppColors.warning;
                                         default: return AppColors.primary;
                                       }
                                     })(),
                                     overflow: TextOverflow.ellipsis,
                                   ),
                                   maxLines: 1,
                                ),
                              ),
                            ],
                         ),
                       )),
                       
                       if (overflow > 0)
                         Padding(
                           padding: const EdgeInsets.only(top: 1),
                           child: Text(
                             '+ $overflow more',
                             style: TextStyle(
                               color: isSelected ? Colors.white.withOpacity(0.9) : AppColors.textSecondary,
                               fontSize: 8, // Very small to fit
                               fontWeight: FontWeight.w800,
                             ),
                           ),
                         ),
                     ];
                   })(),
                 ],
               ),
             ),
           ),
          ),
        ],
      ),
    );
  }

  void _showTasksDialog(DateTime date, List<Task> tasks) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF0F1218), // Deep match
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withOpacity(0.1))
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           "MISSION LOG",
                           style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold),
                         ),
                         const SizedBox(height: 4),
                         Text(
                           DateFormat('MMM d, yyyy').format(date).toUpperCase(),
                           style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textPrimary, fontSize: 20, fontFamily: 'Clash Display'),
                         ),
                       ],
                     ),
                     IconButton(
                       icon: const Icon(Icons.close, color: AppColors.textSecondary),
                       onPressed: () => Navigator.pop(context),
                     )
                   ],
                ),
                const SizedBox(height: 24),
                if (tasks.isEmpty)
                   Container(
                     padding: const EdgeInsets.all(32),
                     width: double.infinity,
                     decoration: BoxDecoration(
                       color: Colors.white.withOpacity(0.02),
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(color: Colors.white.withOpacity(0.05)),
                     ),
                     child: const Column(
                       children: [
                         Icon(Icons.radar, color: AppColors.textDisabled, size: 32),
                         SizedBox(height: 12),
                         Text("NO ACTIVE MISSIONS", style: TextStyle(color: AppColors.textDisabled, fontSize: 12, letterSpacing: 1)),
                       ],
                     ),
                   )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: tasks.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final task = tasks[i];
                         final isCompleted = task.status == 'completed';
                         return InkWell(
                           onTap: () {
                             TaskModal.show(context, task: task, isViewing: true);
                           },
                           borderRadius: BorderRadius.circular(8),
                           child: Container(
                          padding: const EdgeInsets.all(12),
                           decoration: BoxDecoration(
                             color: AppColors.surfaceElevated,
                             borderRadius: BorderRadius.circular(8),
                             border: Border.all(color: Colors.white.withOpacity(0.08)),
                             boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)]
                           ),
                           child: Row(
                             children: [
                               Expanded(
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(
                                          task.title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                            fontSize: 14,
                                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                                            decorationColor: AppColors.textSecondary,
                                            decorationThickness: 2,
                                          ),
                                        ),
                                   ],
                                 ),
                               ),
                               Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                 decoration: BoxDecoration(
                                   color: Colors.white.withOpacity(0.05),
                                   borderRadius: BorderRadius.circular(4),
                                 ),
                                 child: Text(task.priority.toUpperCase(), style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                               )
                             ],
                           ),
                         ),
                         );
                      }
                    ),
                  )
              ],
            ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
              
              // Controls Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: _buildControls(),
              ),
              const SizedBox(height: 16),
              
              // Headers (Sun, Mon, Tue...)
              // TableCalendar has built-in headers, but to match "GAP" style strictly, we might need custom.
              // We'll trust TableCalendar's header style for now but ensure it aligns.
              
              // Calendar Grid
              Expanded(
                child: TableCalendar<Task>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: _getTasksForDay,
                  
                  shouldFillViewport: true, // Responsiveness
                  headerVisible: false,
                  pageJumpingEnabled: true,
                  
                  // Minimalistic Animation for View Swaps
                  formatAnimationDuration: const Duration(milliseconds: 500),
                  formatAnimationCurve: Curves.easeInOut,
                  
                  daysOfWeekHeight: 24,
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekendStyle: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
                    weekdayStyle: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
                  ),
                  
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                       return _buildDayCell(context, day, _getTasksForDay(day));
                    },
                    selectedBuilder: (context, day, focusedDay) {
                       return _buildDayCell(context, day, _getTasksForDay(day), isSelected: true);
                    },
                    todayBuilder: (context, day, focusedDay) {
                       return _buildDayCell(context, day, _getTasksForDay(day), isToday: true);
                    },
                    outsideBuilder: (context, day, focusedDay) {
                       return _buildDayCell(context, day, _getTasksForDay(day), isOutside: true);
                    },
                    markerBuilder: (context, day, events) { return const SizedBox.shrink(); } 
                  ),
                  
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    if (isSameDay(selectedDay, _selectedDay)) {
                       _showTasksDialog(selectedDay, _getTasksForDay(selectedDay));
                    }
                  },
                  onPageChanged: (focusedDay) {
                    setState(() => _focusedDay = focusedDay);
                  },
                ),
              ).animate().fade(delay: 100.ms).slideY(begin: 0.1, end: 0),
            ],
          ),
        ),
        
        // FAB
        Positioned(
          bottom: 32,
          right: 32,
          child: Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary, 
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ],
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => TaskModal.show(context),
                borderRadius: BorderRadius.circular(16),
                child: const Icon(Icons.add, color: Colors.black, size: 28),
              ),
            ),
          ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
        ),
      ],
    ).animate().fade().slideX();
  }
}







