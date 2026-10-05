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
/// Se pregunta el dia porque el telefono guarda todos los registros que ha
/// tomado: la lista del taller de hoy no puede llevar pegada la de la semana
/// pasada. Con un solo dia no hay nada que preguntar y se va directo.
Future<void> abrirListaAsistenciaPdf(
  BuildContext context,
  WidgetRef ref,
  List<Asistencia> registros,
) async {
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
    builder: (_) => _HojaListaPdf(registros: registros, ref: ref),
  );
}

String _capital(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

DateTime _dia(DateTime d) {
  final l = d.toLocal();
  return DateTime(l.year, l.month, l.day);
}

class _HojaListaPdf extends StatefulWidget {
  const _HojaListaPdf({required this.registros, required this.ref});

  final List<Asistencia> registros;
  final WidgetRef ref;

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
    // Lo comun es sacar la lista al terminar el taller: el dia mas reciente.
    _elegido = _porDia.keys.first;
  }

  List<Asistencia> get _seleccion => _elegido == null
      ? widget.registros
      : widget.registros.where((a) => _dia(a.registradoEn) == _elegido).toList();

  String get _nombreArchivo => _elegido == null
      ? 'lista-asistencia-${selloDia(_porDia.keys.last)}'
            '-a-${selloDia(_porDia.keys.first)}.pdf'
      : 'lista-asistencia-${selloDia(_elegido!)}.pdf';

  Future<DatosListaAsistencia> _datos() async {
    final ref = widget.ref;
    final veredas = {
      for (final v in await ref.read(veredasProvider.future))
        v.id: '${v.vereda} · ${v.municipio}',
    };
    final sesion = ref.read(sesionProvider).valueOrNull;
    return DatosListaAsistencia(
      generadoEn: DateTime.now(),
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
            vereda: veredas[a.veredaLocalId],
            cultivos: a.cultivos.split('\n').where((c) => c.isNotEmpty).toList(),
            areaSembradaHa: a.areaSembradaHa,
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
            Text('Lista de asistencia en PDF', style: tema.textTheme.titleMedium),
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
                      titulo: 'Todos los dias',
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
