import 'package:flutter/material.dart';
import 'package:unilife/login_page.dart';
import 'package:unilife/main.dart';
import 'grades_tab.dart';
import 'exams_tab.dart';
import 'classes_tab.dart';
import 'model/grade.dart';
import 'model/exam.dart';
import 'model/class.dart';
import 'model/user_model.dart';

class HomePage extends StatefulWidget {
  final UserModel activeUser;

  const HomePage({
    super.key,
    required this.activeUser,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  bool _isLoading = true;

  List<Grade> _grades = [];
  List<Exam> _exams = [];
  List<Class> _classes = [];
  double _average = 0.0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      List<Grade> grades=await apiClient.fetchGrades();
      List<Exam> exams=await apiClient.fetchExams();
      List<Class> classes=await apiClient.fetchClasses();
      double avg=await apiClient.computeAvg();

      if (!mounted) return;
      setState(() {
        _grades = grades;
        _exams = exams;
        _classes = classes;
        _average = avg;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  //ho preferito gestire gli state delle tabs nella home per essere il più pulito possibile

  void _onGradeAdded(Grade grade) {
    setState(() => _grades.add(grade));
    _refreshAverage();
  }

  void _onGradeUpdated(int gradeID, Grade updatedGrade) {
    setState(() {
      /*
        se il voto che ho aggiornato è presente allora lo modifico con il nuovo voto deserializzato,
        questo vale per tutte le funzioni di update
       */
      final index = _grades.indexWhere((g) => g.gradeID == gradeID);
      if (index != -1) _grades[index] = updatedGrade;
    });
    _refreshAverage();
  }

  void _onGradeDeleted(int gradeID) {
    setState(() => _grades.removeWhere((g) => g.gradeID == gradeID));
    _refreshAverage();
  }

  void _onGradeCompletionChanged(int gradeID, bool isCompleted) {
    setState(() {
      final index = _grades.indexWhere((g) => g.gradeID == gradeID);
      if (index != -1) _grades[index].isCompleted = isCompleted;
    });
    _refreshAverage();
  }

  Future<void> _refreshAverage() async {
    try {
      final avg = await apiClient.computeAvg();
      if (!mounted) return;
      setState(() => _average = avg);
    } catch (_) {}
  }

  void _onExamAdded(Exam exam) {
    setState(() => _exams.add(exam));
  }

  void _onExamUpdated(int examID, Exam updatedExam) {
    setState(() {
      final index = _exams.indexWhere((e) => e.examID == examID);
      if (index != -1) _exams[index] = updatedExam;
    });
  }

  void _onExamDeleted(int examID) {
    setState(() => _exams.removeWhere((e) => e.examID == examID));
  }

  void _onClassAdded(Class cls) {
    setState(() => _classes.add(cls));
  }

  void _onClassUpdated(int classID, Class updatedClass) {
    setState(() {
      final index = _classes.indexWhere((c) => c.classID == classID);
      if (index != -1) _classes[index] = updatedClass;
    });
  }

  void _onClassDeleted(int classID) {
    setState(() => _classes.removeWhere((c) => c.classID == classID));
  }

  //metodo di logout per tutte le tab
  Future<void> _signOut() async {
    setState(()=>_isLoading=true);

    try{
      await apiClient.signOutUser();
      if(!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_)=>const LoginPage()),
      );
    }catch(_){ }finally{
      setState(()=>_isLoading=false);
    }
  }

  //metodi per il mettere il drawer in tutte le tabs

  Widget _createHeader() {
    return Container(
        height: 80,
        color: Color(0xFF1A1A1A),
        child: ListTile(
          title: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
                widget.activeUser.email,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          subtitle: Text(
              widget.activeUser.name1,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              )
          ),
          dense: true,
          leading: CircleAvatar(child: Icon(Icons.person)),
        )
    );
  }

  Widget _createDrawerItem(
      {required IconData icon,
        required String text,
        required GestureTapCallback onTap}) {
    return ListTile(
      title: Row(
        children: [
          Icon(icon),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16
              ),
            ),
          )
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildDrawer(){
    return Drawer(
      backgroundColor: const Color(0xFF1A1A1A),
      child: ListView(
        children: [
          SizedBox(
            height: 32,
          ),
          _createHeader(),
          SizedBox(
            height: 16,
          ),
          Divider(
            color: Colors.white54,
            thickness: 0.0,
          ),

          _createDrawerItem(icon: Icons.settings, text: "Impostazioni", onTap: ()=>0),
          Divider(
            indent: 12,
            endIndent: 12,
            color: Colors.white54,
            thickness: 0.0,
          ),
          _createDrawerItem(icon: Icons.logout, text: "Logout", onTap: ()=>_signOut()),
          Divider(
            indent: 12,
            endIndent: 12,
            color: Colors.white54,
            thickness: 0.0,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final tabs = [
      GradesTab(
        grades: _grades,
        average: _average,
        onGradeAdded: _onGradeAdded,
        onGradeUpdated: _onGradeUpdated,
        onGradeDeleted: _onGradeDeleted,
        onGradeCompletionChanged: _onGradeCompletionChanged,
        drawerWidget: _buildDrawer(),
      ),
      ExamsTab(
        exams: _exams,
        onExamAdded: _onExamAdded,
        onExamUpdated: _onExamUpdated,
        onExamDeleted: _onExamDeleted,
        drawerWidget: _buildDrawer(),
      ),
      ClassesTab(
        classes: _classes,
        onClassAdded: _onClassAdded,
        onClassUpdated: _onClassUpdated,
        onClassDeleted: _onClassDeleted,
        drawerWidget: _buildDrawer(),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: tabs[_currentIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF232323),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white54,
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.school_outlined),
              activeIcon: Icon(Icons.school),
              label: 'Voti',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Esami',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.view_agenda_outlined),
              activeIcon: Icon(Icons.view_agenda),
              label: 'Lezioni',
            ),
          ],
        ),
      ),
    );
  }
}
