import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:unilife/model/hours_mins.dart';
import 'main.dart';
import 'model/exam.dart';

class ExamsTab extends StatefulWidget {
  final List<Exam> exams;
  final void Function(Exam) onExamAdded;
  final void Function(int, Exam) onExamUpdated;
  final void Function(int) onExamDeleted;
  final Widget drawerWidget;
  const ExamsTab({
    super.key,
    required this.exams,
    required this.onExamAdded,
    required this.onExamUpdated,
    required this.onExamDeleted,
    required this.drawerWidget,
  });

  @override
  State<ExamsTab> createState() => _ExamsTabState();
}

class _ExamsTabState extends State<ExamsTab> {
  final _courseNameController = TextEditingController();
  DateTime? _selectedDate;
  HoursMins? _selectedTime;
  Priority _selectedPriority = Priority.medium;
  bool _isLoadingDialog = false;

  @override
  void dispose() {
    _courseNameController.dispose();
    super.dispose();
  }

  Future<void> _editExam(BuildContext dialogContext, int examID) async {
    final name = _courseNameController.text.trim();
    if (name.isEmpty || _selectedDate == null) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Errore'),
          description: Text('Compila tutti i campi.'),
        ),
      );
      return;
    }

    final navigator = Navigator.of(dialogContext);

    setState(() => _isLoadingDialog = true);
    try {
      await apiClient.updateExam(
        examID: examID,
        courseName: name,
        due: _selectedDate!,
        priority: _selectedPriority,
        time: _selectedTime!,
      );
      if (!mounted) return;
      navigator.pop();
      final existingExam = widget.exams.firstWhere((e) => e.examID == examID);
      final updatedExam = Exam(
        examID: examID,
        userID: existingExam.userID,
        courseName: name,
        due: _selectedDate!,
        time: _selectedTime!,
        priority: _selectedPriority,
      );
      widget.onExamUpdated(examID, updatedExam);
    } catch (e) {
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Errore'),
          description: Text('Impossibile modificare l\'esame.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingDialog = false);
    }
  }

  Future<void> _deleteExam(int examID) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            title: const Text(
              'Elimina Esame',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Sei sicuro di voler eliminare questo esame?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Annulla',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Elimina',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      await apiClient.deleteExam(examID: examID);
      widget.onExamDeleted(examID);
    } catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Errore'),
          description: Text('Impossibile eliminare l\'esame.'),
        ),
      );
    }
  }

  Future<void> _addExam(BuildContext dialogContext) async {
    final name = _courseNameController.text.trim();
    if (name.isEmpty || _selectedDate == null) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Errore'),
          description: Text('Compila tutti i campi.'),
        ),
      );
      return;
    }

    final navigator = Navigator.of(dialogContext);

    setState(() => _isLoadingDialog = true);
    try {
      final newExam = await apiClient.addExam(
        courseName: name,
        due: _selectedDate!,
        priority: _selectedPriority,
        time: _selectedTime!,
      );
      if (!mounted) return;
      navigator.pop();
      widget.onExamAdded(newExam);
    } catch (e) {
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Errore'),
          description: Text('Impossibile aggiungere l\'esame.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingDialog = false);
    }
  }

  void _showExamDialog({Exam? existingExam}) {
    if(existingExam!=null){
      _courseNameController.text=existingExam.courseName;
      _selectedDate=existingExam.due;
      _selectedTime=existingExam.time;
      _selectedPriority=existingExam.priority;
    }else{
      _courseNameController.clear();
      _selectedDate=null;
      _selectedPriority=Priority.medium;
    }

    _isLoadingDialog=false;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: false,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                backgroundColor: const Color(0xFF18181B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
                            const Expanded(
                              child: Text(
                                'Aggiungi Promemoria Esame',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
                          'Inserisci i dettagli del prossimo esame.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              const Text(
                                'Nome Corso',
                                style: TextStyle(color: Colors.white, fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              ShadInput(
                                controller: _courseNameController,
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
                              const Text(
                                'Data',
                                style: TextStyle(color: Colors.white, fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2100),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          datePickerTheme: const DatePickerThemeData(
                                            backgroundColor: Color(0xFF18181B),
                                          ),
                                        ),
                                        child: child!,
                                      );
                                     }
                                  );
                                  if (date != null) {
                                    setDialogState(() => _selectedDate = date);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFF666666),
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _selectedDate == null
                                            ? 'Seleziona una data'
                                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                        style: TextStyle(
                                          color:
                                              _selectedDate == null
                                                  ? Colors.white54
                                                  : Colors.white,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: Colors.white54,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16,),
                              const Text(
                                'Ora',
                                style: TextStyle(color: Colors.white, fontSize: 13),
                              ),
                              const SizedBox(height: 6,),
                              GestureDetector(
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: _selectedTime != null
                                        ? TimeOfDay(hour: _selectedTime!.hours, minute: _selectedTime!.mins)
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
                                    setDialogState(() => _selectedTime = HoursMins.fromTimeOfDay(time));
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFF666666), width: 1.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _selectedTime == null ? 'Seleziona' : '${_selectedTime!.hours.toString().padLeft(2, '0')}:${_selectedTime!.mins.toString().padLeft(2, '0')}',
                                    style: TextStyle(color: _selectedTime == null ? Colors.white54 : Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Priorità',
                                style: TextStyle(color: Colors.white, fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              ShadSelect<Priority>(
                                placeholder: const Text('Seleziona priorità'),
                                initialValue: _selectedPriority,
                                options: [
                                  ShadOption(
                                    value: Priority.low,
                                    child: const Text('Bassa'),
                                  ),
                                  ShadOption(
                                    value: Priority.medium,
                                    child: const Text('Media'),
                                  ),
                                  ShadOption(
                                    value: Priority.high,
                                    child: const Text('Alta'),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    setDialogState(() => _selectedPriority = v);
                                  }
                                },
                                selectedOptionBuilder: (context, value) {
                                  final labels = {
                                    Priority.low: 'Bassa',
                                    Priority.medium: 'Media',
                                    Priority.high: 'Alta',
                                  };
                                  return Text(labels[value]!);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ShadButton.outline(
                              child: const Text('Annulla'),
                              onPressed: () => Navigator.of(dialogContext).pop(),
                            ),
                            const SizedBox(width: 8),
                            ShadButton(
                              onPressed:
                                  _isLoadingDialog ? null :
                                      existingExam==null?() => _addExam(dialogContext)
                                        :()=>_editExam(dialogContext, existingExam.examID),
                              leading:
                                  _isLoadingDialog
                                      ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                      : null,
                              child: const Text('Salva'),
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

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.low:
        return Colors.green;
      case Priority.medium:
        return Colors.amber;
      case Priority.high:
        return Colors.red;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Esami',
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
          final exams = List<Exam>.from(widget.exams);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: exams.isEmpty ? 1 : exams.length + 1,
            itemBuilder: (context, index) {
              if (index == (exams.isEmpty ? 0 : exams.length)) {
                // Add card at the end
                return GestureDetector(
                  onTap: () => _showExamDialog(),
                  child: Card(
                    color: const Color(0xFF1A1A1A),
                    margin: EdgeInsets.only(bottom: exams.isEmpty ? 0 : 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.white54),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'Aggiungi promemoria',
                          style: TextStyle(
                            color: Colors.white54,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              final exam = exams[index];
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final examDate = DateTime(exam.due.year, exam.due.month, exam.due.day);
              final daysLeft = examDate.difference(today).inDays;
              final daysText = daysLeft>1?'Fra $daysLeft giorni':(daysLeft>0?'Domani':'Oggi');

              return Card(
                color: const Color(0xFF232323),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF333333)),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      exam.courseName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${exam.due.day}/${exam.due.month}/${exam.due.year} ($daysText)',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6,),
                          Row(
                            children: [
                              const Icon(
                                Icons.timer,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${exam.time.hours.toString().padLeft(2, '0')}:${exam.time.mins.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getPriorityColor(exam.priority),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ...[
                          _buildPopUpMenu(context, ()=> _showExamDialog(existingExam: exam), ()=> _deleteExam(exam.examID)),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
