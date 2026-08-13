# CLI Task Manager

[![Dart](https://img.shields.io/badge/Dart-3.0%2B-blue)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Un gestionnaire de tâches en CLI écrit en Dart pur.

![CLI Task Manager](docs/TASKLI.png)

## Fonctionnalités

- Ajouter une tâche avec titre, priorité (low/medium/high) et deadline optionnelle
- Ajouter une tâche urgente avec niveau d'urgence (1-5)
- Lister les tâches triées par priorité ou par date
- Filtrer les tâches par statut (terminées / en attente)
- Marquer une tâche comme terminée
- Supprimer une tâche
- Compter les tâches avec filtres
- Sauvegarde automatique dans un fichier JSON local
- Mode interactif et mode commande

## Lancer l'application

```bash
dart pub get
dart run bin/main.dart
```

Le programme démarre en mode interactif. Tapez `help` pour voir les commandes disponibles et `exit` pour quitter.

## Lancer les tests

```bash
dart test
```

## Architecture

Le projet est structuré en plusieurs couches suivant les principes SOLID :

### Couches

- **Modèles** (`lib/src/models/task.dart`) : classe abstraite `Task`, implementations `UrgentTask` et `RegularTask`, enum `Priority` avec extensions
- **Exceptions** (`lib/src/exceptions.dart`) : exceptions métier personnalisées
- **Interfaces** (`lib/src/interfaces.dart`) : contrats `TaskRepository`, `TaskService`, `TaskFormatter`
- **Services** (`lib/src/service.dart`) : `TaskManagerService` contenant la logique métier
- **Persistance** (`lib/src/repository.dart`) : `JsonTaskRepository` pour la sauvegarde/chargement JSON
- **Formatteur** (`lib/src/formatter.dart`) : `ConsoleTaskFormatter` pour l'affichage
- **CLI** (`lib/src/cli.dart`) : `TaskCli` pour l'interaction utilisateur en ligne de commande

### Diagramme des dépendances

```
CLI (TaskCli)
  └── Service (TaskManagerService)
        └── Repository (JsonTaskRepository)
              └── Models (Task, UrgentTask, RegularTask)
        └── Formatter (ConsoleTaskFormatter)
```

## Exemples de commandes

### Mode commande

```bash
# Ajouter une tâche
dart run bin/main.dart add "Faire les courses" high 2026-08-31

# Ajouter une tâche urgente
dart run bin/main.dart add "Corriger le bug" high --urgent 5

# Lister toutes les tâches
dart run bin/main.dart list

# Lister par date de création
dart run bin/main.dart list --date

# Lister seulement les tâches en attente
dart run bin/main.dart list --pending

# Lister seulement les tâches terminées
dart run bin/main.dart list --done

# Marquer une tâche comme terminée
dart run bin/main.dart done abc123

# Supprimer une tâche
dart run bin/main.dart delete xyz789

# Compter les tâches
dart run bin/main.dart count

# Compter les tâches terminées
dart run bin/main.dart count --done

# Afficher l'aide
dart run bin/main.dart --help
```

### Mode interactif

```bash
dart run bin/main.dart --interactive
# ou
dart run bin/main.dart -i
```

```
task-cli> add "Faire les courses" high 2026-08-31
Task added: abc123
[x] Faire les courses (High) | Due: 2026-08-31

task-cli> list
Tasks (1 total, 0 pending, 1 done):
---
[x] Faire les courses (High) | Due: 2026-08-31

task-cli> exit
Goodbye!
```

## Concepts clés

### Priorités

- `low` : Priorité basse
- `medium` : Priorité moyenne
- `high` : Priorité haute

### Tâches urgentes

Les tâches urgentes ont un niveau d'urgence supplémentaire (1-5) qui permet de les distinguer des tâches régulières.

### Tri des tâches

Par défaut, les tâches sont triées par priorité (high > medium > low), puis par deadline (la plus proche en premier).

### Immutabilité

Les modèles de tâches sont immuables. Pour modifier une tâche, utilisez la méthode `copyWith()` qui retourne une nouvelle instance avec les valeurs modifiées.

## Structure du projet

```
cli_task_manager/
├── bin/
│   └── main.dart              # Point d'entrée
├── lib/
│   ├── cli_task_manager.dart  # Library export
│   └── src/
│       ├── cli.dart           # Interface CLI
│       ├── exceptions.dart    # Exceptions métier
│       ├── formatter.dart     # Formatteur de sortie
│       ├── interfaces.dart    # Contrats abstraits
│       ├── models/
│       │   └── task.dart      # Modèles de tâches
│       ├── repository.dart    # Persistance JSON
│       └── service.dart       # Logique métier
├── test/
│   └── task_manager_test.dart # Tests unitaires
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

## Améliorations futures

- [ ] Support pour les sous-tâches
- [ ] Export/Import de tâches
- [ ] Filtres par date (overdue, today, this week)
- [ ] Recherche plein texte
- [ ] Catégories de tâches
- [ ] Notifications pour les deadlines

## Licence

MIT - voir le fichier [LICENSE](LICENSE) pour plus de détails.
