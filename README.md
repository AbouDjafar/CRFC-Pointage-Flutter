# CRFC Pointage Flutter

Application Flutter Android locale-first pour la gestion du pointage CRFC, conçue à partir des maquettes présentes dans [design-screenshots](/C:/Users/Amine/Documents/App%20Flutter%20CRFC%20Pointage/design-screenshots) et du splash de référence [crfc_splash_preview.html](/C:/Users/Amine/Documents/App%20Flutter%20CRFC%20Pointage/crfc_splash_preview.html).

## Fonctionnalités

- Splash animé fidèle au prototype HTML avec logo SVG, anneau rotatif et progression.
- Authentification locale avec session sécurisée.
- Tableau de bord quotidien, historique, analytics et gestion des exports.
- Gestion des employés, utilisateurs et absences récurrentes.
- Rapports journaliers avec calcul des retards à partir de `08:15`.
- Import Excel des employés avec détection souple des colonnes de nom.
- Export PDF administratif et synthèse Excel locale.
- Mode clair et mode sombre.

## Identifiants seedés

- Administrateur
  - login court: `admin`
  - email: `admin@crfc.local`
  - mot de passe: `Admin@2026`
- Agent
  - login court: `agent`
  - email: `agent@crfc.local`
  - mot de passe: `Agent@2026`

## Stack

- Flutter stable
- `flutter_riverpod` pour l'état
- `go_router` pour la navigation
- `drift` + SQLite pour la persistance locale
- `flutter_secure_storage` pour la session
- `file_picker` + `excel` pour l'import/export Excel
- `pdf` + `printing` pour les exports PDF
- `fl_chart` pour les statistiques

## Structure

- [lib/main.dart](/C:/Users/Amine/Documents/App%20Flutter%20CRFC%20Pointage/lib/main.dart)
- [lib/src/app](/C:/Users/Amine/Documents/App%20Flutter%20CRFC%20Pointage/lib/src/app)
- [lib/src/core](/C:/Users/Amine/Documents/App%20Flutter%20CRFC%20Pointage/lib/src/core)
- [lib/src/data](/C:/Users/Amine/Documents/App%20Flutter%20CRFC%20Pointage/lib/src/data)
- [lib/src/features](/C:/Users/Amine/Documents/App%20Flutter%20CRFC%20Pointage/lib/src/features)
- [test](/C:/Users/Amine/Documents/App%20Flutter%20CRFC%20Pointage/test)

## Lancement local

```powershell
.\.tooling\flutter\bin\flutter.bat pub get
.\.tooling\flutter\bin\flutter.bat run
```

Si votre environnement Flutter global est déjà configuré, `flutter run` fonctionne aussi.

## Qualité

```powershell
.\.tooling\flutter\bin\flutter.bat analyze
.\.tooling\flutter\bin\flutter.bat test
```

Sous Windows, certains hooks de native assets peuvent mal gérer les chemins avec espaces. Si besoin, exécutez les commandes depuis un chemin sans espaces ou via un lecteur virtuel `subst`.

## CI / APK

Le workflow GitHub Actions [android.yml](/C:/Users/Amine/Documents/App%20Flutter%20CRFC%20Pointage/.github/workflows/android.yml) :

- installe Java 17 et Flutter stable
- lance `flutter pub get`
- lance `dart run build_runner build --delete-conflicting-outputs`
- exécute `flutter analyze`
- exécute `flutter test`
- génère `flutter build apk --release`
- publie l'APK non signée comme artefact

## Notes métier

- Un seul rapport par date.
- Un employé ne peut pas être à la fois en retard et absent dans le même rapport.
- Un rapport finalisé est verrouillé tant qu'un administrateur ne le rouvre pas.
- Les absences récurrentes sont préchargées au moment de la création d'un nouveau rapport.
