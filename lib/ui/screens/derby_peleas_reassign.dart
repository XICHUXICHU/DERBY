import 'package:flutter/material.dart';
import '../../domain/domain.dart';

class DerbyPeleasReassignScreen extends StatefulWidget {
  final List<Ronda> rondasOriginales;
  final List<Partido> partidos;
  final List<Gallo> gallos;
  final List<Compadres> compadres;
  final double diferenciaMaxPeso;

  const DerbyPeleasReassignScreen({
    super.key,
    required this.rondasOriginales,
    required this.partidos,
    required this.gallos,
    required this.compadres,
    required this.diferenciaMaxPeso,
  });

  @override
  State<DerbyPeleasReassignScreen> createState() =>
      _DerbyPeleasReassignScreenState();
}

class _DerbyPeleasReassignScreenState extends State<DerbyPeleasReassignScreen> {
  late List<Ronda> _rondas;

  @override
  void initState() {
    super.initState();
    _rondas = widget.rondasOriginales.map<Ronda>((r) {
      return Ronda(
        numero: r.numero,
        enfrentamientos: List.from(r.enfrentamientos),
      );
    }).toList();
  }

  bool _esInvalido(Enfrentamiento e) {
    if (e.galloB == null) return false; // si es huérfano en teoría no es "inválido", es incompleto
    if (e.galloA.partidoId == e.galloB!.partidoId) return true;
    if (widget.diferenciaMaxPeso > 0 &&
        e.galloA.diferenciaAbsoluta(e.galloB!) > widget.diferenciaMaxPeso) {
      return true;
    }
    for (var c in widget.compadres) {
      if ((c.partidoIdA == e.galloA.partidoId &&
              c.partidoIdB == e.galloB!.partidoId) ||
          (c.partidoIdA == e.galloB!.partidoId &&
              c.partidoIdB == e.galloA.partidoId)) {
        return true;
      }
    }
    return false;
  }

  void _intercambiarGallos(
    int rondaOrigenIdx,
    int rondaDestinoIdx,
    int enfOrigenIdx,
    int enfDestinoIdx,
    bool moverGalloBOrigen,
    bool moverGalloBDestino,
  ) {
    setState(() {
      final rondaOrigen = _rondas[rondaOrigenIdx];
      final rondaDestino = _rondas[rondaDestinoIdx];
      
      final enfOrigen = rondaOrigen.enfrentamientos[enfOrigenIdx];
      final enfDestino = rondaDestino.enfrentamientos[enfDestinoIdx];

      final galloOrigen = moverGalloBOrigen ? enfOrigen.galloB : enfOrigen.galloA;
      final galloDestino = moverGalloBDestino ? enfDestino.galloB : enfDestino.galloA;

      Gallo? aOrig = moverGalloBOrigen ? enfOrigen.galloA : galloDestino;
      Gallo? bOrig = !moverGalloBOrigen ? enfOrigen.galloB : galloDestino;

      Gallo? aDest = moverGalloBDestino ? enfDestino.galloA : galloOrigen;
      Gallo? bDest = !moverGalloBDestino ? enfDestino.galloB : galloOrigen;

      // Normalizar: galloA no puede ser null en un enfrentamiento vivo
      if (aOrig == null && bOrig != null) {
        aOrig = bOrig;
        bOrig = null;
      }
      if (aDest == null && bDest != null) {
        aDest = bDest;
        bDest = null;
      }

      // Reconstruir origen
      final nuevaListaOrigen = <Enfrentamiento>[];
      for (int i = 0; i < rondaOrigen.enfrentamientos.length; i++) {
        if (i == enfOrigenIdx) {
          if (aOrig != null) {
            nuevaListaOrigen.add(Enfrentamiento(
              id: enfOrigen.id,
              rondaNumero: enfOrigen.rondaNumero,
              galloA: aOrig,
              galloB: bOrig,
              diferenciaPeso: bOrig != null ? aOrig.diferenciaAbsoluta(bOrig) : 0,
            ));
          }
        } else if (rondaOrigenIdx == rondaDestinoIdx && i == enfDestinoIdx) {
          if (aDest != null) {
            nuevaListaOrigen.add(Enfrentamiento(
              id: enfDestino.id,
              rondaNumero: enfDestino.rondaNumero,
              galloA: aDest,
              galloB: bDest,
              diferenciaPeso: bDest != null ? aDest.diferenciaAbsoluta(bDest) : 0,
            ));
          }
        } else {
          nuevaListaOrigen.add(rondaOrigen.enfrentamientos[i]);
        }
      }

      // Reconstruir destino sólo si es de otra ronda
      if (rondaOrigenIdx != rondaDestinoIdx) {
        final nuevaListaDestino = <Enfrentamiento>[];
        for (int i = 0; i < rondaDestino.enfrentamientos.length; i++) {
          if (i == enfDestinoIdx) {
            if (aDest != null) {
              nuevaListaDestino.add(Enfrentamiento(
                id: enfDestino.id,
                rondaNumero: enfDestino.rondaNumero,
                galloA: aDest,
                galloB: bDest,
                diferenciaPeso: bDest != null ? aDest.diferenciaAbsoluta(bDest) : 0,
              ));
            }
          } else {
            nuevaListaDestino.add(rondaDestino.enfrentamientos[i]);
          }
        }
        rondaDestino.enfrentamientos.clear();
        rondaDestino.enfrentamientos.addAll(nuevaListaDestino);
      }

      rondaOrigen.enfrentamientos.clear();
      rondaOrigen.enfrentamientos.addAll(nuevaListaOrigen);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor Manual de Sorteo'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text(
              'GUARDAR CAMBIOS',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              // Limpiar huecos nulos sin comprimir/eliminar rondas, 
              // para mantener la distribución manual (1 pelea por ronda cuando sea posible)
              final rondasLimpias = <Ronda>[];

              for (final ronda in _rondas) {
                // Eliminar enfrentamientos donde galloB es nulo (Huecos no llenados)
                final peleasCompletas = ronda.enfrentamientos
                    .where((e) => e.galloB != null)
                    .toList();

                final peleasFinales = <Enfrentamiento>[];
                for (final p in peleasCompletas) {
                  peleasFinales.add(
                    p.conResultado(p.resultado ?? ResultadoPelea.noPeleada),
                  );
                }

                rondasLimpias.add(Ronda(
                  numero: ronda.numero, // Mantenemos su número original (no subimos ni comprimimos)
                  enfrentamientos: peleasFinales,
                  esRondaBase: ronda.esRondaBase,
                  fechaCreacion: ronda.fechaCreacion,
                  partidosBye: ronda.partidosBye,
                  partidosDobles: ronda.partidosDobles,
                ));
              }

              Navigator.pop(context, rondasLimpias);
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      backgroundColor: Colors.grey.shade100,
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rondas.length,
        itemBuilder: (context, rondaIdx) {
          final ronda = _rondas[rondaIdx];
          return _buildRondaBoard(ronda, rondaIdx, cs);
        },
      ),
    );
  }

