import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../core/informe_pdf.dart';
import '../data/db/app_database.dart';
import '../state/providers.dart';
import 'marca.dart';

/// El informe, para leerselo al productor antes de irse de la finca.
///
/// Se renderiza el markdown a mano en vez de traer un paquete: el modelo
/// devuelve encabezados, vinetas y parrafos, y nada mas. Un renderizador
/// completo agregaria peso al APK para soportar tablas y codigo que este
/// documento no va a tener nunca.
class InformePage extends ConsumerWidget {
  const InformePage({super.key, required this.informe});

  final Informe informe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final fecha = DateFormat("d 'de' MMMM, h:mm a", 'es').format(
      informe.generadoEn,
    );

    return Scaffold(
      appBar: AppBarMarca(
        titulo: 'Informe de la visita',
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Ver o imprimir el PDF',
            onPressed: () => _imprimir(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.copy_all_outlined),
            tooltip: 'Copiar',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: informe.contenido));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Informe copiado.')),
                );
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
        children: [
          Row(
            children: [
              Pildora(texto: informe.tipo, tono: TonoPildora.info),
              const SizedBox(width: 6),
              Pildora(texto: 'v${informe.version}'),
              if (informe.entregado) ...[
                const SizedBox(width: 6),
                const Pildora(
                  texto: 'Entregado',
                  tono: TonoPildora.exito,
                  icono: Icons.check_rounded,
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Generado el $fecha',
            style: tema.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          ..._render(context, informe.contenido),
          const SizedBox(height: 28),
          // El productor tiene derecho a que le digan de donde salio esto.
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 17,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Este informe lo armo la app a partir de la conversacion. '
                    'Leaselo al productor antes de entregarlo: si algo no '
                    'coincide con lo que dijo, corrijalo con el.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _entregar(context, ref),
        icon: const Icon(Icons.send),
        label: const Text('Entregar PDF'),
      ),
    );
  }

  /// El PDF se arma en el telefono, no en el backend: el visitador lo entrega
  /// antes de irse de la finca, y ahi puede no haber señal.
  Future<Uint8List> _pdf(WidgetRef ref) async {
    final ctx = await ref.read(repoProvider).contextoPdf(informe.visitaId);
    return construirInformePdf(
      DatosInforme(
        titulo: informe.titulo,
        contenido: informe.contenido,
        generadoEn: informe.generadoEn,
        productor: ctx['productor'] as String?,
        finca: ctx['finca'] as String?,
        vereda: ctx['vereda'] as String?,
        municipio: ctx['municipio'] as String?,
        visitador: ctx['visitador'] as String?,
        fechaVisita: DateTime.tryParse(ctx['fecha'] as String? ?? ''),
        fotos: (ctx['fotos'] as List).cast<String>(),
      ),
    );
  }

  String get _nombreArchivo {
    final limpio = informe.titulo
        .replaceAll(RegExp(r'[^A-Za-z0-9 -]'), '')
        .replaceAll(' ', '-');
    return '$limpio.pdf';
  }

  Future<void> _entregar(BuildContext context, WidgetRef ref) async {
    final mensajero = ScaffoldMessenger.of(context);
    final caja = context.findRenderObject() as RenderBox?;

    try {
      final bytes = await _pdf(ref);

      // `share` abre WhatsApp, correo o lo que el telefono tenga. No se fuerza
      // un canal: en el llano el productor a veces solo tiene WhatsApp, y a
      // veces solo el papel del pueblo.
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'application/pdf',
              name: _nombreArchivo,
            ),
          ],
          subject: informe.titulo,
          sharePositionOrigin:
              caja == null ? null : caja.localToGlobal(Offset.zero) & caja.size,
        ),
      );

      // Se marca entregado al compartir, no al confirmar que llego: el telefono
      // no puede saber si el productor lo abrio, y pedir esa confirmacion seria
      // inventar un dato.
      await ref.read(repoProvider).marcarInformeEntregado(informe.id);
    } catch (e) {
      mensajero.showSnackBar(
        SnackBar(content: Text('No se pudo armar el PDF: $e')),
      );
    }
  }

  /// Imprimir o guardar el PDF sin pasar por compartir. En el pueblo a veces
  /// lo que hay es una impresora, no internet.
  Future<void> _imprimir(BuildContext context, WidgetRef ref) async {
    final mensajero = ScaffoldMessenger.of(context);
    try {
      final bytes = await _pdf(ref);
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: _nombreArchivo,
      );
    } catch (e) {
      mensajero.showSnackBar(
        SnackBar(content: Text('No se pudo armar el PDF: $e')),
      );
    }
  }

  /// Markdown minimo: `#`, `##`, `###`, vinetas y parrafos.
  List<Widget> _render(BuildContext context, String md) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final widgets = <Widget>[];

    for (final crudo in md.split('\n')) {
      final linea = crudo.trimRight();
      if (linea.trim().isEmpty) {
        widgets.add(const SizedBox(height: 12));
        continue;
      }

      if (linea.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            _limpiar(linea.substring(2)),
            style: tema.textTheme.headlineSmall,
          ),
        ));
      } else if (linea.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8),
          child: Text(
            _limpiar(linea.substring(3)),
            style: tema.textTheme.titleLarge?.copyWith(color: scheme.primary),
          ),
        ));
      } else if (linea.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(
            _limpiar(linea.substring(4)),
            style: tema.textTheme.titleMedium,
          ),
        ));
      } else if (linea.trimLeft().startsWith('- ') ||
          linea.trimLeft().startsWith('* ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 10),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  _limpiar(linea.trimLeft().substring(2)),
                  // Un poco mas grande que el cuerpo normal: esto se lee en
                  // voz alta, a veces con el sol de frente.
                  style: tema.textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
              ),
            ],
          ),
        ));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            _limpiar(linea),
            style: tema.textTheme.bodyLarge?.copyWith(height: 1.55),
          ),
        ));
      }
    }

    return widgets;
  }

  /// Quita el enfasis de markdown. No se renderiza en negrita: el informe se
  /// lee en voz alta y los asteriscos sueltos confunden mas de lo que ayudan.
  String _limpiar(String texto) =>
      texto.replaceAll(RegExp(r'\*{1,2}'), '').replaceAll('__', '').trim();
}
