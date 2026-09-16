import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Los tres colores de la marca, tomados del logo (`assets/marca/sirius.png`).
/// No se inventan tonos nuevos: todo lo demas del tema se deriva de estos.
const azulSirius = Color(0xFF004E9D); // el azul del wordmark
const azulClaro = Color(0xFF009DFF); // el punto de arriba
const verdeSirius = Color(0xFF6EB100); // el punto de abajo

/// La tipografia corporativa. Museo Slab es una slab serif: los remates le dan
/// peso al texto en una pantalla vista al sol, que es donde se usa esta app.
///
/// El nombre va aqui como constante y no suelto en cada `TextStyle`: es el
/// unico sitio donde cambiarlo si algun dia la marca cambia de fuente.
const fuenteSirius = 'MuseoSlab';

/// Ambar reservado para "a medias". No es de marca a proposito: si el amarillo
/// fuera corporativo, un semaforo a medio llenar se leeria como estado normal.
const ambarAviso = Color(0xFFB26B00);

/// Colores que Material no nombra pero la app si necesita: "va bien",
/// "va a medias", "atencion". Se leen como `Theme.of(context).marca`.
@immutable
class ColoresMarca extends ThemeExtension<ColoresMarca> {
  const ColoresMarca({
    required this.exito,
    required this.exitoSuave,
    required this.aviso,
    required this.avisoSuave,
    required this.acento,
  });

  final Color exito;
  final Color exitoSuave;
  final Color aviso;
  final Color avisoSuave;
  final Color acento;

  @override
  ColoresMarca copyWith({
    Color? exito,
    Color? exitoSuave,
    Color? aviso,
    Color? avisoSuave,
    Color? acento,
  }) {
    return ColoresMarca(
      exito: exito ?? this.exito,
      exitoSuave: exitoSuave ?? this.exitoSuave,
      aviso: aviso ?? this.aviso,
      avisoSuave: avisoSuave ?? this.avisoSuave,
      acento: acento ?? this.acento,
    );
  }

  @override
  ColoresMarca lerp(ColoresMarca? otro, double t) {
    if (otro == null) return this;
    return ColoresMarca(
      exito: Color.lerp(exito, otro.exito, t)!,
      exitoSuave: Color.lerp(exitoSuave, otro.exitoSuave, t)!,
      aviso: Color.lerp(aviso, otro.aviso, t)!,
      avisoSuave: Color.lerp(avisoSuave, otro.avisoSuave, t)!,
      acento: Color.lerp(acento, otro.acento, t)!,
    );
  }
}

extension TemaMarca on ThemeData {
  ColoresMarca get marca => extension<ColoresMarca>()!;
}

