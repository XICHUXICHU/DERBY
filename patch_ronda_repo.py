import sys

file_path = 'lib/data/repositories/ronda_repository.dart'
with open(file_path, 'r') as f:
    content = f.read()

new_method = """
  /// Mueve un enfrentamiento a otra ronda y cambia sus gallos.
  Future<void> moverYActualizarEnfrentamiento(
    int enfrentamientoId,
    int nuevaRondaId,
    int nuevoGalloAId,
    int nuevoGalloBId,
    double nuevaDiferenciaPeso,
  ) async {
    await (_db.update(_db.enfrentamientos)..where((e) => e.id.equals(enfrentamientoId)))
        .write(
      EnfrentamientosCompanion(
        rondaId: Value(nuevaRondaId),
        galloAId: Value(nuevoGalloAId),
        galloBId: Value(nuevoGalloBId),
        diferenciaPeso: Value(nuevaDiferenciaPeso),
        resultado: const Value(null),
      ),
    );
  }
"""

if "moverYActualizarEnfrentamiento(" not in content:
    content = content.replace('Future<void> actualizarGallosEnfrentamiento', new_method + '\n  Future<void> actualizarGallosEnfrentamiento')
    with open(file_path, 'w') asimport sys

file_path = 'lib/data/ri
file_pated with open(file_path,
    print("Already patched")
