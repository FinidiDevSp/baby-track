# AGENTS.md — Guía operativa para apps Flutter/Dart
> Versión: 1.0 · Mantenedor: Equipo Dev · Estado: Estable

## 0. Propósito
Este documento define **agentes, responsabilidades, estándares y rutinas** para desarrollar y operar aplicaciones **Flutter/Dart** con calidad de producción. Úsalo como contrato del equipo y checklist vivo.

---

## 1. Roles/Agentes y responsabilidades
- **Tech Lead (Agente Arquitectura)**
  - Define arquitectura, estándares, decisiones ADR y trade‑offs.
  - Acepta cambios de arquitectura y librerías core.
- **Agente UI/UX**
  - Sistema de diseño, accesibilidad (a11y), theming (light/dark), motion.
  - Revisa consistencia visual y states vacíos/error/empty.
- **Agente Estado & Dominio**
  - Modelado de dominio, casos de uso, orquestación de estado (Bloc/Riverpod).
- **Agente Datos & Red**
  - Integración API, cache/persistencia, manejo de errores y reintentos.
- **Agente Calidad (QA/Testing)**
  - Pirámide de tests, cobertura mínima y pruebas de regresión visual.
- **Agente DevEx/CI-CD**
  - Automatiza pipelines, linters, versionado semántico y releases.
- **Agente Seguridad**
  - Manejo de secretos, hardening, revisión de dependencias, políticas de datos.

Cada PR debe tener un **agente responsable** explícito.

---

## 2. Arquitectura recomendada
- **Clean Architecture + Feature First** con capas:
  - `presentation/` (widgets, pages, controllers).
  - `application/` (use cases, servicios de orquestación).
  - `domain/` (entidades, repositorios abstractos, value objects).
  - `infrastructure/` (datasources, DTOs, mappers, client HTTP).
- **Gestión de estado**: Riverpod (preferido) o Bloc/Cubit.
- **Navegación**: `go_router` con rutas tipadas y guards.
- **DI**: `riverpod`/`get_it` (si no usas Riverpod).
- **Serialización**: `json_serializable` + `freezed` para inmutables/sealed.
- **Theming**: `ThemeExtension` + tokens de diseño.
- **Internacionalización (i18n)**: `flutter_localizations` + `intl`.

**Estructura sugerida de proyecto**:
```
lib/
  app.dart
  bootstrap.dart
  router/
    app_router.dart
  features/
    auth/
      presentation/
      application/
      domain/
      infrastructure/
    home/
      ...
  shared/
    widgets/
    theme/
    utils/
    data/
      clients/
      storage/
test/
  features/
  shared/
```

---

## 3. Estándares de código (Dart/Flutter)
- **Null-safety obligatorio** y tipos explícitos en API pública.
- **Inmutabilidad por defecto** (`final`, `const`, `freezed`).
- **Arquitectura de errores**: usar `Result<E, T>`/`Either` o `AsyncValue`.
- **Widgets**: sin lógica de negocio; componer; preferir `const` widgets.
- **Nombres**: `PascalCase` para clases, `camelCase` para miembros, `snake_case` para archivos.
- **Límites**: 200 LOC por archivo (soft), 300 por widget (máx).

**Linter recomendado (`analysis_options.yaml`)**: `package:flutter_lints/flutter.yaml` + reglas: `always_use_package_imports`, `prefer_final_locals`, `avoid_print`, `public_member_api_docs`, `prefer_single_quotes`, `unawaited_futures`.

---

## 4. Estado con Riverpod (ejemplo)
```dart
// domain/user.dart (freezed)
@freezed
class User with _$User {
  const factory User({required String id, required String name}) = _User;
}

// application/usecases/get_user.dart
final getUserUseCaseProvider = Provider<GetUserUseCase>((ref) {
  final repo = ref.watch(userRepositoryProvider);
  return GetUserUseCase(repo);
});

class GetUserUseCase {
  GetUserUseCase(this._repo);
  Future<User> call(String id) => _repo.getById(id);
}

// presentation/user_controller.dart
final userControllerProvider = AsyncNotifierProvider.autoDispose
    <UserController, User?>(UserController.new);

class UserController extends AutoDisposeAsyncNotifier<User?> {
  @override
  Future<User?> build() async => null;

  Future<void> load(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(getUserUseCaseProvider)(id));
  }
}
```

---

## 5. Networking, caché y errores
- Cliente HTTP: `dio` con **interceptors** (auth, logging solo en debug).
- Retries con backoff exponencial, timeouts definidos por entorno.
- **Cache**: `hive`/`shared_preferences` o `sqflite` según necesidad.
- **Errores**: mapear HTTP → dominio (`NetworkFailure`, `AuthFailure`).
- **Política offline**: modos `staleWhileRevalidate` en queries.

---

## 6. UI/UX y accesibilidad
- **Tamaños táctiles** ≥ 48px; contraste WCAG AA; soporte lector de pantalla.
- Estados vacíos y de error con acciones de recuperación.
- Animaciones con `ImplicitlyAnimated` o `Motion` discreta; 60fps.
- Soporte **dark mode** y tamaños de fuente del sistema.
- Adaptar para web/desktop con `LayoutBuilder` y breakpoints.

