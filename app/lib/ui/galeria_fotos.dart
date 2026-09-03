import 'dart:io';

import 'package:flutter/material.dart';

import '../data/db/app_database.dart';
import 'theme.dart';

/// Miniaturas de las fotos de la visita.
///
/// Antes esta lista eran solo pildoras con el segundo del audio: la foto se
/// guardaba en disco y quedaba registrada, pero el visitador no tenia forma de
/// verla desde la app y no podia confirmar si habia salido bien. La miniatura
/// es esa confirmacion, y el toque abre el visor.
class GrillaFotos extends StatelessWidget {
  const GrillaFotos({super.key, required this.fotos});

  final List<Evidencia> fotos;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, limites) {
        // Miniaturas de ~92 px, repartidas para que la fila cierre justa
        // contra los dos bordes de la tarjeta en cualquier ancho de telefono.
        const separacion = 8.0;
        final columnas =
            ((limites.maxWidth + separacion) / 100).floor().clamp(3, 6);
        final lado =
            (limites.maxWidth - separacion * (columnas - 1)) / columnas;

        return Wrap(
          spacing: separacion,
          runSpacing: separacion,
          children: [
            for (var i = 0; i < fotos.length; i++)
              _Miniatura(
                foto: fotos[i],
                lado: lado,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VisorFotos(fotos: fotos, inicial: i),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Miniatura extends StatelessWidget {
  const _Miniatura({
    required this.foto,
    required this.lado,
    required this.onTap,
  });

  final Evidencia foto;
  final double lado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: lado,
          height: lado,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _ImagenArchivo(
                path: foto.archivoPath,
                // Decodificar a 3x el lado alcanza para una pantalla densa sin
                // cargar el JPEG completo en memoria por cada miniatura.
                anchoCache: (lado * 3).round(),
                fondo: tema.colorScheme.surfaceContainerHigh,
              ),
              // El punto verde dice "ya subio". Sin el, el visitador no
              // distingue una foto sincronizada de una que sigue en la cola.
              if (foto.enlaceArchivo != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tema.marca.exito,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              if (foto.segundoAudio != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    color: Colors.black54,
                    child: Text(
                      formatDuration(foto.segundoAudio!),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Visor a pantalla completa, con desliz entre fotos.
///
/// Deja hacer zoom porque la razon de la foto suele ser una etiqueta de
/// producto o una hoja con dano, y a tamano de pantalla no siempre se lee.
class VisorFotos extends StatefulWidget {
  const VisorFotos({super.key, required this.fotos, this.inicial = 0});

  final List<Evidencia> fotos;
  final int inicial;

  @override
  State<VisorFotos> createState() => _VisorFotosState();
}

class _VisorFotosState extends State<VisorFotos> {
  late final PageController _paginas =
      PageController(initialPage: widget.inicial);
  late int _actual = widget.inicial;

  @override
  void dispose() {
    _paginas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Foto ${_actual + 1} de ${widget.fotos.length}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _paginas,
              itemCount: widget.fotos.length,
              onPageChanged: (i) => setState(() => _actual = i),
              itemBuilder: (context, i) => InteractiveViewer(
                maxScale: 5,
                child: Center(
                  child: _ImagenArchivo(
                    path: widget.fotos[i].archivoPath,
                    fondo: Colors.black,
                    ajuste: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          _DetalleFoto(foto: widget.fotos[_actual]),
        ],
      ),
    );
  }
}

class _DetalleFoto extends StatelessWidget {
  const _DetalleFoto({required this.foto});

  final Evidencia foto;

  @override
  Widget build(BuildContext context) {
    final hora = foto.tomadaEn.toLocal();
    final reloj = '${hora.hour.toString().padLeft(2, '0')}:'
        '${hora.minute.toString().padLeft(2, '0')}';
    final subida = foto.enlaceArchivo != null;

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        color: Colors.black,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Etiqueta(texto: 'Tomada $reloj', icono: Icons.schedule),
                if (foto.segundoAudio != null)
                  _Etiqueta(
                    texto:
                        'min ${formatDuration(foto.segundoAudio!)} del audio',
                    icono: Icons.mic_none,
                  ),
                _Etiqueta(
                  texto: subida ? 'Subida' : 'Sin subir',
                  icono: subida
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_upload_outlined,
                ),
              ],
            ),
            // Lo que el modelo leyo de la foto, cuando ya paso por el
            // procesamiento. Antes de eso no hay nada que mostrar.
            if (foto.descripcionIa != null || foto.textoOcr != null) ...[
              const SizedBox(height: 12),
              Text(
                foto.descripcionIa ?? foto.textoOcr!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto, required this.icono});

  final String texto;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 13, color: Colors.white70),
          const SizedBox(width: 5),
          Text(
            texto,
            style: const TextStyle(color: Colors.white70, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

/// La foto desde el disco del telefono.
///
/// El archivo puede faltar: el sistema limpia el directorio de la app, o la
/// visita se abrio en otro telefono y solo bajaron las filas. En ese caso hay
/// que decirlo, no dejar un rectangulo gris que parece una falla.
class _ImagenArchivo extends StatelessWidget {
  const _ImagenArchivo({
    required this.path,
    required this.fondo,
    this.anchoCache,
    this.ajuste = BoxFit.cover,
  });

  final String path;
  final Color fondo;
  final int? anchoCache;
  final BoxFit ajuste;

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(path),
      fit: ajuste,
      cacheWidth: anchoCache,
      gaplessPlayback: true,
      errorBuilder: (context, _, _) => Container(
        color: fondo,
        alignment: Alignment.center,
        child: const Icon(
          Icons.broken_image_outlined,
          size: 20,
          color: Colors.white54,
        ),
      ),
    );
  }
}
