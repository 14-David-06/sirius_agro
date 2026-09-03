import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config.dart';
import '../state/sesion.dart';
import 'marca.dart';
import 'theme.dart';

/// La puerta de la app. Entra con la contrasena de Sirius Nomina Core: no hay
/// un usuario propio del agro que alguien tenga que crear y despues recordar.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _cedula = TextEditingController();
  final _password = TextEditingController();
  final _focoPassword = FocusNode();
  bool _verPassword = false;

  @override
  void dispose() {
    _cedula.dispose();
    _password.dispose();
    _focoPassword.dispose();
    super.dispose();
  }

  bool get _listo =>
      _cedula.text.replaceAll(RegExp(r'\D'), '').isNotEmpty &&
      _password.text.isNotEmpty;

  Future<void> _entrar() async {
    if (!_listo) return;
    // El teclado tapa el mensaje de error en pantallas chicas.
    FocusScope.of(context).unfocus();
    await ref
        .read(loginProvider.notifier)
        .entrar(_cedula.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    final estado = ref.watch(loginProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Un APK mal compilado se descubre aca, en el escritorio,
                  // y no en una finca a una hora del pueblo.
                  if (kReleaseMode && AppConfig.problemaDeCompilacion != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Banda(
                        texto: AppConfig.problemaDeCompilacion!,
                        icono: Icons.build_circle_outlined,
                        tono: TonoPildora.error,
                      ),
                    ),
                  const Center(child: LogoSirius(alto: 40)),
                  const SizedBox(height: 10),
                  Text(
                    'COPILOTO DE CAMPO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 36),
                  TextField(
                    controller: _cedula,
                    autocorrect: false,
                    enableSuggestions: false,
                    // Teclado numerico: la cedula son digitos y en el campo se
                    // teclea de pie. Se aceptan los puntos por si alguien los
                    // escribe por costumbre; el backend los ignora.
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Numero de cedula',
                      helperText: 'Sin puntos ni espacios. El de nomina.',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _focoPassword.requestFocus(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _password,
                    focusNode: _focoPassword,
                    obscureText: !_verPassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Contrasena',
                      prefixIcon: const Icon(Icons.lock_outline),
                      // Al sol y con guantes se teclea mal: poder mirar lo que
                      // se escribio evita el tercer intento fallido.
                      suffixIcon: IconButton(
                        icon: Icon(
                          _verPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _verPassword = !_verPassword),
                        tooltip: _verPassword ? 'Ocultar' : 'Mostrar',
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _entrar(),
                  ),
                  if (estado.error != null) ...[
                    const SizedBox(height: 18),
                    _Error(estado: estado),
                  ],
                  const SizedBox(height: 26),
                  FilledButton.icon(
                    onPressed: _listo && !estado.trabajando ? _entrar : null,
                    icon: estado.trabajando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: Text(estado.trabajando ? 'Entrando...' : 'Entrar'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.wifi_off,
                        size: 15,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'El primer ingreso de cada persona en este telefono '
                          'necesita internet. Despues funciona en la finca sin '
                          'señal.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.estado});

  final LoginState estado;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final scheme = tema.colorScheme;
    // Falta de red y contrasena mala no son la misma clase de problema: una se
    // arregla caminando hasta donde haya señal, la otra tecleando de nuevo.
    final red = estado.necesitaRed;
    final (frente, fondo, icono) = red
        ? (tema.marca.aviso, tema.marca.avisoSuave, Icons.cloud_off)
        : (scheme.error, scheme.errorContainer, Icons.error_outline);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: frente),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              estado.error!,
              style: TextStyle(fontSize: 13, height: 1.4, color: frente),
            ),
          ),
        ],
      ),
    );
  }
}
