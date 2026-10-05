import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../core/lista_asistencia_pdf.dart';
import '../data/db/app_database.dart';
import '../data/nombres_archivo.dart';
import '../state/providers.dart';
import '../state/sesion.dart';
import 'theme.dart';

/// Elige de que dia sale la lista y la comparte o la imprime.
///
/// Los [registros] ya vienen del evento. Si el evento duro varios dias se
/// puede sacar la lista de uno solo; por defecto sale el evento completo.
Future<void> abrirListaAsistenciaPdf(
  BuildContext context,
  WidgetRef ref,
  List<Asistencia> registros, {
  String? evento,
}) async {
  if (registros.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Todavia no hay registros para la lista.')),
    );
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) =>
        _HojaListaPdf(registros: registros, ref: ref, evento: evento),
  );
}

String _capital(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

DateTime _dia(DateTime d) {
  final l = d.toLocal();
  return DateTime(l.year, l.month, l.day);
}

class _HojaListaPdf extends StatefulWidget {
  const _HojaListaPdf({
    required this.registros,
    required this.ref,
    this.evento,
  });

  final List<Asistencia> registros;
  final WidgetRef ref;
  final String? evento;

  @override
  State<_HojaListaPdf> createState() => _HojaListaPdfState();
}

class _HojaListaPdfState extends State<_HojaListaPdf> {
  /// null = todos los dias.
  DateTime? _elegido;
  bool _trabajando = false;

  late final Map<DateTime, int> _porDia = () {
    final conteo = <DateTime, int>{};
    for (final a in widget.registros) {
      conteo.update(_dia(a.registradoEn), (n) => n + 1, ifAbsent: () => 1);
    }
    final dias = conteo.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final d in dias) d: conteo[d]!};
  }();

  @override
  void initState() {
    super.initState();
    // Un dia solo no tiene nada que elegir; con varios, el evento completo.
    _elegido = _porDia.length == 1 ? _porDia.keys.first : null;
  }

  List<Asistencia> get _seleccion => _elegido == null
      ? widget.registros
      : widget.registros.where((a) => _dia(a.registradoEn) == _elegido).toList();

  /// `asistencia-taller-de-bioinsumos-2026-10-05.pdf`: con el evento, que es
  /// como se busca el archivo despues en el telefono o en el correo.
  String get _nombreArchivo {
    final quien = slugArchivo(widget.evento ?? '');
    final dias = _elegido != null
        ? selloDia(_elegido!)
        : _porDia.length == 1
        ? selloDia(_porDia.keys.first)
        : '${selloDia(_porDia.keys.last)}-a-${selloDia(_porDia.keys.first)}';
    return 'asistencia-${quien.isEmpty ? 'sin-evento' : quien}-$dias.pdf';
  }

  Future<DatosListaAsistencia> _datos() async {
    final ref = widget.ref;
    final veredas = {
      for (final v in await ref.read(veredasProvider.future))
        v.id: '${v.vereda} · ${v.municipio}',
    };
    final sesion = ref.read(sesionProvider).valueOrNull;
    return DatosListaAsistencia(
      generadoEn: DateTime.now(),
      evento: widget.evento,
      responsable: sesion?.credencial.nombre,
      filas: [
        for (final a in _seleccion)
          FilaListaAsistencia(
            registradoEn: a.registradoEn,
            firmaPath: a.firmaPath,
            procesado: a.procesado,
            nombre: a.nombreCompleto,
            cedula: a.cedula,
            telefono: a.telefono,
            correo: a.correo,
            vereda: veredas[a.veredaLocalId],
            quiereVisita: a.quiereVisita,
          ),
      ],
    );
  }

  Future<void> _hacer({required bool imprimir}) async {
    if (_trabajando) return;
    setState(() => _trabajando = true);
    final mensajero = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);
    final caja = context.findRenderObject() as RenderBox?;
    try {
      final bytes = await construirListaAsistenciaPdf(await _datos());
      final nombre = _nombreArchivo;
      navegador.pop();
      if (imprimir) {
        await Printing.layoutPdf(onLayout: (_) async => bytes, name: nombre);
      } else {
        // `fileNameOverrides`: sin el, share_plus le pone un UUID al archivo
        // en Android y a WhatsApp llega `1fa-11f1-....pdf`.
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(bytes, mimeType: 'application/pdf', name: nombre),
            ],
            fileNameOverrides: [nombre],
            subject: 'Lista de asistencia',
            sharePositionOrigin: caja == null
                ? null
                : caja.localToGlobal(Offset.zero) & caja.size,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _trabajando = false);
      mensajero.showSnackBar(
        SnackBar(content: Text('No se pudo armar la lista: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final formato = DateFormat("EEEE d 'de' MMMM", 'es');
    final pendientes = _seleccion.where((a) => !a.procesado).length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.evento == null
                  ? 'Lista de asistencia en PDF'
                  : 'Lista de «${widget.evento}» en PDF',
              style: tema.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Ordenada por hora de registro, con la firma de cada persona.',
              style: tema.textTheme.bodySmall
                  ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final MapEntry(key: dia, value: n) in _porDia.entries)
                    _OpcionDia(
                      titulo: _capital(formato.format(dia)),
                      cantidad: n,
                      elegido: _elegido == dia,
                      onTap: () => setState(() => _elegido = dia),
                    ),
                  if (_porDia.length > 1)
                    _OpcionDia(
                      titulo: widget.evento == null
                          ? 'Todos los dias'
                          : 'Todo el evento',
                      cantidad: widget.registros.length,
                      elegido: _elegido == null,
                      onTap: () => setState(() => _elegido = null),
                    ),
                ],
              ),
            ),
            if (pendientes > 0) ...[
              const SizedBox(height: 8),
              Text(
                '$pendientes registro(s) todavia no se procesan: salen con la '
                'hora y la firma, y los datos como «Por procesar».',
                style: TextStyle(fontSize: 12.5, color: tema.marca.aviso),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _trabajando ? null : () => _hacer(imprimir: true),
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Imprimir'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _trabajando ? null : () => _hacer(imprimir: false),
                    icon: _trabajando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.share_outlined),
                    label: const Text('Compartir'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OpcionDia extends StatelessWidget {
  const _OpcionDia({
    required this.titulo,
    required this.cantidad,
    required this.elegido,
    required this.onTap,
  });

  final String titulo;
  final int cantidad;
  final bool elegido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(
        elegido ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: elegido ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(titulo),
      trailing: Text(cantidad == 1 ? '1 persona' : '$cantidad personas'),
    );
  }
}
