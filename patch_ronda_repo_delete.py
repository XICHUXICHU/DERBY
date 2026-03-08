import sys

file_path = 'lib/data/repositories/ronda_repository.dart'
with open(file_path, 'r') as f:
    content = f.read()

new_method = """
  /// Eliminar enfrentamiento.
  Future<void> eliminarEnfrentamiento(int enfrentamientoId) async {
    await (_db.delete(_db.enfrentamientos)..where((e) => e.id.equals(enfrentamientoId))).go();
  }
"""

if "eliminarEnfrentamiento(" not in content:
    content = content.replace('Future<void> eliminarPorDerby(int derbyId) async {', new_method + '\n  Future<void> eliminarPorDerby(int derbyId) async {')
    with open(file_path, 'w') as f:
        f.write(content)
    print("Patched " + file_path)
else:
    print("Already patched")
