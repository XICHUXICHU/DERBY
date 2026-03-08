import 'package:derby2_flutter/domain/domain.dart';
import 'package:derby2_flutter/engine/derby_engine.dart';
import 'package:derby2_flutter/application/usecases/generar_sorteo.dart';

void main() {
  final engine = DerbyEngine(compadres: [],
    config: DerbyConfig(
      rondasTotales: 3,
      pesoMinimo: 1900,
      pesoMaximo: 2600,
      pesoGalloBase: 2100,
      permitirRepeticiones: true,
      diferenciaMaxPeso: 500,
    ),
  );
  
  final usecase = GenerarSorteo(engine);
  
  final partidos = List.generate(21, (i) => Partido(id: i + 1, nombre: 'P${i+1}'));
  final compadres = <Compadres>[];
  
  int galloId = 1;
  final gallos = <Gallo>[];
  for (var p in partidos) {
    // 3 PL, 1 Base
    for(int i=0; i<3; i++) {
        gallos.add(Gallo(id: galloId++, partidoId: p.id, pesoGramos: 2000.0 + (i * 100), esBase: false, numeroAnillo: 'PL${i}'));
    }
    gallos.add(Gallo(id: galloId++, partidoId: p.id, pesoGramos: 2100, esBase: true, numeroAnillo: 'BASE'));
  }
  
  // Vamos a promover el gallo base del partido 1
  final galloExtId = gallos.firstWhere((g) => g.partidoId == 1 && g.esBase).id;
  
  print('Iniciando sorteo con 21 partidos');
  final rondas = usecase.ejecutarTodas(
    partidos: partidos,
    gallos: gallos,
    compadres: compadres,
    partidoDoblePreferidoId: 1, // Preferimos el P1 porque donó el gallo
    galloBasePromovidoId: galloExtId,
  );
  
  print('Sorteo finalizado. Rondas: ${rondas.length}');
  int totalPeleas = 0;
  for (var r in rondas) {
     totalPeleas += r.enfrentamientos.length;
     print('Ronda ${r.numero}: ${r.enfrentamientos.length} peleas, excluidos: ${r.partidosBye}');
  }
  print('Total peleas: $totalPeleas (esperadas 32 = 64 gallos / 2)');
}
