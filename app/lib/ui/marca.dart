import 'dart:io';

import 'package:flutter/material.dart';

import 'indicador_red.dart';
import 'theme.dart';

/// El wordmark de Sirius. Dos archivos porque el logo a color no se lee sobre
/// fondo oscuro: en tema oscuro va la version blanca, con los dos puntos que
/// siguen siendo de marca.
class LogoSirius extends StatelessWidget {
  const LogoSirius({super.key, this.alto = 22});

  final double alto;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      oscuro ? 'assets/marca/sirius_blanco.png' : 'assets/marca/sirius.png',
      height: alto,
      filterQuality: FilterQuality.high,
      excludeFromSemantics: true,
    );
  }
}

/// Encabezado de la app: el logo manda y el nombre de la pantalla va debajo,
/// pequeno. Asi cada pantalla se ve como parte del mismo producto.
///
/// El estado de la conexion va aqui, antes de las acciones de cada pantalla:
/// en campo se consulta a cada rato y tiene que estar siempre en el mismo
/// lugar, no en una pantalla si y en otra no.
class AppBarMarca extends StatelessWidget implements PreferredSizeWidget {
  const AppBarMarca({super.key, required this.titulo, this.actions});

  final String titulo;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppBar(
      toolbarHeight: 64,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const LogoSirius(alto: 20),
          const SizedBox(height: 3),
          Text(
            titulo.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        const IndicadorRed(),
        ...?actions,
      ],
    );
  }
}

/// Etiqueta de estado. El color dice el estado; el texto lo confirma. Nunca
/// solo color: el visitador puede estar mirando la pantalla al sol.
enum TonoPildora { neutro, exito, aviso, error, info }

class Pildora extends StatelessWidget {
  const Pildora({
    super.key,
    required this.texto,
    this.tono = TonoPildora.neutro,
    this.icono,
  });

  final String texto;
  final TonoPildora tono;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final marca = tema.marca;

    final (frente, fondo) = switch (tono) {
      TonoPildora.exito => (marca.exito, marca.exitoSuave),
      TonoPildora.aviso => (marca.aviso, marca.avisoSuave),
      TonoPildora.error => (scheme.error, scheme.errorContainer),
      TonoPildora.info => (scheme.primary, scheme.primaryContainer),
      TonoPildora.neutro => (
          scheme.onSurfaceVariant,
          scheme.surfaceContainerHigh,
        ),
    };

    return Container(
      padding: EdgeInsets.fromLTRB(icono == null ? 10 : 7, 4, 10, 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 13, color: frente),
            const SizedBox(width: 4),
          ],
          Text(
            texto,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              height: 1.1,
              color: frente,
            ),
          ),
        ],
      ),
    );
  }
}

/// Anillo de completitud. El mismo widget en la lista y en la barra de la
/// visita, para que el numero signifique lo mismo en las dos pantallas.
///
/// Dentro del anillo va [child] --normalmente la cara del agricultor-- y no el
/// numero: el anillo es lo que se mira de reojo para saber como va la visita,
/// y la cara es lo que permite reconocer de quien es la visita sin leer. El
/// numero exacto se escribe aparte, donde haya sitio para leerlo.
class AnilloCompletitud extends StatelessWidget {
  const AnilloCompletitud({
    super.key,
    required this.pct,
    this.diametro = 46,
    this.grosor = 4,
    this.child,
  });

  final int pct;
  final double diametro;
  final double grosor;

  /// Lo que se ve dentro del anillo. Sin esto vuelve al numero, que es lo que
  /// sirve cuando no hay a quien mostrar: una visita sin productor cargado.
  final Widget? child;

