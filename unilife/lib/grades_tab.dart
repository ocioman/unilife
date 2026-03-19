import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';
import 'model/grade.dart';

class GradesTab extends StatefulWidget {
  final List<Grade> grades;
  final double average;
  final void Function(Grade) onGradeAdded;
  final void Function(int, Grade) onGradeUpdated;
  final void Function(int) onGradeDeleted;
  final void Function(int, bool) onGradeCompletionChanged;
  final Widget drawerWidget;
  const GradesTab({
    super.key,
    required this.grades,
    required this.average,
    required this.onGradeAdded,
    required this.onGradeUpdated,
    required this.onGradeDeleted,
    required this.onGradeCompletionChanged,
    required this.drawerWidget,
  });

  @override
  State<GradesTab> createState() => _GradesTabState();
}

class _GradesTabState extends State<GradesTab> {
  bool _isLoadingDialog = false;

  final _examNameController = TextEditingController();
  final _valueController = TextEditingController();
  final _cfuController = TextEditingController();
  bool _hasPartials = false;

  final _partialNameController = TextEditingController();
  final _parentExamNameController = TextEditingController();
  final _partialValueController = TextEditingController();
  final _partialWeightController = TextEditingController();

  @override
  void dispose() {
    _examNameController.dispose();
    _valueController.dispose();
    _cfuController.dispose();
    _partialNameController.dispose();
    _parentExamNameController.dispose();
    _partialValueController.dispose();
    _partialWeightController.dispose();
    super.dispose();
  }

