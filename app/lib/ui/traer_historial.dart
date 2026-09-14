import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config.dart';
import '../data/db/app_database.dart';
import '../data/visita_repository.dart';
import '../state/historial.dart';
import '../state/providers.dart';
import '../state/red.dart';

/// Traer de Airtable las visitas ya registradas de un agricultor.
///
/// Se abre a proposito y se pide POR PERSONA, no «todas»: bajarle a un
/// telefono de campo el historial del equipo entero mueve datos personales de
/// productores a dispositivos que no los registraron, y ademas no cabe — cada
/// visita trae sus fotos y su audio.
///
/// Lo que baja es un ESPEJO DE CONSULTA. No se edita ni se vuelve a subir, y
/// una visita que ya esta en este telefono no se toca: ahi el telefono es la
/// fuente de verdad, porque es donde se registro.
Future<void> abrirTraerHistorial(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _TraerHistorial(),
  );
}

class _TraerHistorial extends ConsumerStatefulWidget {
  const _TraerHistorial();

  @override
  ConsumerState<_TraerHistorial> createState() => _TraerHistorialState();
}

class _TraerHistorialState extends ConsumerState<_TraerHistorial> {
  final _busqueda = TextEditingController();
  List<Productor> _resultados = const [];
  bool _buscando = false;

  @override
  void initState() {
    super.initState();
    _buscar('');
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  /// Busca en el directorio LOCAL, no en Airtable.
  ///
  /// El directorio ya se baja al crear una visita y vive en el telefono. Ir a
  /// la red para escribir un nombre convertiria una pantalla que funciona sin
  /// senal en una que no.
  Future<void> _buscar(String texto) async {
    setState(() => _buscando = true);
    final encontrados = await ref.read(repoProvider).buscarProductores(texto);
    if (mounted) {
      setState(() {
        _resultados = encontrados;
        _buscando = false;
      });
    }
  }

  Future<void> _traer(Productor productor) async {
    final remoteId = productor.remoteId;
    final mensajero = ScaffoldMessenger.of(context);

    if (remoteId == null) {
      mensajero.showSnackBar(
        SnackBar(
          content: Text(
            '${productor.nombreCompleto} todavia no existe en Airtable: sus '
            'visitas estan solo en este telefono.',
          ),
        ),
      );
      return;
    }

    final resultado =
        await ref.read(historialProvider.notifier).traer(remoteId);
    if (!mounted) return;

    if (resultado != null) {
      Navigator.of(context).pop();
      mensajero.showSnackBar(SnackBar(content: Text(_resumen(resultado))));
    }
  }

  /// Lo que hay que decirle al visitador no es «listo».
  String _resumen(ResultadoEspejo r) {
    if (r.vacio) return 'Ese agricultor no tiene visitas en Airtable.';

    final partes = <String>[
      if (r.visitas > 0)
        r.visitas == 1 ? '1 visita traida' : '${r.visitas} visitas traidas',
      if (r.fotos > 0) '${r.fotos} foto(s)',
      if (r.audios > 0) '${r.audios} audio(s)',
      // Que una visita no se haya tocado por ser de este telefono no es un
      // fallo: es la regla funcionando, y el visitador tiene que verlo.
      if (r.propiasRespetadas > 0)
        '${r.propiasRespetadas} ya eran de este telefono y no se tocaron',
      if (r.hallazgosFueraDeCatalogo > 0)
        '${r.hallazgosFueraDeCatalogo} dato(s) quedaron fuera: su campo no '
            'esta en el catalogo de esta version',
    ];
    return partes.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final estado = ref.watch(historialProvider);
    final sinRed = ref.watch(redProvider) == EstadoRed.sinRed;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Traer visitas de Airtable', style: tema.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Elige al agricultor. Se bajan sus visitas con las fotos y el '
            'audio, para consultarlas. No se pueden editar, y lo que ya esta '
            'en este telefono no se toca.',
            style: tema.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          if (!AppConfig.isConfigured)
            _Aviso(
              texto: 'Este APK se compilo sin servidor: no hay de donde traer '
                  'las visitas.',
              tono: scheme.error,
            )
          else if (sinRed)
            _Aviso(
              texto: 'Sin senal. Esto necesita red — es lo unico de la app '
                  'que no funciona en la vereda.',
              tono: scheme.error,
            )
          else if (estado.error != null)
            _Aviso(texto: estado.error!, tono: scheme.error),

          if (estado.trabajando) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
            const SizedBox(height: 10),
            Text(
              // El paso concreto y no un «cargando»: traer un historial con
              // fotos y audio tarda, y un spinner mudo parece una app colgada.
              estado.paso.isEmpty ? 'Buscando visitas...' : estado.paso,
              style: tema.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
          ] else ...[
            const SizedBox(height: 12),
            TextField(
              controller: _busqueda,
              autofocus: true,
              onChanged: _buscar,
              decoration: const InputDecoration(
                labelText: 'Buscar al agricultor',
                hintText: 'Nombre, documento o codigo',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 320,
              child: _buscando
                  ? const Center(child: CircularProgressIndicator())
                  : _resultados.isEmpty
                      ? Center(
                          child: Text(
                            'No hay agricultores con ese nombre en el '
                            'directorio del telefono.',
                            textAlign: TextAlign.center,
                            style: tema.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _resultados.length,
                          itemBuilder: (_, i) {
                            final p = _resultados[i];
                            // Sin `remoteId` el agricultor solo existe aqui:
                            // no hay historial que pedir. Se muestra apagado
                            // en vez de esconderlo, para que quede claro por
                            // que no esta.
                            final enAirtable = p.remoteId != null;
                            return ListTile(
                              enabled: enAirtable && !sinRed,
                              leading: const Icon(Icons.person_outline),
                              title: Text(p.nombreCompleto),
                              subtitle: Text(
                                enAirtable
                                    ? [
                                        if (p.codigoProductor != null)
                                          p.codigoProductor!,
                                        if (p.documento != null) p.documento!,
                                      ].join(' · ')
                                    : 'Todavia no esta en Airtable',
                              ),
                              onTap: () => _traer(p),
                            );
                          },
                        ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto, required this.tono});

  final String texto;
  final Color tono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tono.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: tono),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texto, style: TextStyle(fontSize: 12.5, color: tono)),
          ),
        ],
      ),
    );
  }
}