  static Color colorDe(BuildContext context, int pct) {
    final tema = Theme.of(context);
    return switch (pct) {
      >= 80 => tema.marca.exito,
      >= 40 => tema.marca.aviso,
      _ => tema.colorScheme.outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = colorDe(context, pct);

    // El interior se mete por dentro del trazo y con un pelo de aire: una foto
    // pegada al anillo se lee como un borron de dos colores.
    final margen = grosor + 2;

    return SizedBox(
      width: diametro,
      height: diametro,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (child != null)
            Padding(
              padding: EdgeInsets.all(margen),
              child: ClipOval(child: SizedBox.expand(child: child)),
            ),
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: pct / 100,
              strokeWidth: grosor,
              strokeCap: StrokeCap.round,
              backgroundColor: scheme.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          // Debajo de ~28 px el numero no se lee: el anillo solo ya dice
          // lo suficiente y el porcentaje va escrito al lado.
          if (child == null && diametro >= 28)
            Text(
              '$pct',
              style: TextStyle(
                fontSize: diametro * 0.28,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}

/// La cara del agricultor: su foto si la hay, y si no una silueta.
///
/// Tres origenes en orden, porque cada uno falla de una forma distinta: el
/// archivo del telefono es el unico que funciona sin senal; la miniatura de
/// Airtable sirve para las visitas que bajo otro telefono, pero caduca; y
/// cuando no hay ninguno queda la silueta, que nunca falla.
///
/// La silueta no es un monigote generico: es una persona con sombrero de
/// campo. La app se usa delante de la persona que retrata, y una lista de
/// fichas grises no dice nada de a quien se fue a ver.
class AvatarAgricultor extends StatelessWidget {
  const AvatarAgricultor({
    super.key,
    this.fotoPath,
    this.fotoRemota,
    this.genero,
  });

  final String? fotoPath;
  final String? fotoRemota;

  /// Tal como lo guarda la ficha: `Femenino`, `Masculino`, `Otro`,
  /// `Prefiere no decir` o nada.
  final String? genero;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final silueta = SiluetaAgricultor(genero: genero);
    final local = fotoPath;
    final remota = fotoRemota;

    Widget interior;
    if (local != null && local.isNotEmpty && File(local).existsSync()) {
      final archivo = File(local);
      interior = Image.file(
        archivo,
        fit: BoxFit.cover,
        // La ruta del retrato es siempre la misma dentro de la carpeta de la
        // visita, asi que sin la marca de tiempo se seguiria viendo la foto
        // que se acaba de reemplazar.
        key: ValueKey(archivo.lastModifiedSync()),
        cacheWidth: 200,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => silueta,
      );
    } else if (remota != null && remota.isNotEmpty) {
      // Caduca cada pocas horas y en la finca puede no haber red: que falle es
      // normal, y lo normal no puede dejar un hueco rojo en la lista.
      interior = Image.network(
        remota,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => silueta,
      );
    } else {
      interior = silueta;
    }

    return Container(color: scheme.surfaceContainerHigh, child: interior);
  }
}

/// Silueta de agricultor o agricultora, segun el genero de la ficha.
///
/// Dibujada y no traida como imagen: son cuatro formas, pesan cero, y asi se
/// tinen con el color del tema en vez de quedarse grises cuando el telefono
/// esta en modo oscuro.
///
/// Solo `Femenino` cambia el dibujo. `Otro`, `Prefiere no decir` y la ficha
/// sin genero salen con la silueta base: inventarle un genero a quien dijo que
/// prefiere no decirlo seria peor que no distinguirlo.
class SiluetaAgricultor extends StatelessWidget {
  const SiluetaAgricultor({super.key, this.genero});

  final String? genero;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _PintorSilueta(
        color: scheme.outline,
        femenino: genero?.trim().toLowerCase() == 'femenino',
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _PintorSilueta extends CustomPainter {
  const _PintorSilueta({required this.color, required this.femenino});

  final Color color;
  final bool femenino;

  @override
  void paint(Canvas canvas, Size size) {
    // Todo el dibujo esta escrito sobre un cuadrado de 100x100 y se escala al
    // tamano real: asi las mismas coordenadas sirven para el avatar de 46 px
    // de la lista y para el de 20 px de la barra.
    canvas.scale(size.width / 100, size.height / 100);
    final pincel = Paint()..color = color;

    // El pelo va primero: al pintarse debajo de la cabeza y del sombrero, lo
    // unico que asoma es la melena que baja por los lados de la cara.
    //
    // Es UNA forma cerrada que arranca bajo el ala y termina dentro del
    // hombro, y no dos mechones sueltos: dos ovalos dejan sin pintar el
    // triangulo donde se juntan mechon, cabeza y hombro, y a 46 px ese hueco
    // se ve como dos ojos blancos en mitad de la cara.
    if (femenino) {
      final pelo = Path()
        ..moveTo(31, 30)
        ..cubicTo(25, 44, 25, 62, 28, 74)
        ..lineTo(72, 74)
        ..cubicTo(75, 62, 75, 44, 69, 30)
        ..close();
      canvas.drawPath(pelo, pincel);
    }

    // Hombros: el busto se corta abajo, como un retrato de carnet.
    final hombros = Path()
      ..moveTo(14, 100)
      ..cubicTo(16, 74, 32, 62, 50, 62)
      ..cubicTo(68, 62, 84, 74, 86, 100)
      ..close();
    canvas.drawPath(hombros, pincel);

    canvas.drawCircle(const Offset(50, 46), 17, pincel);

    // El sombrero es lo que convierte la silueta en un agricultor. El ala
    // ancha no es adorno: es lo que se reconoce de un vistazo a 20 px.
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTRB(34, 12, 66, 34),
        topLeft: const Radius.circular(13),
        topRight: const Radius.circular(13),
      ),
      pincel,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 33), width: 74, height: 14),
      pincel,
    );
  }

  @override
  bool shouldRepaint(_PintorSilueta otro) =>
      otro.color != color || otro.femenino != femenino;
}

/// Titulo de bloque dentro de una pantalla larga. Da estructura sin gastar
/// una tarjeta entera.
class TituloSeccion extends StatelessWidget {
  const TituloSeccion(this.texto, {super.key, this.accion});

  final String texto;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              texto.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          ?accion,
        ],
      ),
    );
  }
}