---

## 7. Testing (pirámide y metas)
- **Unit**: mínimo **70%** de cobertura de dominio.
- **Widget**: casos críticos de UI y estados vacíos/error.
- **Integration/E2E**: `integration_test` + `patrol` (opcional).
- **Regresión visual**: `golden_toolkit` para pantallas clave.
- **Performance**: `flutter drive --profile` + benchmarks específicos.
- **QA checks** previos a merge (ver checklist).

Ejemplo de test de widget:
```dart
testWidgets('muestra placeholder cuando no hay usuario', (tester) async {
  await tester.pumpWidget(ProviderScope(child: MyApp()));
  expect(find.text('No user'), findsOneWidget);
});
```

---

## 8. CI/CD y automatización
- **CI**: acciones en PR
  - `flutter pub get`
  - Linters y formato (`dart format --set-exit-if-changed .`)
  - `flutter analyze`, `dart test`, goldens en entorno estable.
- **CD**:
  - Versionado semántico a partir de commits convencionales.
  - Build & notarization (iOS), firmas y artefactos (Android).
  - Deploy por canal: `alpha`, `beta`, `prod` con `fastlane`/`codemagic`.
- **Release notes** generadas desde Conventional Commits (`conventional-changelog`).

---

## 9. Seguridad y datos
- **Secretos** fuera del repo; usar `--dart-define-from-file` o manager seguro.
- **TLS pinning** si aplica; validar certificados en producción.
- **PP/ToS** enlazados en app; **telemetría opt‑in**; minimiza PII.
- Revisión de dependencias con `flutter pub outdated --mode=null-safety` y escáneres SCA.

---

## 10. Performance
- Usar `const` y `Keys`; evitar rebuilds con `select`/`Provider` granular.
- **Images** optimizadas (WebP/AVIF), `cacheWidth/height`.
- Medir con **DevTools** (raster, shader compilations), prewarm shaders.
- `isolate` para tareas pesadas; evita trabajo en main isolate.

---

## 11. Localización (i18n) y formatos
- `arb` por idioma; `Intl.message` + codegen.
- Probar pluralización, género y formatos regionales.
- Asegurar que cadenas no estén hardcodeadas en widgets.

---

## 12. Guía de git y commits (Convencional)
**Formato**: `tipo(scope)!: resumen`  
Tipos: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.

**Ejemplos**:
- `feat(auth): flujo de login con go_router y Riverpod`
- `fix(api): reintentos con backoff y timeout configurables`
- `perf(home): reduce jank usando const y memoización`
- `refactor(theme): extrae tokens a ThemeExtension`

---

## 13. Checklist PR (copiar en la descripción)
- [ ] PR tiene **agente responsable** asignado.
- [ ] Pasa `analyze`, `format`, linters y tests.
- [ ] Incluye **screenshots**/goldens de UI actualizados.
- [ ] Estados de **error/vacío/loading** cubiertos.
- [ ] **Accesibilidad** revisada (labels, contraste, focus).
- [ ] **i18n** aplicado a las nuevas cadenas.
- [ ] **Telemetry** detrás de flags; sin PII.
- [ ] Documentación y ADR actualizados si aplica.

---

## 14. Plantillas útiles (snippets)
**Bootstrap**
```dart
void main() => bootstrap(() => const MyApp());

Future<void> bootstrap(WidgetBuilder builder) async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) { /* log */ };
  runApp(ProviderScope(child: builder(context!)));
}
```

**HTTP client con Dio**
```dart
final dio = Dio(BaseOptions(
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
));
```

**Router con go_router**
```dart
final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (c, s) => const HomePage()),
  ],
  redirect: (c, s) { /* auth guard */ return null; },
);
```

---

## 15. ADR (Architecture Decision Records)
- Guardar en `docs/adr/NNN-titulo.md` con contexto, decisión y consecuencias.
- Requerido para cambios de librerías core o patrones transversales.

---

## 16. Mantenimiento y gobernanza
- **Revisión mensual** de dependencias y deudas técnicas.
- **Rotación** de agentes críticos (Estado, Datos, Seguridad) cada 2 sprints.
- **SLOs** de build: CI < 10 min, Lint < 2 min, Tests < 5 min.

---

## 17. Roadmap mínimo (plantilla)
- Sprint N: Autenticación + base de navegación.
- Sprint N+1: Offline básico + golden tests.
- Sprint N+2: Telemetría + hardening seguridad.
- Sprint N+3: Accesibilidad avanzada + performance pass.

---

## 18. Referencias rápidas
- Flutter.dev docs, Effective Dart, Riverpod/Bloc docs, go_router, freezed, json_serializable, golden_toolkit, DevTools.

---

## 19. Apéndice: Scripts útiles
```
make setup          # flutter pub get + codegen
make analyze        # dart format + flutter analyze
make test           # unit + widget + golden
make build:beta     # build con flavor beta
```