  Future<void> _addNormalOrParentGrade(BuildContext dialogContext) async {
    final name = _examNameController.text.trim();
    final cfuStr = _cfuController.text.trim();
    final valueStr = _valueController.text.trim();

    if (name.isEmpty || cfuStr.isEmpty || (!_hasPartials && valueStr.isEmpty)) {
      if (context.mounted) {
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            title: Text('Errore'),
            description: Text('Compila i campi necessari.'),
          ),
        );
      }
      return;
    }

    final cfu = int.tryParse(cfuStr);
    if (cfu == null) {
      if (context.mounted) {
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            title: Text('Errore'),
            description: Text('CFU deve essere un numero.'),
          ),
        );
      }
      return;
    }

    double? value;
    if (!_hasPartials) {
      value = double.tryParse(valueStr);
      if (value == null) {
        if (context.mounted) {
          ShadToaster.of(context).show(
            const ShadToast.destructive(
              title: Text('Errore'),
              description: Text('Il voto deve essere un numero.'),
            ),
          );
        }
        return;
      }else if(value>30){
        if(context.mounted){
          ShadToaster.of(context).show(
            ShadToast.destructive(
              title: Text('Errore'),
              description: Text('Il voto deve essere minore o uguale a 30'),
            )
          );
          return;
        }
      }else if(value<17){
        if(context.mounted){
          ShadToaster.of(context).show(
            ShadToast.destructive(
              title: Text('Errore'),
              description: Text('Il voto deve essere maggiore o uguale a 17'),
            )
          );
        }
        return;
      }
    }

    final navigator = Navigator.of(dialogContext);

    setState(() => _isLoadingDialog = true);
    try {
      final newGrade = await apiClient.addGrade(
        examName: name,
        cfu: cfu,
        value: value,
        isPartial: _hasPartials,
        isCompleted: _hasPartials ? false : true,
        parentGradeID: null,
      );
      if (!mounted) return;
      navigator.pop();
      widget.onGradeAdded(newGrade);
    } on PostgrestException catch (e) {
      if (!context.mounted) return;
      if (e.code == '23505') {
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            title: Text('Errore'),
            description: Text('Voto già inserito.'),
          ),
        );
      } else {
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            title: Text('Errore'),
            description: Text('Impossibile salvare l\'esame.'),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Errore'),
          description: Text('Impossibile salvare l\'esame.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingDialog = false);
    }
  }

  Future<void> _addPartialGrade(BuildContext dialogContext) async {
    final parentName = _parentExamNameController.text.trim();
    final partialName = _partialNameController.text.trim();
    final valueStr = _partialValueController.text.trim();
    final weightStr = _partialWeightController.text.trim();

    if (parentName.isEmpty ||
        partialName.isEmpty ||
        valueStr.isEmpty ||
        weightStr.isEmpty) {
      if (context.mounted) {
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            title: Text('Errore'),
            description: Text('Compila tutti i campi.'),
          ),
        );
      }
      return;
    }


    final value = double.tryParse(valueStr);
    final weight = int.tryParse(weightStr);

    if (value == null || weight == null || weight <= 0 || weight > 100 || value>30) {
      if (context.mounted) {
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            title: Text('Errore'),
            description: Text('Valori numerici non validi.'),
          ),
        );
      }
      return;
    }

    final navigator = Navigator.of(dialogContext);

    setState(() => _isLoadingDialog = true);
    try {
      final parentId = await apiClient.getParentGradeIdByName(parentName);
      if (parentId == null) {
        if (!mounted) return;
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            title: Text('Errore'),
            description: Text('Esame completo non trovato.'),
          ),
        );
        setState(() => _isLoadingDialog = false);
        return;
      }

      final existingWeightSum = await apiClient.getTotalWeightForParent(
        parentId,
      );
      if (existingWeightSum + weight > 100) {
        if (!mounted) return;
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Errore'),
            description: Text(
              'Il peso totale supera il 100%. Attuale: $existingWeightSum%.',
            ),
          ),
        );
        setState(() => _isLoadingDialog = false);
        return;
      }

      await apiClient.addGrade(
        examName: partialName,
        value: value,
        weight: weight,
        isPartial: true,
        parentGradeID: parentId,
        isCompleted: false,
      ).then((newPartial) {
        widget.onGradeAdded(newPartial);
      });

      if (existingWeightSum + weight == 100) {
        await apiClient.updateGradeCompleted(parentId);
        widget.onGradeCompletionChanged(parentId, true);
      }

      if (!mounted) return;
      navigator.pop();
    } on PostgrestException catch (e) {
      if (!context.mounted) return;
      if (e.code == '23505') {
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            title: Text('Errore'),
            description: Text('Voto parziale già inserito.'),
          ),
        );
      } else {
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            title: Text('Errore'),
            description: Text('Impossibile salvare il parziale.'),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Errore'),
          description: Text('Impossibile salvare il parziale.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingDialog = false);
    }
  }

  Future<void> _deleteGrade(int gradeID) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            title: const Text(
              'Elimina Voto',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Sei sicuro di voler eliminare questo voto?',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Annulla',
                  style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Elimina',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      Grade deleted=await apiClient.deleteGrade(gradeID: gradeID);

      /*deleted o parentGradeID possono essere null solo se c'è stato un errore nell'inserimento di un voto parziale
        o un errore nella cancellazione (in entrambi i casi presi dal try catch in api_client)
       */
      if(deleted.isPartial&&deleted.parentGradeID!=null){
        int weightSum=await apiClient.getTotalWeightForParent(deleted.parentGradeID!);
        if(weightSum<100){
          await apiClient.updateGradeNotCompleted(deleted.parentGradeID!);
          widget.onGradeCompletionChanged(deleted.parentGradeID!, false);
        }
      }
      widget.onGradeDeleted(gradeID);
    } catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Errore'),
          description: Text('Impossibile eliminare il voto.'),
        ),
      );
    }
  }

  //dialog valido sia per l'inserimento che l'edit di voti completi/padri
  void _showGradeDialog({Grade? grade}) {
    if(grade!=null){
      _examNameController.text=grade.examName;
      _valueController.text=grade.value?.toStringAsFixed(0) ?? '';
      _cfuController.text=grade.cfu?.toString() ?? '';
      _hasPartials=grade.isPartial;
    }else{
      _examNameController.clear();
      _valueController.clear();
      _cfuController.clear();
      _hasPartials=false;
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
                          Expanded(
                            child: Text(
                              grade==null?'Aggiungi voto':'Modifica voto',
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
                      Text(
                        grade==null?'Inserisci i dati dell\'esame.':'Modifica i dati dell\'esame',
                        style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            const Text(
                              'Nome Esame',
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            ShadInput(
                              controller: _examNameController,
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
                            if(grade==null) ...[
                              const SizedBox(height: 16,),
                              ShadCheckbox(
                                value: _hasPartials,
                                onChanged:
                                    (v) => setDialogState(() => _hasPartials = v),
                                label: const Text('Esame composto da parziali'),
                              ),
                            ],
                            if (!_hasPartials) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Voto (in trentesimi)',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              ShadInput(
                                controller: _valueController,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
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
                            const SizedBox(height: 16),
                            const Text(
                              'CFU',
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            ShadInput(
                              controller: _cfuController,
                              keyboardType: TextInputType.number,
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
                            onPressed:
                                _isLoadingDialog?null:
                                    grade!=null?()=>_editNormalOrParentGrade(dialogContext, grade):
                                    ()=>_addNormalOrParentGrade(dialogContext),
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

  Future<void> _editNormalOrParentGrade(
    BuildContext dialogContext,
    Grade grade,
  ) async {
    final name = _examNameController.text.trim();
    final cfuStr = _cfuController.text.trim();
    final valueStr = _valueController.text.trim();

    if (name.isEmpty || cfuStr.isEmpty || (!_hasPartials && valueStr.isEmpty)) {
      if (context.mounted) {
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            title: Text('Errore'),
            description: Text('Compila i campi necessari.'),
          ),
        );
      }
      return;
    }

    final cfu = int.tryParse(cfuStr);
    if (cfu == null) {
      if (context.mounted) {
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            title: Text('Errore'),
            description: Text('CFU deve essere un numero.'),
          ),
        );
      }
      return;
    }

    double? value;
    if (!_hasPartials) {
      value = double.tryParse(valueStr);
      if (value == null) {
        if (context.mounted) {
          ShadToaster.of(context).show(
            const ShadToast.destructive(
              title: Text('Errore'),
              description: Text('Il voto deve essere un numero.'),
            ),
          );
        }
        return;
      }
    }

    final navigator = Navigator.of(dialogContext);

    setState(() => _isLoadingDialog = true);
    try {
      await apiClient.updateGrade(
        gradeID: grade.gradeID,
        examName: name,
        cfu: cfu,
        value: value,
      );
      if (!mounted) return;
      navigator.pop();
      final updatedGrade = Grade(
        gradeID: grade.gradeID,
        userID: grade.userID,
        examName: name,
        value: value,
        isPartial: grade.isPartial,
        parentGradeID: grade.parentGradeID,
        isCompleted: grade.isCompleted,
        weight: grade.weight,
      );
      updatedGrade.cfu = cfu;
      widget.onGradeUpdated(grade.gradeID, updatedGrade);
    } on PostgrestException catch (e) {
      if (!context.mounted) return;
      if (e.code == '23505') {
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            title: Text('Errore'),
            description: Text('Voto già inserito.'),
          ),
        );
      } else {
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            title: Text('Errore'),
            description: Text('Impossibile modificare l\'esame.'),
          ),
        );
      }
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


  //dialog valido sia per l'inserimento che l'edit di voti parziali
  void _showPartialDialog({Grade? partial, String? prefilledParentName}) {
    if(partial!=null){
      _partialNameController.text=partial.examName;
      _partialValueController.text=partial.value?.toStringAsFixed(0)??'';
      _partialWeightController.text=partial.weight?.toString()??'';
    }else{
      _partialNameController.clear();
      _parentExamNameController.text=prefilledParentName!; //nelle chiamate che faccio sono sicuro che non sia null
      _partialValueController.clear();
      _partialWeightController.clear();
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
                          Expanded(
                            child: Text(
                              partial==null?'Aggiungi parziale':'Modifica parziale',
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
                      Text(
                        partial==null?'Modifica i dati del parziale.':'Inserisci i dati del parziale',
                        style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),

                              const Text(
                                'Nome Parziale',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              ShadInput(
                                controller: _partialNameController,
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
                                'Voto',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              ShadInput(
                                controller: _partialValueController,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
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
                                'Peso (%)',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              ShadInput(
                                controller: _partialWeightController,
                                placeholder: const Text('es. 50 per il 50%'),
                                keyboardType: TextInputType.number,
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
                            onPressed:
                                _isLoadingDialog?null:
                                    partial!=null?()=>_editPartialGrade(dialogContext, partial):
                                    ()=>_addPartialGrade(dialogContext),
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

  Future<void> _editPartialGrade(
    BuildContext dialogContext,
    Grade partial,
  ) async {
    final partialName = _partialNameController.text.trim();
    final valueStr = _partialValueController.text.trim();
    final weightStr = _partialWeightController.text.trim();

    if (partialName.isEmpty || valueStr.isEmpty || weightStr.isEmpty) {
      if (context.mounted) {
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            title: Text('Errore'),
            description: Text('Compila tutti i campi.'),
          ),
        );
      }
      return;
    }

    final value = double.tryParse(valueStr);
    final weight = int.tryParse(weightStr);

    if (value == null || weight == null || weight <= 0 || weight > 100) {
      if (context.mounted) {
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            title: Text('Errore'),
            description: Text('Valori numerici non validi.'),
          ),
        );
      }
      return;
    }

    final navigator = Navigator.of(dialogContext);

    setState(() => _isLoadingDialog = true);
    try {
      final existingWeightSum =
          partial.parentGradeID != null
              ? await apiClient.getTotalWeightForParent(partial.parentGradeID!)
              : 0;

      final oldWeight = partial.weight ?? 0;
      if (existingWeightSum - oldWeight + weight > 100) {
        if (!mounted) return;
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Errore'),
            description: Text('Il peso totale supera il 100%.'),
          ),
        );
        setState(() => _isLoadingDialog = false);
        return;
      }

      await apiClient.updateGrade(
        gradeID: partial.gradeID,
        examName: partialName,
        value: value,
        weight: weight,
      );

      if (partial.parentGradeID != null &&
          existingWeightSum - oldWeight + weight == 100) {
        await apiClient.updateGradeCompleted(partial.parentGradeID!);
        widget.onGradeCompletionChanged(partial.parentGradeID!, true);
      }else if(partial.parentGradeID!=null&&existingWeightSum==100&&
                existingWeightSum-oldWeight+weight<100){
        await apiClient.updateGradeNotCompleted(partial.parentGradeID!);
        widget.onGradeCompletionChanged(partial.parentGradeID!, false);
      }

      if (!mounted) return;
      navigator.pop();
      final updatedPartial = Grade(
        gradeID: partial.gradeID,
        userID: partial.userID,
        examName: partialName,
        value: value,
        isPartial: true,
        parentGradeID: partial.parentGradeID,
        isCompleted: partial.isCompleted,
        weight: weight,
      );
      widget.onGradeUpdated(partial.gradeID, updatedPartial);
    } on PostgrestException catch (e) {
      if (!context.mounted) return;
      if (e.code == '23505') {
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            title: Text('Errore'),
            description: Text('Voto parziale già inserito.'),
          ),
        );
      } else {
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            title: Text('Errore'),
            description: Text('Impossibile modificare il parziale.'),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Errore'),
          description: Text('Impossibile modificare il parziale.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingDialog = false);
    }
  }

  Widget _buildAverageCircle(double avg) {
    final percentage = (avg / 30.0).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: SizedBox(
        width: 140,
        height: 140,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1A1A1A),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _AverageCirclePainter(
                  percentage: percentage,
                  activeColor: const Color(0xFF4CAF50),
                  inactiveColor: const Color(0xFF333333),
                  strokeWidth: 8,
                ),
              ),
            ),
            if (avg > 0)
              Container(
                decoration: const BoxDecoration(shape: BoxShape.circle),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'MEDIA',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  avg == 0.0 ? '--/30' : '${avg.toStringAsFixed(1)}/30',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
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

  Widget _buildParentGradeCard(Grade parent) {
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
          iconColor: Colors.white70,
          collapsedIconColor: Colors.white70,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  parent.examName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          (parent.isCompleted ?? false)
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (parent.isCompleted ?? false) ? 'Completato' : 'In corso',
                      style: TextStyle(
                        color:
                            (parent.isCompleted ?? false)
                                ? Colors.green
                                : Colors.amber,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  ...[
                    _buildPopUpMenu(context, ()=>_showGradeDialog(grade: parent), ()=>_deleteGrade(parent.gradeID)),
                  ],
                ],
              ),
            ],
          ),
          subtitle: Text(
            '${parent.cfu} CFU',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          children: [
            Builder(
              builder: (context) {
                final partials = widget.grades.where((g) => g.parentGradeID == parent.gradeID).toList();
                return Column(
                  children: [
                    ...partials.map(
                      (p) => ListTile(
                        title: Text(
                          p.examName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Voto: ${p.value} (${p.weight}%)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ...[
                              _buildPopUpMenu(context, ()=>_showPartialDialog(partial: p), ()=>_deleteGrade(p.gradeID))
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (!(parent.isCompleted ?? false))
                      GestureDetector(
                        onTap: () => _showPartialDialog(prefilledParentName: parent.examName),
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
                                'Aggiungi parziale',
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalGradeCard(Grade grade) {
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
            grade.examName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '${grade.cfu} CFU',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF333333),
                ),
                child: Text(
                  grade.value?.toStringAsFixed(0) ?? '--',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ...[
                _buildPopUpMenu(context, ()=>_showGradeDialog(grade: grade), ()=>_deleteGrade(grade.gradeID))
              ],
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final allGrades = widget.grades;
    final parentGrades =
        allGrades.where((g) => g.parentGradeID == null).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
            'Voti Registrati',
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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildAverageCircle(widget.average),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index == parentGrades.length) {
                  return GestureDetector(
                    onTap: () => _showGradeDialog(),
                    child: Card(
                      color: const Color(0xFF1A1A1A),
                      margin: EdgeInsets.only(bottom: parentGrades.isEmpty ? 0 : 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.white54),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'Aggiungi voto',
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

                final grade = parentGrades[index];
                if (grade.isPartial) {
                  return _buildParentGradeCard(
                    grade,
                  );
                }
                return _buildNormalGradeCard(grade);
              }, childCount: parentGrades.length + 1),
            ),
          ),
        ],
      ),
    );
  }
}

class _AverageCirclePainter extends CustomPainter {
  final double percentage;
  final Color activeColor;
  final Color inactiveColor;
  final double strokeWidth;

  _AverageCirclePainter({
    required this.percentage,
    required this.activeColor,
    required this.inactiveColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final Paint backgroundPaint =
        Paint()
          ..color = inactiveColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    if (percentage > 0) {
      final Paint foregroundPaint =
          Paint()
            ..color = activeColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.1415926535897932 / 2,
        (percentage * 2 * 3.1415926535897932),
        false,
        foregroundPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AverageCirclePainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
