import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'main.dart';
import 'model/class.dart';
import 'model/hours_mins.dart';

class ClassesTab extends StatefulWidget {
  final List<Class> classes;
  final void Function(Class) onClassAdded;
  final void Function(int, Class) onClassUpdated;
  final void Function(int) onClassDeleted;
  final Widget drawerWidget;

  const ClassesTab({
    super.key,
    required this.classes,
    required this.onClassAdded,
    required this.onClassUpdated,
    required this.onClassDeleted,
    required this.drawerWidget,
  });

  @override
  State<ClassesTab> createState() => _ClassesTabState();
}

class _ClassesTabState extends State<ClassesTab> {
  final _classTypeController = TextEditingController();
  final _roomController = TextEditingController();
  final _profNameController = TextEditingController();
  final _profSurnameController = TextEditingController();
  final _profEmailController = TextEditingController();
  
  DayOfTheWeek _selectedDay = DayOfTheWeek.monday;
  HoursMins? _fromTime;
  HoursMins? _toTime;
  bool _isLoadingDialog = false;

  @override
  void dispose() {
    _classTypeController.dispose();
    _roomController.dispose();
    _profNameController.dispose();
    _profSurnameController.dispose();
    _profEmailController.dispose();
    super.dispose();
  }

  void _clearDialogFields() {
    _classTypeController.clear();
    _roomController.clear();
    _profNameController.clear();
    _profSurnameController.clear();
    _profEmailController.clear();
    _selectedDay = DayOfTheWeek.monday;
    _fromTime = null;
    _toTime = null;
    _isLoadingDialog = false;
  }

