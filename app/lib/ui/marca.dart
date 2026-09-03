import 'package:flutter/material.dart';

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
      actions: actions,
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
class AnilloCompletitud extends StatelessWidget {
  const AnilloCompletitud({
    super.key,
    required this.pct,
    this.diametro = 46,
    this.grosor = 4,
  });

  final int pct;
  final double diametro;
  final double grosor;

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

    return SizedBox(
      width: diametro,
      height: diametro,
      child: Stack(
        alignment: Alignment.center,
        children: [
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
          if (diametro >= 28)
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
