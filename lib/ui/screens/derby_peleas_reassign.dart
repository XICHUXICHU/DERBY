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
    if (e.galloA.partidoId == e.galloB.partidoId) return true;
    if (widget.diferenciaMaxPeso > 0 &&
        e.galloA.diferenciaAbsoluta(e.galloB) > widget.diferenciaMaxPeso) {
      return true;
    }
    for (var c in widget.compadres) {
      if ((c.partidoIdA == e.galloA.partidoId &&
              c.partidoIdB == e.galloB.partidoId) ||
          (c.partidoIdA == e.galloB.partidoId &&
              c.partidoIdB == e.galloA.partidoId)) {
        return true;
      }
    }
    return false;
  }

  void _intercambiarGallos(
    int rondaIdx,
    int enfOrigenIdx,
    int enfDestinoIdx,
    bool moverGalloBOrigen,
    bool moverGalloBDestino,
  ) {
    setState(() {
      final ronda = _rondas[rondaIdx];
      final enfOrigen = ronda.enfrentamientos[enfOrigenIdx];
      final enfDestino = ronda.enfrentamientos[enfDestinoIdx];

      final gAOrigenNuevo = moverGalloBOrigen
          ? enfOrigen.galloA
          : (moverGalloBDestino ? enfDestino.galloB : enfDestino.galloA);
      final gBOrigenNuevo = !moverGalloBOrigen
          ? enfOrigen.galloB
          : (moverGalloBDestino ? enfDestino.galloB : enfDestino.galloA);

      final gADestNuevo = moverGalloBDestino
          ? enfDestino.galloA
          : (moverGalloBOrigen ? enfOrigen.galloB : enfOrigen.galloA);
      final gBDestNuevo = !moverGalloBDestino
          ? enfDestino.galloB
          : (moverGalloBOrigen ? enfOrigen.galloB : enfOrigen.galloA);

      ronda.enfrentamientos[enfOrigenIdx] = Enfrentamiento(
        id: enfOrigen.id,
        rondaNumero: enfOrigen.rondaNumero,
        galloA: gAOrigenNuevo,
        galloB: gBOrigenNuevo,
        diferenciaPeso: gAOrigenNuevo.diferenciaAbsoluta(gBOrigenNuevo),
      );

      ronda.enfrentamientos[enfDestinoIdx] = Enfrentamiento(
        id: enfDestino.id,
        rondaNumero: enfDestino.rondaNumero,
        galloA: gADestNuevo,
        galloB: gBDestNuevo,
        diferenciaPeso: gADestNuevo.diferenciaAbsoluta(gBDestNuevo),
      );
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
              Navigator.pop(context, _rondas);
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
                          _buildDraggableGallo(
                            e.galloB,
                            rondaIdx,
                            enfIdx,
                            true,
                            cs,
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