  Future<void> _addClass(BuildContext dialogContext) async {
    final classType = _classTypeController.text.trim();
    final room = _roomController.text.trim();

    if (classType.isEmpty || room.isEmpty || _fromTime == null || _toTime == null) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Errore'),
          description: Text('Compila i campi obbligatori (Tipo, Aula, Orari).'),
        ),
      );
      return;
    }

    final navigator = Navigator.of(dialogContext);
    setState(() => _isLoadingDialog = true);

    try {
      final newClass = await apiClient.addClass(
        day: _selectedDay,
        classType: classType,
        from: _fromTime!,
        to: _toTime!,
        room: room,
        profName: _profNameController.text.trim().isNotEmpty ? _profNameController.text.trim() : null,
        profSurname: _profSurnameController.text.trim().isNotEmpty ? _profSurnameController.text.trim() : null,
        profEmail: _profEmailController.text.trim().isNotEmpty ? _profEmailController.text.trim() : null,
      );
      if (!mounted) return;
      navigator.pop();
      widget.onClassAdded(newClass);
    } catch (e) {
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Errore'),
          description: Text('Impossibile aggiungere la lezione.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingDialog = false);
    }
  }

  Future<void> _editClass(BuildContext dialogContext, int classID) async {
    final classType = _classTypeController.text.trim();
    final room = _roomController.text.trim();

    if (classType.isEmpty || room.isEmpty || _fromTime == null || _toTime == null) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Errore'),
          description: Text('Compila i campi obbligatori (Tipo, Aula, Orari).'),
        ),
      );
      return;
    }

    final navigator = Navigator.of(dialogContext);
    setState(() => _isLoadingDialog = true);

    try {
      await apiClient.updateClass(
        classID: classID,
        day: _selectedDay,
        classType: classType,
        from: _fromTime,
        to: _toTime,
        room: room,
        profName: _profNameController.text.trim().isNotEmpty ? _profNameController.text.trim() : null,
        profSurname: _profSurnameController.text.trim().isNotEmpty ? _profSurnameController.text.trim() : null,
        profEmail: _profEmailController.text.trim().isNotEmpty ? _profEmailController.text.trim() : null,
      );
      if (!mounted) return;
      navigator.pop();
      final existingClass = widget.classes.firstWhere((c) => c.classID == classID);
      final updatedClass = Class(
        classID: classID,
        userID: existingClass.userID,
        day: _selectedDay,
        classType: classType,
        from: _fromTime!,
        to: _toTime!,
        room: room,
        profName: _profNameController.text.trim().isNotEmpty ? _profNameController.text.trim() : null,
        profSurname: _profSurnameController.text.trim().isNotEmpty ? _profSurnameController.text.trim() : null,
        profEmail: _profEmailController.text.trim().isNotEmpty ? _profEmailController.text.trim() : null,
      );
      widget.onClassUpdated(classID, updatedClass);
    } catch (e) {
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Errore'),
          description: Text('Impossibile modificare la lezione.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingDialog = false);
    }
  }

  Future<void> _deleteClass(int classID) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Elimina Lezione', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Sei sicuro di voler eliminare questa lezione?', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await apiClient.deleteClass(classID: classID);
      widget.onClassDeleted(classID);
    } catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Errore'),
          description: Text('Impossibile eliminare la lezione.'),
        ),
      );
    }
  }

  void _showClassDialog({Class? existingClass, DayOfTheWeek? preselectedDay}) {
    if (existingClass != null) {
      _classTypeController.text = existingClass.classType;
      _roomController.text = existingClass.room;
      _profNameController.text = existingClass.profName??'';
      _profSurnameController.text = existingClass.profSurname??'';
      _profEmailController.text = existingClass.profEmail??'';
      _selectedDay = existingClass.day;
      _fromTime = existingClass.from;
      _toTime = existingClass.to;
    } else {
      _clearDialogFields();
      if (preselectedDay != null) {
        _selectedDay = preselectedDay;
      }
    }

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: const Color(0xFF18181B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          existingClass == null ? 'Aggiungi Lezione' : 'Modifica Lezione',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(),
                        child: const Icon(Icons.close, color: Colors.white54, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Inserisci i dettagli per la lezione qui sotto.',
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 450),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          
                          // Class Type
                          const Text('Nome / Tipo', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          ShadInput(
                            controller: _classTypeController,
                            placeholder: Text('es. Analisi 1, Esercitazione'),
                            decoration: ShadDecoration(
                              border: ShadBorder.all(
                                color: const Color(0xFF666666),
                                width: 1.5,
                                radius: BorderRadius.circular(8),
                              ),
                              focusedBorder: ShadBorder.all(
                                color: Colors.white,
                                width: 1.5,
                                radius: BorderRadius.circular(8),
                              ),
                              disableSecondaryBorder: true,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Room
                          const Text('Aula', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          ShadInput(
                            controller: _roomController,
                            decoration: ShadDecoration(
                              border: ShadBorder.all(
                                color: const Color(0xFF666666),
                                width: 1.5,
                                radius: BorderRadius.circular(8),
                              ),
                              focusedBorder: ShadBorder.all(
                                color: Colors.white,
                                width: 1.5,
                                radius: BorderRadius.circular(8),
                              ),
                              disableSecondaryBorder: true,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Times
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Inizio', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: () async {
                                        final time = await showTimePicker(
                                          context: context,
                                          initialTime: _fromTime != null
                                            ? TimeOfDay(hour: _fromTime!.hours, minute: _fromTime!.mins)
                                            : const TimeOfDay(hour: 9, minute: 0),
                                          builder: (context, child) {
                                            return Theme(
                                              data: Theme.of(context).copyWith(
                                                timePickerTheme: const TimePickerThemeData(
                                                  backgroundColor: Color(0xFF18181B),
                                                ),
                                              ),
                                              child: child!,
                                            );
                                          },
                                        );
                                        if (time != null) {
                                          setDialogState(() => _fromTime = HoursMins.fromTimeOfDay(time));
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: const Color(0xFF666666), width: 1.5),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _fromTime == null ? 'Seleziona' : '${_fromTime!.hours.toString().padLeft(2, '0')}:${_fromTime!.mins.toString().padLeft(2, '0')}',
                                          style: TextStyle(color: _fromTime == null ? Colors.white54 : Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Fine', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: () async {
                                        final time = await showTimePicker(
                                          context: context,
                                          initialTime: _toTime != null 
                                            ? TimeOfDay(hour: _toTime!.hours, minute: _toTime!.mins) 
                                            : const TimeOfDay(hour: 11, minute: 0),
                                          builder: (context, child) {
                                            return Theme(
                                              data: Theme.of(context).copyWith(
                                                timePickerTheme: const TimePickerThemeData(
                                                  backgroundColor: Color(0xFF18181B),
                                                ),
                                              ),
                                              child: child!,
                                            );
                                          },
                                        );
                                        if (time != null) {
                                          setDialogState(() => _toTime = HoursMins.fromTimeOfDay(time));
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: const Color(0xFF666666), width: 1.5),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _toTime == null ? 'Seleziona' : '${_toTime!.hours.toString().padLeft(2, '0')}:${_toTime!.mins.toString().padLeft(2, '0')}',
                                          style: TextStyle(color: _toTime == null ? Colors.white54 : Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Professor details (optional)
                          const Text('Dettagli Docente (Opzionale)', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          
                          // Prof Name
                          const Text('Nome Docente', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          ShadInput(
                            controller: _profNameController,
                            decoration: ShadDecoration(
                              border: ShadBorder.all(
                                color: const Color(0xFF666666),
                                width: 1.5,
                                radius: BorderRadius.circular(8),
                              ),
                              focusedBorder: ShadBorder.all(
                                color: Colors.white,
                                width: 1.5,
                                radius: BorderRadius.circular(8),
                              ),
                              disableSecondaryBorder: true,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Prof Surname
                          const Text('Cognome Docente', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          ShadInput(
                            controller: _profSurnameController,
                            decoration: ShadDecoration(
                              border: ShadBorder.all(
                                color: const Color(0xFF666666),
                                width: 1.5,
                                radius: BorderRadius.circular(8),
                              ),
                              focusedBorder: ShadBorder.all(
                                color: Colors.white,
                                width: 1.5,
                                radius: BorderRadius.circular(8),
                              ),
                              disableSecondaryBorder: true,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Prof Email
                          const Text('Email Docente', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          ShadInput(
                            controller: _profEmailController,
                            decoration: ShadDecoration(
                              border: ShadBorder.all(
                                color: const Color(0xFF666666),
                                width: 1.5,
                                radius: BorderRadius.circular(8),
                              ),
                              focusedBorder: ShadBorder.all(
                                color: Colors.white,
                                width: 1.5,
                                radius: BorderRadius.circular(8),
                              ),
                              disableSecondaryBorder: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ShadButton.outline(
                        child: const Text('Annulla', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                      const SizedBox(width: 8),
                      ShadButton(
                        onPressed: _isLoadingDialog ? null : () => existingClass == null
                          ? _addClass(dialogContext)
                          : _editClass(dialogContext, existingClass.classID),
                        leading: _isLoadingDialog
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : null,
                        child: const Text('Salva', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _dayToString(DayOfTheWeek day) {
    switch (day) {
      case DayOfTheWeek.monday: return 'Lunedì';
      case DayOfTheWeek.tuesday: return 'Martedì';
      case DayOfTheWeek.wednesday: return 'Mercoledì';
      case DayOfTheWeek.thursday: return 'Giovedì';
      case DayOfTheWeek.friday: return 'Venerdì';
      case DayOfTheWeek.saturday: return 'Sabato';
      case DayOfTheWeek.sunday: return 'Domenica';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Planning Settimanale',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: Builder(
            builder: (context) {
              return GestureDetector(
                onTap: () {
                  Scaffold.of(context).openDrawer();
                },
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.all(16),
                  child: const Icon(Icons.menu_rounded),
                ),
              );
            }
        ),
      ),
      drawer: widget.drawerWidget,
      body: Builder(
        builder: (context) {
          final classes = List<Class>.from(widget.classes);
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: DayOfTheWeek.values.length,
            itemBuilder: (context, index) {
              final day = DayOfTheWeek.values[index];
              final dayClasses = classes.where((c) => c.day == day).toList();
              
              // Sort day classes by start time
              dayClasses.sort((a, b) {
                if (a.from.hours != b.from.hours) {
                  return a.from.hours.compareTo(b.from.hours);
                }
                return a.from.mins.compareTo(b.from.mins);
              });

              return Card(
                color: const Color(0xFF232323),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF333333)),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _dayToString(day),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (dayClasses.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF333333),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${dayClasses.length}', 
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                            ),
                          ),
                      ],
                    ),
                    iconColor: Colors.white,
                    collapsedIconColor: Colors.white54,
                    children: [
                      if (dayClasses.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Nessuna lezione', style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
                        )
                      else
                        ...dayClasses.map((cls) => _buildClassItem(cls)),
                      
                      // Add class button at the end of the day's classes
                      GestureDetector(
                        onTap: () => _showClassDialog(preselectedDay: day),
                        child: Card(
                          color: const Color(0xFF232323),
                          margin: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.white54),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text(
                                'Aggiungi lezione',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  Widget _buildPopUpMenu(BuildContext context, Function edit, Function delete){
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white70),
        tooltip: '',
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: const Color(0xFF2A2A2A),
        onSelected: (value) {
          if (value == 'edit') {
            edit();
          } else if (value == 'delete') {
            delete();
          }
        },
        itemBuilder:
            (context) => [
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: const [
                Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
                SizedBox(width: 12),
                Text(
                  'Modifica',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: const [
                Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                SizedBox(width: 12),
                Text(
                  'Elimina',
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassItem(Class cls) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF333333))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 65,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${cls.from.hours.toString().padLeft(2, '0')}:${cls.from.mins.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  '${cls.to.hours.toString().padLeft(2, '0')}:${cls.to.mins.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
          
          // Divider
          Container(
            width: 2,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: const Color(0xFF444444),
          ),
          
          // Details column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cls.classType,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.room, size: 14, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text(
                      cls.room,
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
                if(cls.profName!=null||cls.profSurname!=null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.person, size: 14, color: Colors.white54),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${cls.profName} ${cls.profSurname}'.trim(),
                            style: const TextStyle(color: Colors.white54, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if(cls.profEmail!=null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.email, size: 14, color: Colors.white54),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${cls.profEmail}'.trim(),
                              style: const TextStyle(color: Colors.white54, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
          ...[
            _buildPopUpMenu(context, ()=>_showClassDialog(existingClass: cls), ()=>_deleteClass(cls.classID)),
          ],
        ],
      ),
    );
  }
}