ThemeData buildTheme(Brightness brightness) {
  final oscuro = brightness == Brightness.dark;

  // El esquema se ancla a los tres colores del logo en vez de derivarse de una
  // semilla: el azul de la marca tiene que ser EL azul de la app, no una
  // aproximacion que Material elija por su cuenta.
  final base = ColorScheme.fromSeed(
    seedColor: azulSirius,
    brightness: brightness,
  );
  final scheme = base.copyWith(
    primary: oscuro ? const Color(0xFF8CBEFF) : azulSirius,
    onPrimary: oscuro ? const Color(0xFF00305F) : Colors.white,
    secondary: oscuro ? const Color(0xFF7FD0FF) : azulClaro,
    onSecondary: oscuro ? const Color(0xFF003549) : Colors.white,
    tertiary: oscuro ? const Color(0xFFA8D96B) : const Color(0xFF4C7A00),
    onTertiary: oscuro ? const Color(0xFF203600) : Colors.white,
    // Fondo casi blanco con un velo azul: el papel de la app, no gris sucio.
    surface: oscuro ? const Color(0xFF11151A) : const Color(0xFFF7F9FC),
    surfaceContainerLowest: oscuro ? const Color(0xFF0C1014) : Colors.white,
    surfaceContainerLow: oscuro ? const Color(0xFF161B21) : Colors.white,
    surfaceContainer: oscuro ? const Color(0xFF1A2027) : const Color(0xFFF1F5FA),
    surfaceContainerHigh:
        oscuro ? const Color(0xFF20272F) : const Color(0xFFE9EFF7),
    surfaceContainerHighest:
        oscuro ? const Color(0xFF262E37) : const Color(0xFFE2EAF4),
    outlineVariant: oscuro ? const Color(0xFF39424C) : const Color(0xFFD5DFEB),
  );

  final textos = _tipografia(scheme);
  final radio = BorderRadius.circular(14);

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    // La familia va tambien en el ThemeData y no solo en el TextTheme: lo que
    // dibujan los widgets de Material sin estilo propio —un DatePicker, el
    // texto de un dialogo— sale de aqui.
    fontFamily: fuenteSirius,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: textos,
    splashFactory: InkSparkle.splashFactory,
    extensions: [
      ColoresMarca(
        exito: oscuro ? const Color(0xFF8FD44A) : const Color(0xFF4C7A00),
        exitoSuave:
            oscuro ? const Color(0xFF1E2A10) : const Color(0xFFEDF7DC),
        aviso: oscuro ? const Color(0xFFE0A33D) : ambarAviso,
        avisoSuave: oscuro ? const Color(0xFF2C2312) : const Color(0xFFFBF0DC),
        acento: oscuro ? const Color(0xFF7FD0FF) : azulClaro,
      ),
    ],

    // AppBar como una hoja de papel con una linea abajo: sin sombra, sin tinte
    // que cambie al hacer scroll. Que la marca se vea siempre igual.
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surfaceContainerLowest,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 20,
      titleTextStyle: textos.titleLarge,
      systemOverlayStyle:
          oscuro ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      shape: Border(bottom: BorderSide(color: scheme.outlineVariant)),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),

    // Campos rellenos y sin borde grueso: en un celular al sol, el contraste
    // del fondo se ve mejor que una linea de 1 px.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: radio,
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radio,
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radio,
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radio,
        borderSide: BorderSide(color: scheme.error),
      ),
      labelStyle: TextStyle(
        fontFamily: fuenteSirius,
        color: scheme.onSurfaceVariant,
      ),
      helperStyle: TextStyle(
        fontFamily: fuenteSirius,
        fontSize: 12,
        color: scheme.onSurfaceVariant,
      ),
      helperMaxLines: 2,
    ),

    // Botones altos: se tocan con guantes, de pie y en movimiento.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: radio),
        textStyle: const TextStyle(
          fontFamily: fuenteSirius,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        side: BorderSide(color: scheme.outlineVariant),
        foregroundColor: scheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: radio),
        textStyle: const TextStyle(
          fontFamily: fuenteSirius,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        textStyle: const TextStyle(
          fontFamily: fuenteSirius,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 2,
      highlightElevation: 4,
      extendedTextStyle: const TextStyle(
        fontFamily: fuenteSirius,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    listTileTheme: ListTileThemeData(
      iconColor: scheme.onSurfaceVariant,
      titleTextStyle: textos.bodyLarge,
      subtitleTextStyle: textos.bodySmall?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    expansionTileTheme: ExpansionTileThemeData(
      iconColor: scheme.onSurfaceVariant,
      collapsedIconColor: scheme.onSurfaceVariant,
      textColor: scheme.onSurface,
      collapsedTextColor: scheme.onSurface,
      shape: const Border(),
      collapsedShape: const Border(),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      side: BorderSide(color: scheme.outline, width: 1.6),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      space: 1,
      thickness: 1,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      circularTrackColor: scheme.surfaceContainerHighest,
      linearTrackColor: scheme.surfaceContainerHighest,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: oscuro ? const Color(0xFF2A323B) : const Color(0xFF13233A),
      // Con familia explicita: el SnackBar no hereda del texto de alrededor,
      // planta su propio estilo por defecto. Sin esto el unico texto de la app
      // en otra fuente seria justo el que confirma que algo se guardo.
      contentTextStyle: const TextStyle(
        fontFamily: fuenteSirius,
        color: Colors.white,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.all(16),
    ),
  );
}

/// Jerarquia tipografica explicita. Material por defecto deja los titulos muy
/// livianos para leerse al sol; aca pesan mas.
///
/// El tracking negativo que tenia esta escala era para Roboto, que es
/// estrecha. Museo Slab ya es ancha y lleva remates: apretarla junta los
/// remates de dos letras seguidas y el titulo se emborrona. Por eso aqui el
/// espaciado queda en cero o positivo, y las lineas de texto corrido respiran
/// un punto mas que antes.
TextTheme _tipografia(ColorScheme scheme) {
  final base = Typography.material2021(colorScheme: scheme).black;
  final texto = scheme.onSurface;
  return base
      .copyWith(
        displaySmall: base.displaySmall?.copyWith(
          fontWeight: FontWeight.w300,
          letterSpacing: -0.5,
        ),
        headlineSmall: base.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        titleLarge: base.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        titleMedium: base.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        bodyLarge: base.bodyLarge?.copyWith(fontSize: 15, height: 1.45),
        bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, height: 1.5),
        bodySmall: base.bodySmall?.copyWith(fontSize: 12.5, height: 1.45),
        labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      )
      // `apply` pisa la familia de las 15 variantes de golpe: la escala de
      // Material trae Roboto clavada en cada una, y sin esto los estilos que
      // no se redefinen arriba seguirian saliendo en Roboto.
      .apply(
        fontFamily: fuenteSirius,
        bodyColor: texto,
        displayColor: texto,
      );
}

String formatDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
}