  Widget _buildRondaBoard(Ronda ronda, int rondaIdx, ColorScheme cs) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sports_mma, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'RONDA ${ronda.numero}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: List.generate(ronda.enfrentamientos.length, (enfIdx) {
                final e = ronda.enfrentamientos[enfIdx];
                final flagError = _esInvalido(e);
                final diff = e.diferenciaPeso;

                return Container(
                  width: 340,
                  decoration: BoxDecoration(
                    color: flagError ? Colors.red.shade50 : Colors.white,
                    border: Border.all(
                      color: flagError
                          ? Colors.red.shade400
                          : Colors.grey.shade300,
                      width: flagError ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      if (flagError)
                        BoxShadow(
                          color: Colors.red.withOpacity(0.1),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDraggableGallo(
                            e.galloA,
                            rondaIdx,
                            enfIdx,
                            false,
                            cs,
                          ),
                          Text(
                            'VS',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          if (e.galloB != null)
                            _buildDraggableGallo(
                              e.galloB!,
                              rondaIdx,
                              enfIdx,
                              true,
                              cs,
                            )
                          else
                            DragTarget<Map<String, dynamic>>(
                              onWillAcceptWithDetails: (details) => true,
                              onAcceptWithDetails: (details) {
                                final data = details.data;
                                _intercambiarGallos(
                                  data['rondaIdx'],
                                  rondaIdx,
                                  data['enfIdx'],
                                  enfIdx,
                                  data['isGalloB'],
                                  true, // target is Gallo B (empty)
                                );
                              },
                              builder: (context, candidateData, rejectedData) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: candidateData.isNotEmpty ? Colors.blue.withOpacity(0.2) : Colors.orange.withOpacity(0.1),
                                    border: Border.all(
                                      color: candidateData.isNotEmpty ? Colors.blue : Colors.orange,
                                      style: BorderStyle.solid,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    "ESPACIO VACÍO\n(Arrastra aquí)",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: flagError
                              ? Colors.red.shade100
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Diferencia: ${diff.toStringAsFixed(0)}g',
                          style: TextStyle(
                            fontSize: 12,
                            color: flagError
                                ? Colors.red.shade900
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableGallo(
    Gallo gallo,
    int rondaIdx,
    int enfIdx,
    bool isGalloB,
    ColorScheme cs,
  ) {
    final Map<String, dynamic> dragData = {
      'rondaIdx': rondaIdx,
      'enfIdx': enfIdx,
      'isGalloB': isGalloB,
    };

    final nombrePartido = widget.partidos
        .firstWhere(
          (p) => p.id == gallo.partidoId,
          orElse: () => const Partido(id: -1, nombre: '?'),
        )
        .nombre;

    final childWidget = Container(
      width: 130,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.primary.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isGalloB ? cs.secondaryContainer : cs.primaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              gallo.anillo,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isGalloB
                    ? cs.onSecondaryContainer
                    : cs.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${gallo.pesoGramos}g',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            nombrePartido,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade700,
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        return data['rondaIdx'] == rondaIdx &&
                data['enfIdx'] == enfIdx &&
                data['isGalloB'] == isGalloB
            ? false
            : true;
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        _intercambiarGallos(
          data['rondaIdx'],
          rondaIdx,
          data['enfIdx'],
          enfIdx,
          data['isGalloB'],
          isGalloB,
        );
      },
      builder: (context, candidateData, rejectedData) {
        return Draggable<Map<String, dynamic>>(
          data: dragData,
          feedback: Opacity(
            opacity: 0.8,
            child: Material(
              color: Colors.transparent,
              child: Transform.scale(scale: 1.05, child: childWidget),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: childWidget),
          child: Container(
            decoration: candidateData.isNotEmpty
                ? BoxDecoration(
                    border: Border.all(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: childWidget,
          ),
        );
      },
    );
  }
}