/// Pantalla vacia o en error. Siempre dice que hacer, no solo que pasa.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    required this.detalle,
    this.tono = TonoPildora.neutro,
  });

  final IconData icono;
  final String titulo;
  final String detalle;
  final TonoPildora tono;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final (frente, fondo) = switch (tono) {
      TonoPildora.error => (scheme.error, scheme.errorContainer),
      _ => (scheme.primary, scheme.surfaceContainerHigh),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
              child: Icon(icono, size: 34, color: frente),
            ),
            const SizedBox(height: 20),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: tema.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              detalle,
              textAlign: TextAlign.center,
              style: tema.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banda de aviso al tope de una pantalla (error de grabacion, permiso que
/// falta). Ocupa el ancho completo para que no se confunda con contenido.
class Banda extends StatelessWidget {
  const Banda({
    super.key,
    required this.texto,
    required this.icono,
    this.tono = TonoPildora.aviso,
    this.onCerrar,
  });

  final String texto;
  final IconData icono;
  final TonoPildora tono;
  final VoidCallback? onCerrar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final (frente, fondo) = switch (tono) {
      TonoPildora.error => (scheme.onErrorContainer, scheme.errorContainer),
      TonoPildora.exito => (tema.marca.exito, tema.marca.exitoSuave),
      _ => (tema.marca.aviso, tema.marca.avisoSuave),
    };

    return Container(
      width: double.infinity,
      color: fondo,
      padding: EdgeInsets.fromLTRB(16, 12, onCerrar == null ? 16 : 4, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: frente),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(fontSize: 13, height: 1.35, color: frente),
            ),
          ),
          if (onCerrar != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: frente,
              onPressed: onCerrar,
              tooltip: 'Entendido',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
