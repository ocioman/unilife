class InvalidEmailException implements Exception {
  final String message;
  const InvalidEmailException(this.message);
  @override
  String toString()=>message;
}
