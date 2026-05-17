# Design Export Context

- Generated at: `2026-05-17T20:47:06.552Z`
- Document ID: `3496dbd3-11d1-4748-899a-ed29f3192bd0`
- Page count: 10

## Original Prompt

```text
# Logique Metier CRFC Pointage

## 1. Objet du systeme

Le systeme `CRFC Pointage` sert a enregistrer, consolider, historiser et exploiter les evenements quotidiens de presence du personnel du CRFC.

Le coeur metier repose sur la production d'un **rapport journalier de pointage** pour une date donnee. Ce rapport centralise :

- les employes en retard
- les employes absents
- les motifs d'absence
- le nombre de visiteurs de la journee
- l'auteur du rapport
- l'etat du rapport (`brouillon` ou `finalise`)

Le systeme ne se limite pas a la saisie. Il doit aussi :

- conserver l'historique des rapports
- generer un PDF administratif a partir des donnees metier
- generer une synthese Excel sur une periode
- alimenter des statistiques d'aide a la decision
- gerer un mecanisme d'absences recurrentes

Ce document decrit **uniquement la logique metier**, volontairement sans prescription sur l'interface graphique.

## 2. Vocabulaire du domaine

### 2.1 Utilisateur

Un `Utilisateur` est une personne autorisee a acceder a l'application.

Attributs metier principaux :

- `id`
- `firstName`
- `lastName`
- `email` ou identifiant de connexion
- `password`
- `jobTitle`
- `role`
- `isActive`
- `createdAt`
- `createdBy`

Roles :

- `ADMIN` : acces complet a la gestion des utilisateurs, employes, rapports, exports et configuration
- `AGENT` : saisie et consultation selon le perimetre autorise

Regles :

- un utilisateur inactif ne doit pas pouvoir se connecter
- l'authentification accepte l'email complet ou le login court derive de la partie locale de l'email
- la gestion des utilisateurs est reservee a l'administrateur

### 2.2 Employe

Un `Employe` represente une personne susceptible d'apparaitre dans un rapport de pointage.

Attributs metier principaux :

- `id`
- `fullName`
- `firstName`
- `lastName`
- `isActive`
- `needsReview`
- `importSource`
- `importedAt`

Regles :

- seuls les employes actifs sont eligibles a la saisie des retards et absences
- `needsReview` signale une ambiguite de qualification ou de decoupage du nom lors de l'import
- un employe n'est pas supprime physiquement pour le besoin courant ; on privilegie l'inactivation

### 2.3 Motif d'absence

Un `AbsenceReason` represente un motif metier selectionnable pour justifier une absence.

Attributs :

- `id`
- `label`

Jeu initial attendu :

- `Maladie`
- `Conge`
- `Mission`
- `Permission`
- `Formation`
- `Deplacement`
- `Absence injustifiee`
- `Autre`

Regle importante :

- le motif par defaut d'une absence est `Absence injustifiee`

### 2.4 Absence recurrente

Une `RecurringAbsence` represente une absence a precharger automatiquement lors de la creation du rapport du jour.

Attributs :

- `id`
- `employeeId`
- `reasonId`
- `comment`

Regles :

- un employe ne peut avoir qu'une seule configuration d'absence recurrente active a un instant donne
- l'absence recurrente ne vaut pas rapport journalier en soi ; elle n'est qu'une **source de pre-remplissage**
- le rapport cree a partir des absences recurrentes reste editable

### 2.5 Retard

Un `LateEntry` represente un cas de retard dans un rapport donne.

Attributs :

- `id`
- `employeeId`
- `arrivalTime`
- `minutesLate`
- `note`

Regles :

- l'heure d'arrivee par defaut a la creation d'un retard est `08:30`
- `minutesLate` est une valeur derivee, calculee a partir de `arrivalTime`
- l'heure de reference metier est `08:00`
- si l'heure d'arrivee est inferieure ou egale a `08:00`, le retard calcule est `0`
- si l'heure est superieure a `08:00`, le retard est la difference en minutes entre `arrivalTime` et `08:00`

### 2.6 Absence

Un `AbsenceEntry` represente une absence dans un rapport donne.

Attributs :

- `id`
- `employeeId`
- `reasonId`
- `comment`

Regles :

- toute absence doit avoir un motif
- le commentaire est optionnel
- le motif par defaut est `Absence injustifiee`

### 2.7 Rapport journalier

Le `DailyReport` est l'agregat metier principal.

Attributs :

- `id`
- `date`
- `lateEntries`
- `absenceEntries`
- `visitorCount`
- `introText`
- `status`
- `createdBy`
- `createdAt`
- `updatedAt`
- `pdfPath`

Etats :

- `DRAFT`
- `FINALIZED`

Regles :

- il ne doit exister qu'un seul rapport par date civile
- le rapport porte les evenements d'une journee unique
- l'auteur du rapport est l'utilisateur createur
- le rapport peut etre complete progressivement tant qu'il est en `DRAFT`
- un rapport `FINALIZED` est considere comme verrouille fonctionnellement

## 3. Agregat central et invariants

Le rapport journalier concentre la plupart des invariants du domaine.

### 3.1 Unicite par date

Pour une date donnee :

- un seul rapport doit exister
- toute tentative de creation pour la meme date doit devenir une mise a jour du rapport existant

### 3.2 Exclusivite retard / absence

Pour un meme rapport :

- un employe ne peut apparaitre qu'une seule fois dans les retards
- un employe ne peut apparaitre qu'une seule fois dans les absences
- un employe ne peut pas etre simultanement **retardataire** et **absent** le meme jour

Cette regle est bloquante et non simplement signaletique.

### 3.3 Coherence du statut

Si un rapport est `FINALIZED` :

- il ne doit plus accepter de nouvelles lignes de retard
- il ne doit plus accepter de nouvelles lignes d'absence
- il ne doit plus autoriser la modification du nombre de visiteurs
- il ne doit plus autoriser la suppression d'entrees sans action explicite de reouverture si cette capacite existe

Si un rapport est reouvert :

- son statut repasse a `DRAFT`
- il redevient editable

### 3.4 Calcul et derivees

Certaines valeurs ne sont pas de simples saisies, mais des derivees :

- `minutesLate` derive de `arrivalTime`
- `introText` derive de la date et d'un gabarit administratif
- la majorite des KPI derives des rapports, retards et absences

## 4. Cycle de vie d'un rapport journalier

### 4.1 Initialisation

Lorsqu'un utilisateur demarre le rapport d'une date :

1. le systeme verifie si un rapport existe deja pour cette date
2. si oui, il retourne ce rapport
3. sinon, il cree un nouveau rapport avec :
   - `status = DRAFT`
   - `lateEntries = []`
   - `absenceEntries` precharges depuis les absences recurrentes
   - `visitorCount = 0`
   - `introText` genere automatiquement
   - `createdBy = utilisateur courant`
   - `createdAt = maintenant`
   - `updatedAt = maintenant`

### 4.2 Enrichissement

En mode brouillon, l'utilisateur peut :

- ajouter un retard
- supprimer un retard
- ajouter une absence
- supprimer une absence
- ajuster le nombre de visiteurs

Chaque modification doit mettre a jour `updatedAt`.

### 4.3 Finalisation

La finalisation du rapport :

- change `status` vers `FINALIZED`
- fige le contenu fonctionnel du rapport
- rend le rapport pret a l'export PDF

La finalisation ne doit pas recreer un nouveau rapport ; elle modifie l'agregat existant.

### 4.4 Reouverture

Si le role le permet, un rapport finalise peut etre reouvert.

Effets :

- `status = DRAFT`
- reprise des modifications possibles

Cette action doit etre reservee a un niveau de privilege explicite, en pratique l'administrateur.

### 4.5 Suppression

La suppression d'un rapport retire l'agregat de l'historique.

Effets minimaux attendus :

- suppression du rapport de la persistence locale ou base
- le cas echeant, gestion des fichiers exportes relies au rapport selon la politique retenue

Le systeme ne doit pas supprimer les employes, motifs ou utilisateurs associes.

## 5. Regles de saisie des retards

### 5.1 Entrees requises

Pour ajouter un retard :

- `employeeId` est obligatoire
- `arrivalTime` est obligatoire

### 5.2 Validation

Le systeme doit refuser l'ajout si :

- le rapport n'existe pas
- le rapport est finalise
- l'employe est deja dans les retards du rapport
- l'employe est deja dans les absences du rapport
- le format de l'heure est invalide

### 5.3 Calcul du retard

Reference :

- heure theorique : `08:00`

Exemples :

- `08:00` -> `0` minute
- `08:05` -> `5` minutes
- `08:30` -> `30` minutes
- `09:10` -> `70` minutes

### 5.4 Suppression d'un retard

La suppression d'un retard :

- retire l'entree du rapport
- met a jour `updatedAt`
- reouvre implicitement la possibilite de saisir cet employe en absence pour ce rapport, si le statut le permet

## 6. Regles de saisie des absences

### 6.1 Entrees requises

Pour ajouter une absence :

- `employeeId` obligatoire
- `reasonId` obligatoire
- `comment` optionnel

### 6.2 Validation

Le systeme doit refuser l'ajout si :

- le rapport n'existe pas
- le rapport est finalise
- l'employe est deja dans les absences du rapport
- l'employe est deja dans les retards du rapport
- le motif est absent ou invalide

### 6.3 Valeur par defaut

Par defaut :

- le motif propose doit etre `Absence injustifiee`

### 6.4 Suppression d'une absence

La suppression d'une absence :

- retire l'entree du rapport
- met a jour `updatedAt`
- reouvre implicitement la possibilite de saisir cet employe en retard pour ce rapport, si le statut le permet

## 7. Gestion des visiteurs

Le rapport journalier porte un `visitorCount`.

Regles :

- c'est un entier naturel
- la valeur minimale est `0`
- toute tentative de decrement en-dessous de `0` doit etre ramenee a `0`
- la valeur peut etre modifiee librement tant que le rapport est brouillon

Le systeme ne gere pas, dans le perimetre courant, l'identite individuelle des visiteurs.

## 8. Gestion des absences recurrentes

Les absences recurrentes sont une commodite de saisie et non une historique en elles-memes.

### 8.1 Fonction

Elles servent a pre-remplir les absences du rapport du jour a la creation.

### 8.2 Regles

- une absence recurrente est definie par `employeeId + reasonId + commentaire optionnel`
- un employe ne peut pas avoir plusieurs absences recurrentes simultanees
- une absence recurrente ne doit pas creer d'evenement duplicatif si elle existe deja pour l'employe

### 8.3 Propagation au rapport

Lors de la creation d'un nouveau rapport :

- chaque absence recurrente devient une `AbsenceEntry`
- l'utilisateur peut ensuite modifier ou supprimer ces absences prechargees dans le rapport courant

### 8.4 Non-retroactivite

Modifier une absence recurrente :

- n'altère pas les rapports deja crees
- n'affecte que les futurs rapports non encore initialises

## 9. Gestion des employes

### 9.1 Source initiale

La liste initiale des employes provient d'un import Excel.

### 9.2 Import

Le systeme exploite essentiellement la colonne des noms complets pour construire :

- `fullName`
- `firstName`
- `lastName`
- `importSource`
- `importedAt`
- `needsReview` si l'analyse est ambigue

### 9.3 Activation

L'etat `isActive` determine l'eligibilite d'un employe pour les listes de saisie.

Un employe inactif :

- ne doit pas apparaitre dans les selections de retards ou absences
- peut rester visible dans les donnees de reference et l'historique

### 9.4 Modification

La correction d'un employe porte sur :

- nom
- prenom
- nom complet derive
- etat actif

Cette modification ne doit pas corrompre les rapports historiques. Ceux-ci referencent l'identifiant employe, pas une copie texte libre.

## 10. Gestion des utilisateurs et securite metier

### 10.1 Creation d'utilisateur

La creation d'un utilisateur requiert :

- nom
- prenom
- email
- fonction
- mot de passe
- role

Validations minimales :

- email unique
- mot de passe longueur minimale acceptable
- nom / prenom / fonction non vides

### 10.2 Modification du profil

Un utilisateur doit pouvoir modifier au minimum :

- son nom
- son prenom
- sa fonction

La modification de mot de passe requiert la verification du mot de passe courant.

### 10.3 Suppression d'utilisateur

La suppression d'un utilisateur est restreinte.

Contraintes habituelles deja retenues dans le systeme :

- ne pas supprimer l'admin technique initial
- ne pas permettre a un admin de se supprimer lui-meme si cela compromet l'acces

## 11. Historique et consultation

L'historique metier doit permettre :

- de lister les rapports
- de filtrer par periode
- de distinguer les rapports brouillons et finalises
- d'ouvrir le detail d'un rapport
- de supprimer un rapport si le role le permet

Le detail d'un rapport doit permettre :

- lecture du contenu structure
- export PDF
- finalisation si brouillon
- reouverture si finalise et si le role le permet

## 12. Logique d'export PDF

### 12.1 Nature de l'export

Le PDF n'est pas une saisie libre mais une **projection documentaire** du rapport journalier.

### 12.2 Source de verite

Le contenu du PDF doit etre recalcule a partir :

- du rapport
- des employes
- des motifs d'absence
- de l'auteur du rapport

Le PDF ne doit pas devenir la source de verite metier.

### 12.3 Contenu attendu

Le PDF doit reproduire la structure administrative du compte rendu :

- entete CRFC
- destinataire
- objet
- introduction generee
- tableau des retards
- tableau des absents
- mention des visiteurs
- formule de politesse
- signature et fonction du redacteur

### 12.4 Nom de fichier

Convention cible :

- `rapport-pointage-YYYY-MM-DD.pdf`

### 12.5 Stockage

Dans la version mobile native :

- le fichier est stocke dans un repertoire prive applicatif dedie aux PDF

Le fichier reste gerable par l'application :

- creer
- lister
- renommer
- supprimer
- ouvrir via une application externe compatible

## 13. Logique d'export Excel

### 13.1 Nature de l'export

L'export Excel est une **synthese analytique** sur une periode.

### 13.2 Source de verite

Le contenu est calcule a partir des rapports et de leurs entrees.

### 13.3 Perimetre

Une synthese est definie par :

- une date de debut
- une date de fin
- eventuellement d'autres filtres selon implementation future

### 13.4 Structure attendue

Le fichier doit contenir au minimum :

- `Synthese`
- `Totaux`
- `Retards`
- `Absences`

### 13.5 Nom de fichier

Convention cible :

- `synthese-rapports-START_END.xlsx`

### 13.6 Stockage

Dans la version mobile native :

- le fichier est stocke dans un repertoire prive applicatif dedie aux Excel

Comme pour les PDF, il doit etre :

- listable
- renommable
- supprimable
- ouvrable via une application compatible

## 14. Gestion des fichiers exportes

Le systeme traite les fichiers exportes comme des artefacts geres.

Concept metier :

- `ManagedFile`

Attributs :

- `id`
- `type` (`PDF` ou `EXCEL`)
- `name`
- `uri`
- `mimeType`
- `createdAt`
- `updatedAt`
- `relatedReportId` pour un PDF issu d'un rapport
- `periodStart` / `periodEnd` pour une synthese Excel

Capacites attendues :

- lister
- ouvrir
- renommer
- supprimer
- regenerer si la source metier est encore disponible

Regle importante :

- le renommage agit sur le nom du fichier gere, pas sur les donnees metier du rapport

## 15. Statistiques et analytique

Les statistiques sont derivees des rapports filtres sur une periode.

### 15.1 KPI principaux

Le systeme calcule notamment :

- `reportCount`
- `totalLate`
- `totalAbsence`
- `totalVisitors`
- `totalIncidents`
- `totalLateMinutes`
- `uniqueLateEmployees`
- `uniqueAbsentEmployees`
- `averageLateMinutes`
- `averageArrivalMinutes`

### 15.2 Definition des incidents

`totalIncidents` = `totalLate + totalAbsence`

Il s'agit d'un agrégat de presence anormale, non d'un concept independant.

### 15.3 Series et classements

Le systeme doit pouvoir produire :

- retards par jour
- absences par jour
- repartition des motifs d'absence
- top retardataires
- top absents
- heure moyenne d'arrivee des retardataires
- retard moyen par employe
- jour de pic d'incidents

### 15.4 Regle de calcul des moyennes

Les moyennes ne doivent etre calculees que sur les donnees pertinentes.

Exemples :

- `averageLateMinutes` se calcule sur les retards existants
- `averageArrivalMinutes` se calcule sur les heures d'arrivee des retardataires

Si aucun element n'existe, la vue analytique doit traiter l'absence de donnees explicitement.

## 16. Regles de persistence

### 16.1 Source de persistence

Selon la plateforme, la persistence peut etre :

- base de donnees relationnelle
- stockage local structure

Dans tous les cas, la logique metier suppose une persistence de :

- utilisateurs
- employes
- motifs d'absence
- absences recurrentes
- rapports
- index des fichiers exportes

### 16.2 Versionnement local

Dans le contexte mobile local-first :

- le stockage doit etre versionne
- une migration destructive peut etre acceptee lors de ruptures de schema importantes

### 16.3 Coherence transactionnelle minimale

Pour une operation metier composee, l'etat final doit rester coherent.

Exemples :

- ajouter un retard doit modifier le rapport et persister l'ensemble du rapport mis a jour
- finaliser un rapport doit garantir un `status` coherent apres persistence
- supprimer un rapport ne doit pas laisser de reference invalide dans la liste des rapports

## 17. Cas limites et comportements attendus

### 17.1 Rapport du jour absent

Si l'utilisateur tente une action de saisie avant creation du rapport :

- le systeme doit soit creer le rapport automatiquement
- soit forcer l'initialisation explicite avant la suite

Le comportement retenu aujourd'hui favorise l'initialisation puis la saisie.

### 17.2 Absence de donnees exportables

Si aucun rapport ne correspond a une synthese Excel :

- le systeme doit refuser proprement l'export

Si aucun rapport n'existe pour un PDF :

- l'export PDF doit etre impossible

### 17.3 Fichier introuvable

Si un fichier gere n'existe plus physiquement :

- l'application doit signaler l'erreur
- idealement proposer regeneration ou suppression de l'index

### 17.4 Collision de nom

En cas de renommage ou regeneration :

- le systeme doit gerer les collisions de nom de fichier
- soit par refus explicite
- soit par ecrasement controle
- soit par renommage derive

La politique choisie doit rester consistante.

### 17.5 Validation des heures

Une heure de retard doit rester interpretable par la logique metier.

Formats invalides a rejeter :

- chaine vide
- valeurs non numeriques
- heure hors plage valide

## 18. Hypotheses structurantes

Les hypotheses suivantes sont implicites dans la logique actuelle :

- la journee de pointage est indexee par date civile simple
- l'heure de reference de ponctualite est `08:15`
- les visiteurs sont un compteur, non une entite detaillee
- un employe est identifie par un `id` stable
- les rapports historiques restent des sources d'analyse prioritaires
- l'export PDF et l'export Excel sont des produits derives, jamais la source de verite

## 19. Recommandations pour un agent IA implementant le domaine

Un agent qui reimplemente ou etend ce systeme doit respecter les priorites suivantes :

1. considerer le `DailyReport` comme l'agregat central
2. faire respecter les invariants d'exclusivite retard/absence
3. traiter les absences recurrentes comme du pre-remplissage, pas comme de l'historique
4. recalculer les derivees plutot que les dupliquer inutilement
5. separer nettement :
   - donnees de reference
   - donnees operationnelles du jour
   - artefacts exportes
   - analytics derivees
6. ne jamais laisser l'interface imposer la logique : l'UI peut varier, les regles metier ne doivent pas varier

## 20. Resume decisionnel

Le domaine `CRFC Pointage` est un systeme de **gestion quotidienne de presence** centre sur un **rapport unique par jour**, dont le contenu est structure par **retards**, **absences**, **visiteurs** et **auteur**.

Les contraintes les plus critiques sont :

- unicite du rapport par date
- exclusivite retard/absence pour un meme employe et un meme jour
- blocage des modifications apres finalisation
- calcul deterministe du retard a partir de `08:15`
- prechargement des absences recurrentes lors de la creation du rapport
- generation documentaire et analytique a partir des donnees metier, jamais l'inverse

Tout futur systeme, quel que soit son choix de presentation, doit reproduire fidelement ces regles.
```

## Theme (JSON)

```json
{
  "schema_version": 2,
  "fonts": {
    "primary": "google:Source Sans Pro",
    "secondary": "google:Source Sans Pro",
    "mono": "google:JetBrains Mono"
  },
  "colors": {
    "light": {
      "primary": "#C0771B",
      "on_primary": "#FFFFFF",
      "primary_container": "#1A947D",
      "on_primary_container": "#1A1A1A",
      "secondary": "#6B5C73",
      "on_secondary": "#FFFFFF",
      "secondary_container": "#1A733E",
      "on_secondary_container": "#FFFFFF",
      "accent": "#4A5D7C",
      "on_accent": "#FFFFFF",
      "accent_container": "#4A7C591A",
      "on_accent_container": "#1A1A1A",
      "background": "#E5F2E4",
      "on_background": "#1A1A1A",
      "secondary_background": "#D9EBD8",
      "surface": "#F7FCF7",
      "on_surface": "#1A1A1A",
      "surface_variant": "#E5F2E4",
      "on_surface_variant": "#545454",
      "primary_text": "#1A1A1A",
      "secondary_text": "#545454",
      "hint": "#000000",
      "outline": "#BCD1BA",
      "divider": "#CCE0CB",
      "success": "#4A7C59",
      "on_success": "#FFFFFF",
      "warning": "#C87941",
      "on_warning": "#FFFFFF",
      "error": "#B23B3B",
      "on_error": "#FFFFFF",
      "info": "#2E5894",
      "on_info": "#FFFFFF",
      "transparent": "#00000000",
      "full_contrast": "#000000"
    },
    "dark": {
      "primary": "#DB8CE6",
      "on_primary": "#FFFFFF",
      "primary_container": "#24E694",
      "on_primary_container": "#000000",
      "secondary": "#A8A0AD",
      "on_secondary": "#FFFFFF",
      "secondary_container": "#24AD53",
      "on_secondary_container": "#FFFFFF",
      "accent": "#8E9CB6",
      "on_accent": "#FFFFFF",
      "accent_container": "#8EB69B24",
      "on_accent_container": "#F2EDE4",
      "background": "#191C19",
      "on_background": "#E5F2E4",
      "secondary_background": "#232622",
      "surface": "#282D28",
      "on_surface": "#E5F2E4",
      "surface_variant": "#373D36",
      "on_surface_variant": "#A6B8A5",
      "primary_text": "#E5F2E4",
      "secondary_text": "#A6B8A5",
      "hint": "#FFFFFF",
      "outline": "#454F44",
      "divider": "#373D36",
      "success": "#8EB69B",
      "on_success": "#FFFFFF",
      "warning": "#E6A26A",
      "on_warning": "#FFFFFF",
      "error": "#E67A7A",
      "on_error": "#FFFFFF",
      "info": "#8CB3E6",
      "on_info": "#FFFFFF",
      "transparent": "#00000000",
      "full_contrast": "#FFFFFF"
    }
  },
  "text_styles": {
    "display_large": {
      "font": "primary",
      "size": 56,
      "weight": 700,
      "height": 1.2
    },
    "display_medium": {
      "font": "primary",
      "size": 44,
      "weight": 700,
      "height": 1.2
    },
    "display_small": {
      "font": "primary",
      "size": 36,
      "weight": 700,
      "height": 1.2
    },
    "headline_large": {
      "font": "primary",
      "size": 32,
      "weight": 600,
      "height": 1.3
    },
    "headline_medium": {
      "font": "primary",
      "size": 26,
      "weight": 600,
      "height": 1.3
    },
    "headline_small": {
      "font": "primary",
      "size": 24,
      "weight": 600,
      "height": 1.3
    },
    "title_large": {
      "font": "primary",
      "size": 20,
      "weight": 600,
      "height": 1.4
    },
    "title_medium": {
      "font": "primary",
      "size": 17,
      "weight": 600,
      "height": 1.4
    },
    "title_small": {
      "font": "primary",
      "size": 14,
      "weight": 600,
      "height": 1.4
    },
    "body_large": {
      "font": "primary",
      "size": 17,
      "weight": 400,
      "height": 1.7
    },
    "body_medium": {
      "font": "primary",
      "size": 15,
      "weight": 400,
      "height": 1.7
    },
    "body_small": {
      "font": "primary",
      "size": 13,
      "weight": 400,
      "height": 1.7
    },
    "label_large": {
      "font": "primary",
      "size": 15,
      "weight": 600,
      "height": 1.4
    },
    "label_medium": {
      "font": "primary",
      "size": 13,
      "weight": 600,
      "height": 1.4
    },
    "label_small": {
      "font": "primary",
      "size": 11,
      "weight": 600,
      "height": 1.4
    }
  },
  "spacing": {
    "none": 0,
    "xs": 4,
    "sm": 8,
    "md": 16,
    "lg": 24,
    "xl": 32,
    "xxl": 48,
    "xxxl": 64
  },
  "radii": {
    "none": 0,
    "xs": 2,
    "sm": 4,
    "md": 6,
    "lg": 8,
    "xl": 12,
    "xxl": 16,
    "full": 9999
  },
  "shadows": {
    "none": {
      "color": "#00000000",
      "dx": 0,
      "dy": 0,
      "blur": 0,
      "spread": 0
    },
    "xs": {
      "color": "#0000000D",
      "dx": 0,
      "dy": 1,
      "blur": 2,
      "spread": 0
    },
    "sm": {
      "color": "#00000014",
      "dx": 0,
      "dy": 2,
      "blur": 4,
      "spread": 0
    },
    "md": {
      "color": "#00000014",
      "dx": 0,
      "dy": 4,
      "blur": 8,
      "spread": 0
    },
    "lg": {
      "color": "#0000001A",
      "dx": 0,
      "dy": 8,
      "blur": 16,
      "spread": 0
    },
    "xl": {
      "color": "#0000001A",
      "dx": 0,
      "dy": 12,
      "blur": 24,
      "spread": 0
    },
    "xxl": {
      "color": "#00000026",
      "dx": 0,
      "dy": 16,
      "blur": 32,
      "spread": 0
    }
  },
  "gradients": {}
}
```

## Pages

### 1. Login

- Frame ID: `frame2`
- Original page prompt: "Authentication screen for Agents and Admins with email/login and password fields."
- Follow-up prompts: _None_

#### DslDocument (JSON)

```json
{
  "root": {
    "type": "scaffold",
    "properties": {
      "bg": {
        "color": {
          "color": "#F2EDE4"
        }
      },
      "safe_area": {
        "boolVal": {
          "value": true
        }
      }
    },
    "children": [
      {
        "type": "column",
        "properties": {
          "cross_align": {
            "align": {
              "named": "stretch"
            }
          },
          "align": {
            "align": {
              "named": "space_between"
            }
          }
        },
        "children": [
          {
            "type": "column",
            "properties": {
              "cross_align": {
                "align": {
                  "named": "stretch"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "token": "lg"
                }
              }
            },
            "children": [
              {
                "type": "container",
                "properties": {
                  "align_child": {
                    "align": {
                      "named": "center"
                    }
                  },
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "token": "xl"
                    }
                  }
                },
                "children": [
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "container",
                        "properties": {
                          "width": {
                            "px": {
                              "value": 80,
                              "isInfinity": false
                            }
                          },
                          "height": {
                            "px": {
                              "value": 80,
                              "isInfinity": false
                            }
                          },
                          "bg": {
                            "color": {
                              "color": "#1A4B84"
                            }
                          },
                          "radius": {
                            "radius": {
                              "topLeft": 6,
                              "topRight": 6,
                              "bottomLeft": 6,
                              "bottomRight": 6
                            }
                          },
                          "align_child": {
                            "align": {
                              "named": "center"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "icon",
                            "properties": {
                              "name": {
                                "icon": {
                                  "name": "pen_size_rounded"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "#F2EDE4"
                                }
                              },
                              "size": {
                                "numberVal": {
                                  "value": 42
                                }
                              }
                            },
                            "editorId": "icon9"
                          }
                        ],
                        "editorId": "container20"
                      },
                      {
                        "type": "column",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "xs"
                            }
                          },
                          "cross_align": {
                            "align": {
                              "named": "center"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "CRFC Pointage"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "headline_medium"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "#1A4B84"
                                }
                              },
                              "font_weight": {
                                "stringVal": {
                                  "value": "bold"
                                }
                              }
                            },
                            "editorId": "text37"
                          },
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "Système de Gestion des Présences"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "label_medium"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "secondary_text"
                                }
                              }
                            },
                            "editorId": "text38"
                          }
                        ],
                        "editorId": "column19"
                      }
                    ],
                    "editorId": "column18"
                  }
                ],
                "editorId": "container19"
              }
            ],
            "editorId": "column17"
          },
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "radius": {
                "radius": {
                  "topLeft": 6,
                  "topRight": 6,
                  "bottomLeft": 0,
                  "bottomRight": 0
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "topToken": "xl",
                  "rightToken": "lg",
                  "bottomToken": "xl",
                  "leftToken": "lg"
                }
              },
              "border": {
                "border": {
                  "width": 1,
                  "color": "divider"
                }
              }
            },
            "children": [
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "lg"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "stretch"
                    }
                  }
                },
                "children": [
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "xs"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Connexion"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "title_large"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary_text"
                            }
                          }
                        },
                        "editorId": "text39"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Veuillez entrer vos identifiants pour accéder au tableau de bord."
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "body_medium"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          }
                        },
                        "editorId": "text40"
                      }
                    ],
                    "editorId": "column21"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "stretch"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "@login_field",
                        "properties": {
                          "label": {
                            "stringVal": {
                              "value": "IDENTIFIANT OU EMAIL"
                            }
                          },
                          "hint": {
                            "stringVal": {
                              "value": "ex: j.dupont"
                            }
                          },
                          "icon": {
                            "stringVal": {
                              "value": "person_outline_rounded"
                            }
                          }
                        },
                        "editorId": "loginfield1"
                      },
                      {
                        "type": "column",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "xs"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "@login_field",
                            "properties": {
                              "label": {
                                "stringVal": {
                                  "value": "MOT DE PASSE"
                                }
                              },
                              "hint": {
                                "stringVal": {
                                  "value": "••••••••"
                                }
                              },
                              "icon": {
                                "stringVal": {
                                  "value": "lock_open_rounded"
                                }
                              }
                            },
                            "editorId": "loginfield2"
                          },
                          {
                            "type": "row",
                            "properties": {
                              "align": {
                                "align": {
                                  "named": "end"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "@std.button",
                                "properties": {
                                  "content": {
                                    "stringVal": {
                                      "value": "Mot de passe oublié ?"
                                    }
                                  },
                                  "variant": {
                                    "stringVal": {
                                      "value": "ghost"
                                    }
                                  },
                                  "size": {
                                    "stringVal": {
                                      "value": "small"
                                    }
                                  }
                                },
                                "editorId": "stdbutton1"
                              }
                            ],
                            "editorId": "row18"
                          }
                        ],
                        "editorId": "column23"
                      }
                    ],
                    "editorId": "column22"
                  },
                  {
                    "type": "@std.button",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "Se connecter"
                        }
                      },
                      "variant": {
                        "stringVal": {
                          "value": "primary"
                        }
                      },
                      "full_width": {
                        "boolVal": {
                          "value": true
                        }
                      },
                      "size": {
                        "stringVal": {
                          "value": "large"
                        }
                      },
                      "icon": {
                        "stringVal": {
                          "value": "login_rounded"
                        }
                      },
                      "bg": {
                        "color": {
                          "color": "#1A4B84"
                        }
                      }
                    },
                    "editorId": "button2"
                  }
                ],
                "editorId": "column20"
              }
            ],
            "editorId": "container21"
          },
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "token": "md"
                }
              },
              "border": {
                "borderSided": {
                  "side": "top",
                  "width": 1,
                  "color": "divider"
                }
              }
            },
            "children": [
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "xs"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "center"
                    }
                  }
                },
                "children": [
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "Civic Functionalism v2.4"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "label_small"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "secondary_text",
                          "opacityPercent": 60
                        }
                      }
                    },
                    "editorId": "text41"
                  },
                  {
                    "type": "row",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "xs"
                        }
                      },
                      "align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "icon",
                        "properties": {
                          "name": {
                            "icon": {
                              "name": "security_rounded"
                            }
                          },
                          "size": {
                            "numberVal": {
                              "value": 12
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text",
                              "opacityPercent": 60
                            }
                          }
                        },
                        "editorId": "icon10"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Accès sécurisé réservé au personnel du CRFC"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_small"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text",
                              "opacityPercent": 60
                            }
                          }
                        },
                        "editorId": "text42"
                      }
                    ],
                    "editorId": "row19"
                  }
                ],
                "editorId": "column24"
              }
            ],
            "editorId": "container22"
          }
        ],
        "editorId": "column16"
      }
    ],
    "editorId": "scaffold1"
  }
}
```

### 2. Dashboard

- Frame ID: `frame9`
- Original page prompt: "Main navigation hub showing the current date's report status, quick actions to start a new report, and summary KPIs."
- Follow-up prompts: _None_

#### DslDocument (JSON)

```json
{
  "root": {
    "type": "scaffold",
    "properties": {
      "bg": {
        "color": {
          "color": "#F2EDE4"
        }
      }
    },
    "children": [
      {
        "type": "column",
        "properties": {
          "cross_align": {
            "align": {
              "named": "stretch"
            }
          }
        },
        "children": [
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 40,
                  "right": 24,
                  "bottom": 24,
                  "left": 24
                }
              },
              "border": {
                "borderSided": {
                  "side": "bottom",
                  "width": 1,
                  "color": "divider"
                }
              }
            },
            "children": [
              {
                "type": "row",
                "properties": {
                  "align": {
                    "align": {
                      "named": "space_between"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "center"
                    }
                  }
                },
                "children": [
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "xs"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Bonjour, Admin"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_large"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          }
                        },
                        "editorId": "text43"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Tableau de Bord"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "headline_small"
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary_text"
                            }
                          }
                        },
                        "editorId": "text44"
                      }
                    ],
                    "editorId": "column26"
                  },
                  {
                    "type": "avatar",
                    "properties": {
                      "text": {
                        "stringVal": {
                          "value": "AD"
                        }
                      },
                      "bg": {
                        "color": {
                          "color": "#E5E1D8"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "primary_text"
                        }
                      },
                      "size": {
                        "numberVal": {
                          "value": 44
                        }
                      },
                      "radius": {
                        "radius": {
                          "topLeft": 6,
                          "topRight": 6,
                          "bottomLeft": 6,
                          "bottomRight": 6
                        }
                      }
                    },
                    "editorId": "avatar3"
                  }
                ],
                "editorId": "row20"
              }
            ],
            "editorId": "container23"
          },
          {
            "type": "expanded",
            "children": [
              {
                "type": "column",
                "properties": {
                  "scroll": {
                    "boolVal": {
                      "value": true
                    }
                  },
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "token": "lg"
                    }
                  },
                  "spacing": {
                    "stringVal": {
                      "value": "lg"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "stretch"
                    }
                  }
                },
                "children": [
                  {
                    "type": "container",
                    "properties": {
                      "bg": {
                        "color": {
                          "color": "#E5E1D8"
                        }
                      },
                      "padding": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "token": "lg"
                        }
                      },
                      "radius": {
                        "radius": {
                          "topLeft": 6,
                          "topRight": 6,
                          "bottomLeft": 6,
                          "bottomRight": 6
                        }
                      },
                      "border": {
                        "border": {
                          "width": 1,
                          "color": "outline"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "row",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "md"
                            }
                          },
                          "cross_align": {
                            "align": {
                              "named": "center"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "container",
                            "properties": {
                              "width": {
                                "px": {
                                  "value": 12,
                                  "isInfinity": false
                                }
                              },
                              "height": {
                                "px": {
                                  "value": 12,
                                  "isInfinity": false
                                }
                              },
                              "bg": {
                                "color": {
                                  "color": "warning"
                                }
                              },
                              "shape": {
                                "stringVal": {
                                  "value": "circle"
                                }
                              }
                            },
                            "editorId": "container25"
                          },
                          {
                            "type": "column",
                            "properties": {
                              "cross_align": {
                                "align": {
                                  "named": "start"
                                }
                              },
                              "expanded": {
                                "expanded": {
                                  "enabled": true,
                                  "flex": 1
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "text",
                                "properties": {
                                  "content": {
                                    "stringVal": {
                                      "value": "Rapport du 24 Octobre"
                                    }
                                  },
                                  "style": {
                                    "textStyle": {
                                      "styleName": "title_medium"
                                    }
                                  },
                                  "font_weight": {
                                    "numberVal": {
                                      "value": 600
                                    }
                                  }
                                },
                                "editorId": "text45"
                              },
                              {
                                "type": "text",
                                "properties": {
                                  "content": {
                                    "stringVal": {
                                      "value": "Statut : Brouillon • 5 entrées"
                                    }
                                  },
                                  "style": {
                                    "textStyle": {
                                      "styleName": "body_small"
                                    }
                                  },
                                  "color": {
                                    "color": {
                                      "color": "secondary_text"
                                    }
                                  }
                                },
                                "editorId": "text46"
                              }
                            ],
                            "editorId": "column28"
                          },
                          {
                            "type": "@std.button",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "Reprendre"
                                }
                              },
                              "variant": {
                                "stringVal": {
                                  "value": "primary"
                                }
                              },
                              "size": {
                                "stringVal": {
                                  "value": "small"
                                }
                              }
                            },
                            "editorId": "stdbutton2"
                          }
                        ],
                        "editorId": "row21"
                      }
                    ],
                    "editorId": "container24"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "SYNTHÈSE DU JOUR"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_small"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          }
                        },
                        "editorId": "text47"
                      },
                      {
                        "type": "row",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "md"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "@stat_card",
                            "properties": {
                              "label": {
                                "stringVal": {
                                  "value": "Retards"
                                }
                              },
                              "value": {
                                "stringVal": {
                                  "value": "02"
                                }
                              },
                              "icon": {
                                "stringVal": {
                                  "value": "schedule_rounded"
                                }
                              },
                              "color": {
                                "stringVal": {
                                  "value": "warning"
                                }
                              },
                              "desc": {
                                "stringVal": {
                                  "value": "Depuis 08:15"
                                }
                              }
                            },
                            "editorId": "statcard1"
                          },
                          {
                            "type": "@stat_card",
                            "properties": {
                              "label": {
                                "stringVal": {
                                  "value": "Absences"
                                }
                              },
                              "value": {
                                "stringVal": {
                                  "value": "03"
                                }
                              },
                              "icon": {
                                "stringVal": {
                                  "value": "event_busy_rounded"
                                }
                              },
                              "color": {
                                "stringVal": {
                                  "value": "error"
                                }
                              },
                              "desc": {
                                "stringVal": {
                                  "value": "Motifs variés"
                                }
                              }
                            },
                            "editorId": "statcard2"
                          }
                        ],
                        "editorId": "row22"
                      },
                      {
                        "type": "row",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "md"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "@stat_card",
                            "properties": {
                              "label": {
                                "stringVal": {
                                  "value": "Visiteurs"
                                }
                              },
                              "value": {
                                "stringVal": {
                                  "value": "12"
                                }
                              },
                              "icon": {
                                "stringVal": {
                                  "value": "group_rounded"
                                }
                              },
                              "color": {
                                "stringVal": {
                                  "value": "info"
                                }
                              },
                              "desc": {
                                "stringVal": {
                                  "value": "Flux total"
                                }
                              }
                            },
                            "editorId": "statcard3"
                          },
                          {
                            "type": "@stat_card",
                            "properties": {
                              "label": {
                                "stringVal": {
                                  "value": "Incidents"
                                }
                              },
                              "value": {
                                "stringVal": {
                                  "value": "05"
                                }
                              },
                              "icon": {
                                "stringVal": {
                                  "value": "assessment_rounded"
                                }
                              },
                              "color": {
                                "stringVal": {
                                  "value": "primary_text"
                                }
                              },
                              "desc": {
                                "stringVal": {
                                  "value": "Total journalier"
                                }
                              }
                            },
                            "editorId": "statcard4"
                          }
                        ],
                        "editorId": "row23"
                      }
                    ],
                    "editorId": "column29"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "ACTIONS RAPIDES"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_small"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          }
                        },
                        "editorId": "text48"
                      },
                      {
                        "type": "@action_tile",
                        "properties": {
                          "title": {
                            "stringVal": {
                              "value": "Nouveau Rapport"
                            }
                          },
                          "subtitle": {
                            "stringVal": {
                              "value": "Initialiser la saisie du jour"
                            }
                          },
                          "icon": {
                            "stringVal": {
                              "value": "add_task_rounded"
                            }
                          },
                          "bg_color": {
                            "color": {
                              "color": "#E5E1D8"
                            }
                          },
                          "icon_color": {
                            "stringVal": {
                              "value": "primary_text"
                            }
                          }
                        },
                        "editorId": "actiontile1"
                      },
                      {
                        "type": "@action_tile",
                        "properties": {
                          "title": {
                            "stringVal": {
                              "value": "Historique"
                            }
                          },
                          "subtitle": {
                            "stringVal": {
                              "value": "Consulter les rapports passés"
                            }
                          },
                          "icon": {
                            "stringVal": {
                              "value": "history_rounded"
                            }
                          },
                          "bg_color": {
                            "color": {
                              "color": "#E5E1D8"
                            }
                          },
                          "icon_color": {
                            "stringVal": {
                              "value": "primary_text"
                            }
                          }
                        },
                        "editorId": "actiontile2"
                      },
                      {
                        "type": "@action_tile",
                        "properties": {
                          "title": {
                            "stringVal": {
                              "value": "Exports & Analyses"
                            }
                          },
                          "subtitle": {
                            "stringVal": {
                              "value": "Générer PDF ou Excel"
                            }
                          },
                          "icon": {
                            "stringVal": {
                              "value": "description_rounded"
                            }
                          },
                          "bg_color": {
                            "color": {
                              "color": "#E5E1D8"
                            }
                          },
                          "icon_color": {
                            "stringVal": {
                              "value": "primary_text"
                            }
                          }
                        },
                        "editorId": "actiontile3"
                      }
                    ],
                    "editorId": "column30"
                  },
                  {
                    "type": "container",
                    "properties": {
                      "bg": {
                        "color": {
                          "color": "surface"
                        }
                      },
                      "padding": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "token": "lg"
                        }
                      },
                      "radius": {
                        "radius": {
                          "topLeft": 6,
                          "topRight": 6,
                          "bottomLeft": 6,
                          "bottomRight": 6
                        }
                      },
                      "border": {
                        "border": {
                          "width": 1,
                          "color": "divider"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "column",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "md"
                            }
                          },
                          "cross_align": {
                            "align": {
                              "named": "stretch"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "row",
                            "properties": {
                              "align": {
                                "align": {
                                  "named": "space_between"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "text",
                                "properties": {
                                  "content": {
                                    "stringVal": {
                                      "value": "Tendance (7 jours)"
                                    }
                                  },
                                  "style": {
                                    "textStyle": {
                                      "styleName": "label_large"
                                    }
                                  },
                                  "color": {
                                    "color": {
                                      "color": "primary_text"
                                    }
                                  }
                                },
                                "editorId": "text49"
                              },
                              {
                                "type": "text",
                                "properties": {
                                  "content": {
                                    "stringVal": {
                                      "value": "Voir plus"
                                    }
                                  },
                                  "style": {
                                    "textStyle": {
                                      "styleName": "label_small"
                                    }
                                  },
                                  "color": {
                                    "color": {
                                      "color": "#4A6572"
                                    }
                                  }
                                },
                                "editorId": "text50"
                              }
                            ],
                            "editorId": "row24"
                          },
                          {
                            "type": "container",
                            "properties": {
                              "height": {
                                "px": {
                                  "value": 120,
                                  "isInfinity": false
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "bar_chart",
                                "properties": {
                                  "data": {
                                    "stringVal": {
                                      "value": "4,6,2,5,8,3,5"
                                    }
                                  },
                                  "labels": {
                                    "stringVal": {
                                      "value": "L,M,M,J,V,S,D"
                                    }
                                  },
                                  "color": {
                                    "color": {
                                      "color": "#4A6572"
                                    }
                                  },
                                  "bar_radius": {
                                    "numberVal": {
                                      "value": 2
                                    }
                                  },
                                  "show_labels": {
                                    "boolVal": {
                                      "value": true
                                    }
                                  }
                                },
                                "editorId": "barchart1"
                              }
                            ],
                            "editorId": "container27"
                          }
                        ],
                        "editorId": "column31"
                      }
                    ],
                    "editorId": "container26"
                  }
                ],
                "editorId": "column27"
              }
            ],
            "editorId": "expanded1"
          },
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "topToken": "md",
                  "rightToken": "lg",
                  "bottomToken": "md",
                  "leftToken": "lg"
                }
              },
              "border": {
                "borderSided": {
                  "side": "top",
                  "width": 1,
                  "color": "divider"
                }
              }
            },
            "children": [
              {
                "type": "row",
                "properties": {
                  "align": {
                    "align": {
                      "named": "space_around"
                    }
                  }
                },
                "children": [
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "xs"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "icon",
                        "properties": {
                          "name": {
                            "icon": {
                              "name": "home_rounded"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary_text"
                            }
                          }
                        },
                        "editorId": "icon11"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Accueil"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_small"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary_text"
                            }
                          }
                        },
                        "editorId": "text51"
                      }
                    ],
                    "editorId": "column32"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "xs"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "icon",
                        "properties": {
                          "name": {
                            "icon": {
                              "name": "people_outline_rounded"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          }
                        },
                        "editorId": "icon12"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Personnel"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_small"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          }
                        },
                        "editorId": "text52"
                      }
                    ],
                    "editorId": "column33"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "xs"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "icon",
                        "properties": {
                          "name": {
                            "icon": {
                              "name": "settings_outline_rounded"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          }
                        },
                        "editorId": "icon13"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Réglages"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_small"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          }
                        },
                        "editorId": "text53"
                      }
                    ],
                    "editorId": "column34"
                  }
                ],
                "editorId": "row25"
              }
            ],
            "editorId": "container28"
          }
        ],
        "editorId": "column25"
      }
    ],
    "editorId": "scaffold2"
  }
}
```

### 3. Daily Report Management

- Frame ID: `frame1`
- Original page prompt: "Central interface to add/remove late entries and absences, pre-filled with recurring absences, including a visitor counter and finalization button."
- Follow-up prompts: _None_

#### DslDocument (JSON)

```json
{
  "root": {
    "type": "scaffold",
    "properties": {
      "bg": {
        "color": {
          "color": "background"
        }
      }
    },
    "children": [
      {
        "type": "column",
        "properties": {
          "cross_align": {
            "align": {
              "named": "stretch"
            }
          }
        },
        "children": [
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "topToken": "lg",
                  "rightToken": "md",
                  "bottomToken": "lg",
                  "leftToken": "md"
                }
              },
              "border": {
                "borderSided": {
                  "side": "bottom",
                  "width": 1,
                  "color": "divider"
                }
              }
            },
            "children": [
              {
                "type": "row",
                "properties": {
                  "align": {
                    "align": {
                      "named": "space_between"
                    }
                  }
                },
                "children": [
                  {
                    "type": "iconbutton",
                    "properties": {
                      "name": {
                        "icon": {
                          "name": "chevron_left_rounded"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "primary_text"
                        }
                      }
                    },
                    "editorId": "iconbutton6"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "xs"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "RAPPORT JOURNALIER"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_small"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          }
                        },
                        "editorId": "text54"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Lundi 24 Octobre 2023"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "title_medium"
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          }
                        },
                        "editorId": "text55"
                      }
                    ],
                    "editorId": "column36"
                  },
                  {
                    "type": "iconbutton",
                    "properties": {
                      "name": {
                        "icon": {
                          "name": "chevron_right_rounded"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "primary_text"
                        }
                      }
                    },
                    "editorId": "iconbutton7"
                  }
                ],
                "editorId": "row26"
              }
            ],
            "editorId": "container29"
          },
          {
            "type": "expanded",
            "children": [
              {
                "type": "column",
                "properties": {
                  "scroll": {
                    "boolVal": {
                      "value": true
                    }
                  },
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "token": "lg"
                    }
                  },
                  "spacing": {
                    "stringVal": {
                      "value": "lg"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "stretch"
                    }
                  }
                },
                "children": [
                  {
                    "type": "container",
                    "properties": {
                      "bg": {
                        "color": {
                          "color": "info_container"
                        }
                      },
                      "padding": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "token": "md"
                        }
                      },
                      "radius": {
                        "radius": {
                          "topLeft": 0,
                          "topRight": 0,
                          "bottomLeft": 0,
                          "bottomRight": 0,
                          "token": "md"
                        }
                      },
                      "border": {
                        "border": {
                          "width": 1,
                          "color": "info"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "row",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "md"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "icon",
                            "properties": {
                              "name": {
                                "icon": {
                                  "name": "edit_note_rounded"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "on_info_container"
                                }
                              }
                            },
                            "editorId": "icon14"
                          },
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "Statut : Brouillon"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "body_medium"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "on_info_container"
                                }
                              },
                              "font_weight": {
                                "numberVal": {
                                  "value": 600
                                }
                              }
                            },
                            "editorId": "text56"
                          }
                        ],
                        "editorId": "row27"
                      }
                    ],
                    "editorId": "container30"
                  },
                  {
                    "type": "container",
                    "properties": {
                      "bg": {
                        "color": {
                          "color": "surface"
                        }
                      },
                      "padding": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "token": "lg"
                        }
                      },
                      "radius": {
                        "radius": {
                          "topLeft": 0,
                          "topRight": 0,
                          "bottomLeft": 0,
                          "bottomRight": 0,
                          "token": "md"
                        }
                      },
                      "border": {
                        "border": {
                          "width": 1,
                          "color": "divider"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "row",
                        "properties": {
                          "align": {
                            "align": {
                              "named": "space_between"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "column",
                            "properties": {
                              "cross_align": {
                                "align": {
                                  "named": "start"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "text",
                                "properties": {
                                  "content": {
                                    "stringVal": {
                                      "value": "Visiteurs"
                                    }
                                  },
                                  "style": {
                                    "textStyle": {
                                      "styleName": "title_medium"
                                    }
                                  }
                                },
                                "editorId": "text57"
                              },
                              {
                                "type": "text",
                                "properties": {
                                  "content": {
                                    "stringVal": {
                                      "value": "Compte total de la journée"
                                    }
                                  },
                                  "style": {
                                    "textStyle": {
                                      "styleName": "body_small"
                                    }
                                  },
                                  "color": {
                                    "color": {
                                      "color": "secondary_text"
                                    }
                                  }
                                },
                                "editorId": "text58"
                              }
                            ],
                            "editorId": "column38"
                          },
                          {
                            "type": "row",
                            "properties": {
                              "spacing": {
                                "stringVal": {
                                  "value": "md"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "container",
                                "properties": {
                                  "width": {
                                    "px": {
                                      "value": 40,
                                      "isInfinity": false
                                    }
                                  },
                                  "height": {
                                    "px": {
                                      "value": 40,
                                      "isInfinity": false
                                    }
                                  },
                                  "bg": {
                                    "color": {
                                      "color": "background"
                                    }
                                  },
                                  "radius": {
                                    "radius": {
                                      "topLeft": 0,
                                      "topRight": 0,
                                      "bottomLeft": 0,
                                      "bottomRight": 0,
                                      "token": "sm"
                                    }
                                  },
                                  "border": {
                                    "border": {
                                      "width": 1,
                                      "color": "divider"
                                    }
                                  },
                                  "align_child": {
                                    "align": {
                                      "named": "center"
                                    }
                                  }
                                },
                                "children": [
                                  {
                                    "type": "iconbutton",
                                    "properties": {
                                      "name": {
                                        "icon": {
                                          "name": "remove_rounded"
                                        }
                                      },
                                      "color": {
                                        "color": {
                                          "color": "primary_text"
                                        }
                                      }
                                    },
                                    "editorId": "iconbutton8"
                                  }
                                ],
                                "editorId": "container32"
                              },
                              {
                                "type": "text",
                                "properties": {
                                  "content": {
                                    "stringVal": {
                                      "value": "12"
                                    }
                                  },
                                  "style": {
                                    "textStyle": {
                                      "styleName": "headline_small"
                                    }
                                  },
                                  "font_weight": {
                                    "stringVal": {
                                      "value": "bold"
                                    }
                                  }
                                },
                                "editorId": "text59"
                              },
                              {
                                "type": "container",
                                "properties": {
                                  "width": {
                                    "px": {
                                      "value": 40,
                                      "isInfinity": false
                                    }
                                  },
                                  "height": {
                                    "px": {
                                      "value": 40,
                                      "isInfinity": false
                                    }
                                  },
                                  "bg": {
                                    "color": {
                                      "color": "background"
                                    }
                                  },
                                  "radius": {
                                    "radius": {
                                      "topLeft": 0,
                                      "topRight": 0,
                                      "bottomLeft": 0,
                                      "bottomRight": 0,
                                      "token": "sm"
                                    }
                                  },
                                  "border": {
                                    "border": {
                                      "width": 1,
                                      "color": "divider"
                                    }
                                  },
                                  "align_child": {
                                    "align": {
                                      "named": "center"
                                    }
                                  }
                                },
                                "children": [
                                  {
                                    "type": "iconbutton",
                                    "properties": {
                                      "name": {
                                        "icon": {
                                          "name": "add_rounded"
                                        }
                                      },
                                      "color": {
                                        "color": {
                                          "color": "primary_text"
                                        }
                                      }
                                    },
                                    "editorId": "iconbutton9"
                                  }
                                ],
                                "editorId": "container33"
                              }
                            ],
                            "editorId": "row29"
                          }
                        ],
                        "editorId": "row28"
                      }
                    ],
                    "editorId": "container31"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "cross_align": {
                        "align": {
                          "named": "stretch"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "@section_header",
                        "properties": {
                          "title": {
                            "stringVal": {
                              "value": "RETARDS (08:15)"
                            }
                          },
                          "action": {
                            "stringVal": {
                              "value": "Ajouter"
                            }
                          }
                        },
                        "editorId": "sectionheader1"
                      },
                      {
                        "type": "@entry_item",
                        "properties": {
                          "name": {
                            "stringVal": {
                              "value": "Jean-Baptiste L."
                            }
                          },
                          "subtitle": {
                            "stringVal": {
                              "value": "Arrivée à 08:42 (+27 min)"
                            }
                          }
                        },
                        "editorId": "entryitem1"
                      },
                      {
                        "type": "@entry_item",
                        "properties": {
                          "name": {
                            "stringVal": {
                              "value": "Marie-Claire D."
                            }
                          },
                          "subtitle": {
                            "stringVal": {
                              "value": "Arrivée à 08:25 (+10 min)"
                            }
                          }
                        },
                        "editorId": "entryitem2"
                      }
                    ],
                    "editorId": "column39"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "cross_align": {
                        "align": {
                          "named": "stretch"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "@section_header",
                        "properties": {
                          "title": {
                            "stringVal": {
                              "value": "ABSENCES"
                            }
                          },
                          "action": {
                            "stringVal": {
                              "value": "Ajouter"
                            }
                          }
                        },
                        "editorId": "sectionheader2"
                      },
                      {
                        "type": "@entry_item",
                        "properties": {
                          "name": {
                            "stringVal": {
                              "value": "Thomas Muller"
                            }
                          },
                          "subtitle": {
                            "stringVal": {
                              "value": "Congé (Récurrent)"
                            }
                          }
                        },
                        "editorId": "entryitem3"
                      },
                      {
                        "type": "@entry_item",
                        "properties": {
                          "name": {
                            "stringVal": {
                              "value": "Sarah Benali"
                            }
                          },
                          "subtitle": {
                            "stringVal": {
                              "value": "Maladie"
                            }
                          }
                        },
                        "editorId": "entryitem4"
                      },
                      {
                        "type": "@entry_item",
                        "properties": {
                          "name": {
                            "stringVal": {
                              "value": "Marc Dupont"
                            }
                          },
                          "subtitle": {
                            "stringVal": {
                              "value": "Absence injustifiée"
                            }
                          }
                        },
                        "editorId": "entryitem5"
                      }
                    ],
                    "editorId": "column40"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "cross_align": {
                        "align": {
                          "named": "stretch"
                        }
                      },
                      "spacing": {
                        "stringVal": {
                          "value": "sm"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "NOTES ADMINISTRATIVES"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_small"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          }
                        },
                        "editorId": "text60"
                      },
                      {
                        "type": "@std.textfield",
                        "properties": {
                          "variant": {
                            "stringVal": {
                              "value": "outlined"
                            }
                          },
                          "hint": {
                            "stringVal": {
                              "value": "Commentaires ou incidents particuliers..."
                            }
                          },
                          "max_lines": {
                            "numberVal": {
                              "value": 3
                            }
                          }
                        },
                        "editorId": "stdtextfield1"
                      }
                    ],
                    "editorId": "column41"
                  }
                ],
                "editorId": "column37"
              }
            ],
            "editorId": "expanded2"
          },
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "token": "lg"
                }
              },
              "border": {
                "borderSided": {
                  "side": "top",
                  "width": 1,
                  "color": "divider"
                }
              },
              "shadow": {
                "stringVal": {
                  "value": "lg"
                }
              }
            },
            "children": [
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  }
                },
                "children": [
                  {
                    "type": "@std.button",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "Finaliser le rapport"
                        }
                      },
                      "variant": {
                        "stringVal": {
                          "value": "primary"
                        }
                      },
                      "full_width": {
                        "boolVal": {
                          "value": true
                        }
                      },
                      "icon": {
                        "stringVal": {
                          "value": "lock_rounded"
                        }
                      }
                    },
                    "editorId": "stdbutton3"
                  },
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "La finalisation verrouille les données et prépare l'export PDF."
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "body_small"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "secondary_text"
                        }
                      },
                      "text_align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "editorId": "text61"
                  }
                ],
                "editorId": "column42"
              }
            ],
            "editorId": "container34"
          }
        ],
        "editorId": "column35"
      }
    ],
    "editorId": "scaffold3"
  }
}
```

### 4. Report History

- Frame ID: `frame8`
- Original page prompt: "List of past reports with date filtering and status indicators (Draft vs Finalized)."
- Follow-up prompts: _None_

#### DslDocument (JSON)

```json
{
  "root": {
    "type": "scaffold",
    "properties": {
      "bg": {
        "color": {
          "color": "background"
        }
      }
    },
    "children": [
      {
        "type": "column",
        "properties": {
          "cross_align": {
            "align": {
              "named": "stretch"
            }
          }
        },
        "children": [
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 24,
                  "right": 16,
                  "bottom": 16,
                  "left": 16
                }
              },
              "border": {
                "borderSided": {
                  "side": "bottom",
                  "width": 1,
                  "color": "divider"
                }
              }
            },
            "children": [
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "sm"
                    }
                  }
                },
                "children": [
                  {
                    "type": "row",
                    "properties": {
                      "align": {
                        "align": {
                          "named": "space_between"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "HISTORIQUE"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_small"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          }
                        },
                        "editorId": "text62"
                      },
                      {
                        "type": "iconbutton",
                        "properties": {
                          "name": {
                            "icon": {
                              "name": "search_rounded"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary_text"
                            }
                          }
                        },
                        "editorId": "iconbutton10"
                      }
                    ],
                    "editorId": "row30"
                  },
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "Rapports de pointage"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "headline_medium"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "primary_text"
                        }
                      }
                    },
                    "editorId": "text63"
                  }
                ],
                "editorId": "column44"
              }
            ],
            "editorId": "container35"
          },
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "topToken": "md",
                  "rightToken": "lg",
                  "bottomToken": "md",
                  "leftToken": "lg"
                }
              },
              "border": {
                "borderSided": {
                  "side": "bottom",
                  "width": 1,
                  "color": "divider"
                }
              }
            },
            "children": [
              {
                "type": "row",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "sm"
                    }
                  }
                },
                "children": [
                  {
                    "type": "chip",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "Tous"
                        }
                      },
                      "selected": {
                        "boolVal": {
                          "value": true
                        }
                      },
                      "radius": {
                        "radius": {
                          "topLeft": 4,
                          "topRight": 4,
                          "bottomLeft": 4,
                          "bottomRight": 4
                        }
                      }
                    },
                    "editorId": "chip1"
                  },
                  {
                    "type": "chip",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "Brouillons"
                        }
                      },
                      "variant": {
                        "stringVal": {
                          "value": "filter"
                        }
                      },
                      "radius": {
                        "radius": {
                          "topLeft": 4,
                          "topRight": 4,
                          "bottomLeft": 4,
                          "bottomRight": 4
                        }
                      }
                    },
                    "editorId": "chip2"
                  },
                  {
                    "type": "chip",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "Finalisés"
                        }
                      },
                      "variant": {
                        "stringVal": {
                          "value": "filter"
                        }
                      },
                      "radius": {
                        "radius": {
                          "topLeft": 4,
                          "topRight": 4,
                          "bottomLeft": 4,
                          "bottomRight": 4
                        }
                      }
                    },
                    "editorId": "chip3"
                  },
                  {
                    "type": "spacer",
                    "editorId": "spacer1"
                  },
                  {
                    "type": "iconbutton",
                    "properties": {
                      "name": {
                        "icon": {
                          "name": "calendar_today_rounded"
                        }
                      },
                      "size": {
                        "numberVal": {
                          "value": 20
                        }
                      },
                      "color": {
                        "color": {
                          "color": "secondary_text"
                        }
                      }
                    },
                    "editorId": "iconbutton11"
                  }
                ],
                "editorId": "row31"
              }
            ],
            "editorId": "container36"
          },
          {
            "type": "expanded",
            "children": [
              {
                "type": "column",
                "properties": {
                  "scroll": {
                    "boolVal": {
                      "value": true
                    }
                  },
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "token": "lg"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "stretch"
                    }
                  }
                },
                "children": [
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "OCTOBRE 2023"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "label_small"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "secondary_text"
                        }
                      },
                      "margin": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "bottomToken": "md"
                        }
                      }
                    },
                    "editorId": "text64"
                  },
                  {
                    "type": "@history_card",
                    "properties": {
                      "date": {
                        "stringVal": {
                          "value": "Lundi 24 Octobre"
                        }
                      },
                      "status": {
                        "stringVal": {
                          "value": "DRAFT"
                        }
                      },
                      "incidents": {
                        "stringVal": {
                          "value": "5"
                        }
                      },
                      "visitors": {
                        "stringVal": {
                          "value": "12"
                        }
                      }
                    },
                    "editorId": "historycard1"
                  },
                  {
                    "type": "@history_card",
                    "properties": {
                      "date": {
                        "stringVal": {
                          "value": "Vendredi 21 Octobre"
                        }
                      },
                      "status": {
                        "stringVal": {
                          "value": "FINALIZED"
                        }
                      },
                      "incidents": {
                        "stringVal": {
                          "value": "2"
                        }
                      },
                      "visitors": {
                        "stringVal": {
                          "value": "08"
                        }
                      }
                    },
                    "editorId": "historycard2"
                  },
                  {
                    "type": "@history_card",
                    "properties": {
                      "date": {
                        "stringVal": {
                          "value": "Jeudi 20 Octobre"
                        }
                      },
                      "status": {
                        "stringVal": {
                          "value": "FINALIZED"
                        }
                      },
                      "incidents": {
                        "stringVal": {
                          "value": "8"
                        }
                      },
                      "visitors": {
                        "stringVal": {
                          "value": "15"
                        }
                      }
                    },
                    "editorId": "historycard3"
                  },
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "SEPTEMBRE 2023"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "label_small"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "secondary_text"
                        }
                      },
                      "margin": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "topToken": "lg",
                          "bottomToken": "md"
                        }
                      }
                    },
                    "editorId": "text65"
                  },
                  {
                    "type": "@history_card",
                    "properties": {
                      "date": {
                        "stringVal": {
                          "value": "Mardi 30 Septembre"
                        }
                      },
                      "status": {
                        "stringVal": {
                          "value": "FINALIZED"
                        }
                      },
                      "incidents": {
                        "stringVal": {
                          "value": "1"
                        }
                      },
                      "visitors": {
                        "stringVal": {
                          "value": "05"
                        }
                      }
                    },
                    "editorId": "historycard4"
                  },
                  {
                    "type": "@history_card",
                    "properties": {
                      "date": {
                        "stringVal": {
                          "value": "Lundi 29 Septembre"
                        }
                      },
                      "status": {
                        "stringVal": {
                          "value": "FINALIZED"
                        }
                      },
                      "incidents": {
                        "stringVal": {
                          "value": "4"
                        }
                      },
                      "visitors": {
                        "stringVal": {
                          "value": "10"
                        }
                      }
                    },
                    "editorId": "historycard5"
                  },
                  {
                    "type": "@history_card",
                    "properties": {
                      "date": {
                        "stringVal": {
                          "value": "Vendredi 26 Septembre"
                        }
                      },
                      "status": {
                        "stringVal": {
                          "value": "FINALIZED"
                        }
                      },
                      "incidents": {
                        "stringVal": {
                          "value": "3"
                        }
                      },
                      "visitors": {
                        "stringVal": {
                          "value": "07"
                        }
                      }
                    },
                    "editorId": "historycard6"
                  }
                ],
                "editorId": "column45"
              }
            ],
            "editorId": "expanded3"
          },
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "token": "lg"
                }
              },
              "border": {
                "borderSided": {
                  "side": "top",
                  "width": 1,
                  "color": "divider"
                }
              },
              "shadow": {
                "stringVal": {
                  "value": "lg"
                }
              }
            },
            "children": [
              {
                "type": "@std.button",
                "properties": {
                  "content": {
                    "stringVal": {
                      "value": "Nouveau rapport du jour"
                    }
                  },
                  "variant": {
                    "stringVal": {
                      "value": "primary"
                    }
                  },
                  "full_width": {
                    "boolVal": {
                      "value": true
                    }
                  },
                  "icon": {
                    "stringVal": {
                      "value": "add_rounded"
                    }
                  }
                },
                "editorId": "stdbutton4"
              }
            ],
            "editorId": "container37"
          }
        ],
        "editorId": "column43"
      }
    ],
    "editorId": "scaffold4"
  }
}
```

### 5. Employee Directory

- Frame ID: `frame7`
- Original page prompt: "Management list of employees with active/inactive toggles and 'needs review' flags from imports."
- Follow-up prompts: _None_

#### DslDocument (JSON)

```json
{
  "root": {
    "type": "scaffold",
    "properties": {
      "bg": {
        "color": {
          "color": "background"
        }
      }
    },
    "children": [
      {
        "type": "column",
        "properties": {
          "cross_align": {
            "align": {
              "named": "stretch"
            }
          }
        },
        "children": [
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "topToken": "lg",
                  "rightToken": "md",
                  "bottomToken": "lg",
                  "leftToken": "md"
                }
              },
              "border": {
                "borderSided": {
                  "side": "bottom",
                  "width": 1,
                  "color": "divider"
                }
              }
            },
            "children": [
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  }
                },
                "children": [
                  {
                    "type": "row",
                    "properties": {
                      "align": {
                        "align": {
                          "named": "space_between"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "iconbutton",
                        "properties": {
                          "name": {
                            "icon": {
                              "name": "arrow_back_rounded"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary_text"
                            }
                          }
                        },
                        "editorId": "iconbutton12"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "ANNUAIRE PERSONNEL"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_large"
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary_text"
                            }
                          }
                        },
                        "editorId": "text66"
                      },
                      {
                        "type": "iconbutton",
                        "properties": {
                          "name": {
                            "icon": {
                              "name": "file_upload_rounded"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary"
                            }
                          },
                          "tooltip": {
                            "stringVal": {
                              "value": "Importer Excel"
                            }
                          }
                        },
                        "editorId": "iconbutton13"
                      }
                    ],
                    "editorId": "row32"
                  },
                  {
                    "type": "container",
                    "properties": {
                      "bg": {
                        "color": {
                          "color": "background"
                        }
                      },
                      "radius": {
                        "radius": {
                          "topLeft": 6,
                          "topRight": 6,
                          "bottomLeft": 6,
                          "bottomRight": 6
                        }
                      },
                      "border": {
                        "border": {
                          "width": 1,
                          "color": "outline"
                        }
                      },
                      "padding": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "topToken": "sm",
                          "rightToken": "md",
                          "bottomToken": "sm",
                          "leftToken": "md"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "row",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "sm"
                            }
                          },
                          "cross_align": {
                            "align": {
                              "named": "center"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "icon",
                            "properties": {
                              "name": {
                                "icon": {
                                  "name": "search_rounded"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "secondary_text"
                                }
                              },
                              "size": {
                                "numberVal": {
                                  "value": 20
                                }
                              }
                            },
                            "editorId": "icon15"
                          },
                          {
                            "type": "expanded",
                            "children": [
                              {
                                "type": "text",
                                "properties": {
                                  "content": {
                                    "stringVal": {
                                      "value": "Rechercher un employé..."
                                    }
                                  },
                                  "style": {
                                    "textStyle": {
                                      "styleName": "body_medium"
                                    }
                                  },
                                  "color": {
                                    "color": {
                                      "color": "hint"
                                    }
                                  }
                                },
                                "editorId": "text67"
                              }
                            ],
                            "editorId": "expanded4"
                          }
                        ],
                        "editorId": "row33"
                      }
                    ],
                    "editorId": "container39"
                  }
                ],
                "editorId": "column47"
              }
            ],
            "editorId": "container38"
          },
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "secondary_background"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "topToken": "md",
                  "rightToken": "lg",
                  "bottomToken": "md",
                  "leftToken": "lg"
                }
              },
              "border": {
                "borderSided": {
                  "side": "bottom",
                  "width": 1,
                  "color": "divider"
                }
              }
            },
            "children": [
              {
                "type": "row",
                "properties": {
                  "align": {
                    "align": {
                      "named": "space_around"
                    }
                  }
                },
                "children": [
                  {
                    "type": "column",
                    "properties": {
                      "cross_align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "142"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "title_medium"
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          }
                        },
                        "editorId": "text68"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Total"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_small"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          }
                        },
                        "editorId": "text69"
                      }
                    ],
                    "editorId": "stat1"
                  },
                  {
                    "type": "divider",
                    "properties": {
                      "vertical": {
                        "boolVal": {
                          "value": true
                        }
                      },
                      "height": {
                        "px": {
                          "value": 24,
                          "isInfinity": false
                        }
                      },
                      "color": {
                        "color": {
                          "color": "divider"
                        }
                      }
                    },
                    "editorId": "d1"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "cross_align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "128"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "title_medium"
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "success"
                            }
                          }
                        },
                        "editorId": "text70"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Actifs"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_small"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          }
                        },
                        "editorId": "text71"
                      }
                    ],
                    "editorId": "stat2"
                  },
                  {
                    "type": "divider",
                    "properties": {
                      "vertical": {
                        "boolVal": {
                          "value": true
                        }
                      },
                      "height": {
                        "px": {
                          "value": 24,
                          "isInfinity": false
                        }
                      },
                      "color": {
                        "color": {
                          "color": "divider"
                        }
                      }
                    },
                    "editorId": "d2"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "cross_align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "5"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "title_medium"
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "on_surface"
                            }
                          }
                        },
                        "editorId": "text72"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Alertes"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_small"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          }
                        },
                        "editorId": "text73"
                      }
                    ],
                    "editorId": "stat3"
                  }
                ],
                "editorId": "row34"
              }
            ],
            "editorId": "container40"
          },
          {
            "type": "expanded",
            "children": [
              {
                "type": "column",
                "properties": {
                  "scroll": {
                    "boolVal": {
                      "value": true
                    }
                  },
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "token": "lg"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "stretch"
                    }
                  }
                },
                "children": [
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "ACTIONS REQUISES"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "label_small"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "secondary_text"
                        }
                      },
                      "margin": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "bottomToken": "md"
                        }
                      }
                    },
                    "editorId": "text74"
                  },
                  {
                    "type": "@employee_card",
                    "properties": {
                      "name": {
                        "stringVal": {
                          "value": "Jean-Baptiste Lemaire"
                        }
                      },
                      "initials": {
                        "stringVal": {
                          "value": "JL"
                        }
                      },
                      "job": {
                        "stringVal": {
                          "value": "Service Administratif"
                        }
                      },
                      "is_active": {
                        "boolVal": {
                          "value": true
                        }
                      },
                      "needs_review": {
                        "boolVal": {
                          "value": true
                        }
                      }
                    },
                    "editorId": "emp1"
                  },
                  {
                    "type": "@employee_card",
                    "properties": {
                      "name": {
                        "stringVal": {
                          "value": "Marie-Claire Desruelles"
                        }
                      },
                      "initials": {
                        "stringVal": {
                          "value": "MD"
                        }
                      },
                      "job": {
                        "stringVal": {
                          "value": "Logistique"
                        }
                      },
                      "is_active": {
                        "boolVal": {
                          "value": true
                        }
                      },
                      "needs_review": {
                        "boolVal": {
                          "value": true
                        }
                      }
                    },
                    "editorId": "emp2"
                  },
                  {
                    "type": "sizedbox",
                    "properties": {
                      "height": {
                        "stringVal": {
                          "value": "md"
                        }
                      }
                    },
                    "editorId": "gap1"
                  },
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "TOUS LES EMPLOYÉS"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "label_small"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "secondary_text"
                        }
                      },
                      "margin": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "bottomToken": "md"
                        }
                      }
                    },
                    "editorId": "text75"
                  },
                  {
                    "type": "@employee_card",
                    "properties": {
                      "name": {
                        "stringVal": {
                          "value": "Thomas Muller"
                        }
                      },
                      "initials": {
                        "stringVal": {
                          "value": "TM"
                        }
                      },
                      "job": {
                        "stringVal": {
                          "value": "Directeur Adjoint"
                        }
                      },
                      "is_active": {
                        "boolVal": {
                          "value": true
                        }
                      },
                      "needs_review": {
                        "boolVal": {
                          "value": false
                        }
                      }
                    },
                    "editorId": "emp3"
                  },
                  {
                    "type": "@employee_card",
                    "properties": {
                      "name": {
                        "stringVal": {
                          "value": "Sarah Benali"
                        }
                      },
                      "initials": {
                        "stringVal": {
                          "value": "SB"
                        }
                      },
                      "job": {
                        "stringVal": {
                          "value": "Ressources Humaines"
                        }
                      },
                      "is_active": {
                        "boolVal": {
                          "value": true
                        }
                      },
                      "needs_review": {
                        "boolVal": {
                          "value": false
                        }
                      }
                    },
                    "editorId": "emp4"
                  },
                  {
                    "type": "@employee_card",
                    "properties": {
                      "name": {
                        "stringVal": {
                          "value": "Marc Dupont"
                        }
                      },
                      "initials": {
                        "stringVal": {
                          "value": "MD"
                        }
                      },
                      "job": {
                        "stringVal": {
                          "value": "Agent d'accueil"
                        }
                      },
                      "is_active": {
                        "boolVal": {
                          "value": true
                        }
                      },
                      "needs_review": {
                        "boolVal": {
                          "value": false
                        }
                      }
                    },
                    "editorId": "emp5"
                  },
                  {
                    "type": "@employee_card",
                    "properties": {
                      "name": {
                        "stringVal": {
                          "value": "Lucie Vallet"
                        }
                      },
                      "initials": {
                        "stringVal": {
                          "value": "LV"
                        }
                      },
                      "job": {
                        "stringVal": {
                          "value": "Maintenance"
                        }
                      },
                      "is_active": {
                        "boolVal": {
                          "value": false
                        }
                      },
                      "needs_review": {
                        "boolVal": {
                          "value": false
                        }
                      }
                    },
                    "editorId": "emp6"
                  },
                  {
                    "type": "@employee_card",
                    "properties": {
                      "name": {
                        "stringVal": {
                          "value": "Antoine Garcia"
                        }
                      },
                      "initials": {
                        "stringVal": {
                          "value": "AG"
                        }
                      },
                      "job": {
                        "stringVal": {
                          "value": "Service Technique"
                        }
                      },
                      "is_active": {
                        "boolVal": {
                          "value": true
                        }
                      },
                      "needs_review": {
                        "boolVal": {
                          "value": false
                        }
                      }
                    },
                    "editorId": "emp7"
                  },
                  {
                    "type": "@employee_card",
                    "properties": {
                      "name": {
                        "stringVal": {
                          "value": "Hélène Petit"
                        }
                      },
                      "initials": {
                        "stringVal": {
                          "value": "HP"
                        }
                      },
                      "job": {
                        "stringVal": {
                          "value": "Comptabilité"
                        }
                      },
                      "is_active": {
                        "boolVal": {
                          "value": false
                        }
                      },
                      "needs_review": {
                        "boolVal": {
                          "value": false
                        }
                      }
                    },
                    "editorId": "emp8"
                  }
                ],
                "editorId": "column48"
              }
            ],
            "editorId": "expanded5"
          }
        ],
        "editorId": "column46"
      },
      {
        "type": "fab",
        "properties": {
          "icon": {
            "icon": {
              "name": "add_rounded"
            }
          },
          "label": {
            "stringVal": {
              "value": "Nouvel Employé"
            }
          },
          "bg": {
            "color": {
              "color": "primary"
            }
          },
          "color": {
            "color": {
              "color": "on_primary"
            }
          },
          "radius": {
            "radius": {
              "topLeft": 6,
              "topRight": 6,
              "bottomLeft": 6,
              "bottomRight": 6
            }
          }
        },
        "editorId": "fab1"
      }
    ],
    "editorId": "scaffold5"
  }
}
```

### 6. Recurring Absences

- Frame ID: `frame4`
- Original page prompt: "Configuration screen to assign permanent absence reasons to specific employees for automatic report pre-filling."
- Follow-up prompts: _None_

#### DslDocument (JSON)

```json
{
  "root": {
    "type": "scaffold",
    "properties": {
      "bg": {
        "color": {
          "color": "background"
        }
      }
    },
    "children": [
      {
        "type": "column",
        "properties": {
          "cross_align": {
            "align": {
              "named": "stretch"
            }
          }
        },
        "children": [
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "topToken": "lg",
                  "rightToken": "md",
                  "bottomToken": "lg",
                  "leftToken": "md"
                }
              },
              "border": {
                "borderSided": {
                  "side": "bottom",
                  "width": 1,
                  "color": "divider"
                }
              }
            },
            "children": [
              {
                "type": "row",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "center"
                    }
                  }
                },
                "children": [
                  {
                    "type": "iconbutton",
                    "properties": {
                      "name": {
                        "icon": {
                          "name": "arrow_back_rounded"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "primary_text"
                        }
                      }
                    },
                    "editorId": "iconbutton14"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "cross_align": {
                        "align": {
                          "named": "start"
                        }
                      },
                      "spacing": {
                        "stringVal": {
                          "value": "xs"
                        }
                      },
                      "expanded": {
                        "expanded": {
                          "enabled": true,
                          "flex": 1
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "CONFIGURATION"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_small"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          },
                          "line_height": {
                            "numberVal": {
                              "value": 1.2
                            }
                          }
                        },
                        "editorId": "text76"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Absences Récurrentes"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "headline_small"
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary_text"
                            }
                          }
                        },
                        "editorId": "text77"
                      }
                    ],
                    "editorId": "column50"
                  },
                  {
                    "type": "iconbutton",
                    "properties": {
                      "name": {
                        "icon": {
                          "name": "info_outline_rounded"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "secondary_text"
                        }
                      },
                      "size": {
                        "numberVal": {
                          "value": 20
                        }
                      }
                    },
                    "editorId": "iconbutton15"
                  }
                ],
                "editorId": "row35"
              }
            ],
            "editorId": "container41"
          },
          {
            "type": "expanded",
            "children": [
              {
                "type": "column",
                "properties": {
                  "scroll": {
                    "boolVal": {
                      "value": true
                    }
                  },
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "token": "lg"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "stretch"
                    }
                  }
                },
                "children": [
                  {
                    "type": "container",
                    "properties": {
                      "bg": {
                        "color": {
                          "color": "surface"
                        }
                      },
                      "padding": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "token": "lg"
                        }
                      },
                      "radius": {
                        "radius": {
                          "topLeft": 0,
                          "topRight": 0,
                          "bottomLeft": 0,
                          "bottomRight": 0,
                          "token": "sm"
                        }
                      },
                      "border": {
                        "border": {
                          "width": 1,
                          "color": "divider"
                        }
                      },
                      "margin": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "bottomToken": "lg"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "column",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "md"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "row",
                            "properties": {
                              "spacing": {
                                "stringVal": {
                                  "value": "sm"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "icon",
                                "properties": {
                                  "name": {
                                    "icon": {
                                      "name": "auto_awesome_rounded"
                                    }
                                  },
                                  "color": {
                                    "color": {
                                      "color": "primary"
                                    }
                                  },
                                  "size": {
                                    "numberVal": {
                                      "value": 20
                                    }
                                  }
                                },
                                "editorId": "icon16"
                              },
                              {
                                "type": "text",
                                "properties": {
                                  "content": {
                                    "stringVal": {
                                      "value": "Automatisation du pointage"
                                    }
                                  },
                                  "style": {
                                    "textStyle": {
                                      "styleName": "title_small"
                                    }
                                  },
                                  "font_weight": {
                                    "stringVal": {
                                      "value": "bold"
                                    }
                                  }
                                },
                                "editorId": "text78"
                              }
                            ],
                            "editorId": "row36"
                          },
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "Les employés listés ici seront automatiquement marqués comme absents lors de la création de chaque nouveau rapport journalier."
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "body_medium"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "secondary_text"
                                }
                              },
                              "line_height": {
                                "numberVal": {
                                  "value": 1.6
                                }
                              }
                            },
                            "editorId": "text79"
                          }
                        ],
                        "editorId": "column52"
                      }
                    ],
                    "editorId": "container42"
                  },
                  {
                    "type": "row",
                    "properties": {
                      "align": {
                        "align": {
                          "named": "space_between"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "center"
                        }
                      },
                      "padding": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "bottomToken": "md"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "RÉCURRENCES ACTIVES"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_large"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          }
                        },
                        "editorId": "text80"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "4 employés"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_small"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "hint"
                            }
                          }
                        },
                        "editorId": "text81"
                      }
                    ],
                    "editorId": "row37"
                  },
                  {
                    "type": "@recurring_absence_card",
                    "properties": {
                      "employee_name": {
                        "stringVal": {
                          "value": "Marc-Antoine Girard"
                        }
                      },
                      "reason": {
                        "stringVal": {
                          "value": "Congé"
                        }
                      },
                      "comment": {
                        "stringVal": {
                          "value": "Jusqu'au 15/11"
                        }
                      }
                    },
                    "editorId": "card1"
                  },
                  {
                    "type": "@recurring_absence_card",
                    "properties": {
                      "employee_name": {
                        "stringVal": {
                          "value": "Hélène Sjöberg"
                        }
                      },
                      "reason": {
                        "stringVal": {
                          "value": "Mission"
                        }
                      },
                      "comment": {
                        "stringVal": {
                          "value": "Projet Stockholm"
                        }
                      }
                    },
                    "editorId": "card2"
                  },
                  {
                    "type": "@recurring_absence_card",
                    "properties": {
                      "employee_name": {
                        "stringVal": {
                          "value": "Lars Andersen"
                        }
                      },
                      "reason": {
                        "stringVal": {
                          "value": "Formation"
                        }
                      },
                      "comment": {
                        "stringVal": {
                          "value": "Certification ITIL"
                        }
                      }
                    },
                    "editorId": "card3"
                  },
                  {
                    "type": "@recurring_absence_card",
                    "properties": {
                      "employee_name": {
                        "stringVal": {
                          "value": "Sofia Dahmani"
                        }
                      },
                      "reason": {
                        "stringVal": {
                          "value": "Permission"
                        }
                      },
                      "comment": {
                        "stringVal": {
                          "value": "Raisons familiales"
                        }
                      }
                    },
                    "editorId": "card4"
                  }
                ],
                "editorId": "column51"
              }
            ],
            "editorId": "expanded6"
          },
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "token": "lg"
                }
              },
              "border": {
                "borderSided": {
                  "side": "top",
                  "width": 1,
                  "color": "divider"
                }
              },
              "shadow": {
                "stringVal": {
                  "value": "lg"
                }
              }
            },
            "children": [
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  }
                },
                "children": [
                  {
                    "type": "@std.button",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "Ajouter une absence récurrente"
                        }
                      },
                      "variant": {
                        "stringVal": {
                          "value": "primary"
                        }
                      },
                      "full_width": {
                        "boolVal": {
                          "value": true
                        }
                      },
                      "icon": {
                        "stringVal": {
                          "value": "person_add_rounded"
                        }
                      },
                      "size": {
                        "stringVal": {
                          "value": "large"
                        }
                      }
                    },
                    "editorId": "stdbutton5"
                  },
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "Les modifications n'affectent pas les rapports déjà finalisés."
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "body_small"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "secondary_text"
                        }
                      },
                      "text_align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "editorId": "text82"
                  }
                ],
                "editorId": "column53"
              }
            ],
            "editorId": "container43"
          }
        ],
        "editorId": "column49"
      }
    ],
    "editorId": "scaffold6"
  }
}
```

### 7. Analytics & Statistics

- Frame ID: `frame10`
- Original page prompt: "Visual dashboard showing trends like top late-comers, absence reason distribution, and peak incident days."
- Follow-up prompts: _None_

#### DslDocument (JSON)

```json
{
  "root": {
    "type": "scaffold",
    "properties": {
      "bg": {
        "color": {
          "color": "background"
        }
      }
    },
    "children": [
      {
        "type": "column",
        "properties": {
          "cross_align": {
            "align": {
              "named": "stretch"
            }
          }
        },
        "children": [
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "topToken": "lg",
                  "rightToken": "md",
                  "bottomToken": "lg",
                  "leftToken": "md"
                }
              },
              "border": {
                "borderSided": {
                  "side": "bottom",
                  "width": 1,
                  "color": "divider"
                }
              }
            },
            "children": [
              {
                "type": "row",
                "properties": {
                  "align": {
                    "align": {
                      "named": "space_between"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "center"
                    }
                  }
                },
                "children": [
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "xs"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "STATISTIQUES & ANALYSE"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_small"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          }
                        },
                        "editorId": "text83"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Vue d'ensemble"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "title_medium"
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          }
                        },
                        "editorId": "text84"
                      }
                    ],
                    "editorId": "column55"
                  },
                  {
                    "type": "iconbutton",
                    "properties": {
                      "name": {
                        "icon": {
                          "name": "filter_list_rounded"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "primary_text"
                        }
                      },
                      "tooltip": {
                        "stringVal": {
                          "value": "Filtrer par période"
                        }
                      }
                    },
                    "editorId": "iconbutton16"
                  }
                ],
                "editorId": "row38"
              }
            ],
            "editorId": "container44"
          },
          {
            "type": "expanded",
            "children": [
              {
                "type": "column",
                "properties": {
                  "scroll": {
                    "boolVal": {
                      "value": true
                    }
                  },
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "token": "lg"
                    }
                  },
                  "spacing": {
                    "stringVal": {
                      "value": "lg"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "stretch"
                    }
                  }
                },
                "children": [
                  {
                    "type": "container",
                    "properties": {
                      "bg": {
                        "color": {
                          "color": "surface"
                        }
                      },
                      "padding": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "topToken": "sm",
                          "rightToken": "md",
                          "bottomToken": "sm",
                          "leftToken": "md"
                        }
                      },
                      "radius": {
                        "radius": {
                          "topLeft": 6,
                          "topRight": 6,
                          "bottomLeft": 6,
                          "bottomRight": 6
                        }
                      },
                      "border": {
                        "border": {
                          "width": 1,
                          "color": "divider"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "row",
                        "properties": {
                          "align": {
                            "align": {
                              "named": "space_between"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "Octobre 2023"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "body_medium"
                                }
                              },
                              "font_weight": {
                                "numberVal": {
                                  "value": 600
                                }
                              }
                            },
                            "editorId": "text85"
                          },
                          {
                            "type": "icon",
                            "properties": {
                              "name": {
                                "icon": {
                                  "name": "calendar_today_rounded"
                                }
                              },
                              "size": {
                                "numberVal": {
                                  "value": 18
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "secondary_text"
                                }
                              }
                            },
                            "editorId": "icon17"
                          }
                        ],
                        "editorId": "row39"
                      }
                    ],
                    "editorId": "container45"
                  },
                  {
                    "type": "row",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "@kpi_card",
                        "properties": {
                          "label": {
                            "stringVal": {
                              "value": "INCIDENTS"
                            }
                          },
                          "value": {
                            "stringVal": {
                              "value": "42"
                            }
                          },
                          "delta": {
                            "stringVal": {
                              "value": "+12%"
                            }
                          },
                          "up": {
                            "boolVal": {
                              "value": true
                            }
                          }
                        },
                        "editorId": "kpicard1"
                      },
                      {
                        "type": "@kpi_card",
                        "properties": {
                          "label": {
                            "stringVal": {
                              "value": "VISITEURS"
                            }
                          },
                          "value": {
                            "stringVal": {
                              "value": "284"
                            }
                          },
                          "delta": {
                            "stringVal": {
                              "value": "+5%"
                            }
                          },
                          "up": {
                            "boolVal": {
                              "value": false
                            }
                          }
                        },
                        "editorId": "kpicard2"
                      }
                    ],
                    "editorId": "row40"
                  },
                  {
                    "type": "row",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "@kpi_card",
                        "properties": {
                          "label": {
                            "stringVal": {
                              "value": "RETARD MOYEN"
                            }
                          },
                          "value": {
                            "stringVal": {
                              "value": "18 min"
                            }
                          },
                          "delta": {
                            "stringVal": {
                              "value": "-2 min"
                            }
                          },
                          "up": {
                            "boolVal": {
                              "value": false
                            }
                          }
                        },
                        "editorId": "kpicard3"
                      },
                      {
                        "type": "@kpi_card",
                        "properties": {
                          "label": {
                            "stringVal": {
                              "value": "RAPPORTS"
                            }
                          },
                          "value": {
                            "stringVal": {
                              "value": "21/31"
                            }
                          },
                          "delta": {
                            "stringVal": {
                              "value": "Stable"
                            }
                          },
                          "up": {
                            "boolVal": {
                              "value": false
                            }
                          }
                        },
                        "editorId": "kpicard4"
                      }
                    ],
                    "editorId": "row41"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Tendance des incidents"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_large"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          }
                        },
                        "editorId": "text86"
                      },
                      {
                        "type": "container",
                        "properties": {
                          "bg": {
                            "color": {
                              "color": "surface"
                            }
                          },
                          "padding": {
                            "edgeInsets": {
                              "top": 0,
                              "right": 0,
                              "bottom": 0,
                              "left": 0,
                              "token": "lg"
                            }
                          },
                          "radius": {
                            "radius": {
                              "topLeft": 6,
                              "topRight": 6,
                              "bottomLeft": 6,
                              "bottomRight": 6
                            }
                          },
                          "border": {
                            "border": {
                              "width": 1,
                              "color": "divider"
                            }
                          },
                          "height": {
                            "px": {
                              "value": 220,
                              "isInfinity": false
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "column",
                            "properties": {
                              "spacing": {
                                "stringVal": {
                                  "value": "md"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "expanded",
                                "children": [
                                  {
                                    "type": "line_chart",
                                    "properties": {
                                      "data": {
                                        "stringVal": {
                                          "value": "12,8,15,10,18,14,9"
                                        }
                                      },
                                      "labels": {
                                        "stringVal": {
                                          "value": "S1,S2,S3,S4,S5,S6,S7"
                                        }
                                      },
                                      "color": {
                                        "color": {
                                          "color": "primary"
                                        }
                                      },
                                      "curved": {
                                        "boolVal": {
                                          "value": true
                                        }
                                      },
                                      "filled": {
                                        "boolVal": {
                                          "value": true
                                        }
                                      },
                                      "fill_opacity": {
                                        "numberVal": {
                                          "value": 0.1
                                        }
                                      },
                                      "show_dots": {
                                        "boolVal": {
                                          "value": true
                                        }
                                      },
                                      "line_width": {
                                        "numberVal": {
                                          "value": 2
                                        }
                                      }
                                    },
                                    "editorId": "linechart1"
                                  }
                                ],
                                "editorId": "expanded8"
                              },
                              {
                                "type": "row",
                                "properties": {
                                  "align": {
                                    "align": {
                                      "named": "center"
                                    }
                                  },
                                  "spacing": {
                                    "stringVal": {
                                      "value": "lg"
                                    }
                                  }
                                },
                                "children": [
                                  {
                                    "type": "row",
                                    "properties": {
                                      "spacing": {
                                        "stringVal": {
                                          "value": "xs"
                                        }
                                      }
                                    },
                                    "children": [
                                      {
                                        "type": "container",
                                        "properties": {
                                          "width": {
                                            "px": {
                                              "value": 8,
                                              "isInfinity": false
                                            }
                                          },
                                          "height": {
                                            "px": {
                                              "value": 8,
                                              "isInfinity": false
                                            }
                                          },
                                          "radius": {
                                            "radius": {
                                              "topLeft": 0,
                                              "topRight": 0,
                                              "bottomLeft": 0,
                                              "bottomRight": 0,
                                              "token": "full"
                                            }
                                          },
                                          "bg": {
                                            "color": {
                                              "color": "primary"
                                            }
                                          }
                                        },
                                        "editorId": "container47"
                                      },
                                      {
                                        "type": "text",
                                        "properties": {
                                          "content": {
                                            "stringVal": {
                                              "value": "Retards & Absences"
                                            }
                                          },
                                          "style": {
                                            "textStyle": {
                                              "styleName": "body_small"
                                            }
                                          },
                                          "color": {
                                            "color": {
                                              "color": "secondary_text"
                                            }
                                          }
                                        },
                                        "editorId": "text87"
                                      }
                                    ],
                                    "editorId": "row43"
                                  }
                                ],
                                "editorId": "row42"
                              }
                            ],
                            "editorId": "column58"
                          }
                        ],
                        "editorId": "container46"
                      }
                    ],
                    "editorId": "column57"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Motifs d'absence"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_large"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          }
                        },
                        "editorId": "text88"
                      },
                      {
                        "type": "container",
                        "properties": {
                          "bg": {
                            "color": {
                              "color": "surface"
                            }
                          },
                          "padding": {
                            "edgeInsets": {
                              "top": 0,
                              "right": 0,
                              "bottom": 0,
                              "left": 0,
                              "token": "lg"
                            }
                          },
                          "radius": {
                            "radius": {
                              "topLeft": 6,
                              "topRight": 6,
                              "bottomLeft": 6,
                              "bottomRight": 6
                            }
                          },
                          "border": {
                            "border": {
                              "width": 1,
                              "color": "divider"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "row",
                            "properties": {
                              "spacing": {
                                "stringVal": {
                                  "value": "lg"
                                }
                              },
                              "cross_align": {
                                "align": {
                                  "named": "center"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "container",
                                "properties": {
                                  "width": {
                                    "px": {
                                      "value": 140,
                                      "isInfinity": false
                                    }
                                  },
                                  "height": {
                                    "px": {
                                      "value": 140,
                                      "isInfinity": false
                                    }
                                  }
                                },
                                "children": [
                                  {
                                    "type": "@std.pie_chart",
                                    "properties": {
                                      "data": {
                                        "stringVal": {
                                          "value": "45,25,15,10,5"
                                        }
                                      },
                                      "labels": {
                                        "stringVal": {
                                          "value": "Injustifiée,Maladie,Congé,Mission,Autre"
                                        }
                                      },
                                      "colors": {
                                        "stringVal": {
                                          "value": "#2C3E50,#34495E,#5D6D7E,#85929E,#AEB6BF"
                                        }
                                      },
                                      "donut": {
                                        "boolVal": {
                                          "value": true
                                        }
                                      },
                                      "donut_radius": {
                                        "numberVal": {
                                          "value": 0.7
                                        }
                                      },
                                      "legend": {
                                        "stringVal": {
                                          "value": "hidden"
                                        }
                                      }
                                    },
                                    "editorId": "piechart1"
                                  }
                                ],
                                "editorId": "container49"
                              },
                              {
                                "type": "column",
                                "properties": {
                                  "expanded": {
                                    "expanded": {
                                      "enabled": true,
                                      "flex": 1
                                    }
                                  },
                                  "spacing": {
                                    "stringVal": {
                                      "value": "sm"
                                    }
                                  }
                                },
                                "children": [
                                  {
                                    "type": "row",
                                    "properties": {
                                      "spacing": {
                                        "stringVal": {
                                          "value": "sm"
                                        }
                                      }
                                    },
                                    "children": [
                                      {
                                        "type": "container",
                                        "properties": {
                                          "width": {
                                            "px": {
                                              "value": 8,
                                              "isInfinity": false
                                            }
                                          },
                                          "height": {
                                            "px": {
                                              "value": 8,
                                              "isInfinity": false
                                            }
                                          },
                                          "radius": {
                                            "radius": {
                                              "topLeft": 2,
                                              "topRight": 2,
                                              "bottomLeft": 2,
                                              "bottomRight": 2
                                            }
                                          },
                                          "bg": {
                                            "color": {
                                              "color": "#2C3E50"
                                            }
                                          }
                                        },
                                        "editorId": "container50"
                                      },
                                      {
                                        "type": "text",
                                        "properties": {
                                          "content": {
                                            "stringVal": {
                                              "value": "45% Injustifiée"
                                            }
                                          },
                                          "style": {
                                            "textStyle": {
                                              "styleName": "body_small"
                                            }
                                          }
                                        },
                                        "editorId": "text89"
                                      }
                                    ],
                                    "editorId": "row45"
                                  },
                                  {
                                    "type": "row",
                                    "properties": {
                                      "spacing": {
                                        "stringVal": {
                                          "value": "sm"
                                        }
                                      }
                                    },
                                    "children": [
                                      {
                                        "type": "container",
                                        "properties": {
                                          "width": {
                                            "px": {
                                              "value": 8,
                                              "isInfinity": false
                                            }
                                          },
                                          "height": {
                                            "px": {
                                              "value": 8,
                                              "isInfinity": false
                                            }
                                          },
                                          "radius": {
                                            "radius": {
                                              "topLeft": 2,
                                              "topRight": 2,
                                              "bottomLeft": 2,
                                              "bottomRight": 2
                                            }
                                          },
                                          "bg": {
                                            "color": {
                                              "color": "#34495E"
                                            }
                                          }
                                        },
                                        "editorId": "container51"
                                      },
                                      {
                                        "type": "text",
                                        "properties": {
                                          "content": {
                                            "stringVal": {
                                              "value": "25% Maladie"
                                            }
                                          },
                                          "style": {
                                            "textStyle": {
                                              "styleName": "body_small"
                                            }
                                          }
                                        },
                                        "editorId": "text90"
                                      }
                                    ],
                                    "editorId": "row46"
                                  },
                                  {
                                    "type": "row",
                                    "properties": {
                                      "spacing": {
                                        "stringVal": {
                                          "value": "sm"
                                        }
                                      }
                                    },
                                    "children": [
                                      {
                                        "type": "container",
                                        "properties": {
                                          "width": {
                                            "px": {
                                              "value": 8,
                                              "isInfinity": false
                                            }
                                          },
                                          "height": {
                                            "px": {
                                              "value": 8,
                                              "isInfinity": false
                                            }
                                          },
                                          "radius": {
                                            "radius": {
                                              "topLeft": 2,
                                              "topRight": 2,
                                              "bottomLeft": 2,
                                              "bottomRight": 2
                                            }
                                          },
                                          "bg": {
                                            "color": {
                                              "color": "#5D6D7E"
                                            }
                                          }
                                        },
                                        "editorId": "container52"
                                      },
                                      {
                                        "type": "text",
                                        "properties": {
                                          "content": {
                                            "stringVal": {
                                              "value": "15% Congé"
                                            }
                                          },
                                          "style": {
                                            "textStyle": {
                                              "styleName": "body_small"
                                            }
                                          }
                                        },
                                        "editorId": "text91"
                                      }
                                    ],
                                    "editorId": "row47"
                                  }
                                ],
                                "editorId": "column60"
                              }
                            ],
                            "editorId": "row44"
                          }
                        ],
                        "editorId": "container48"
                      }
                    ],
                    "editorId": "column59"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Top retards (Fréquence)"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_large"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          }
                        },
                        "editorId": "text92"
                      },
                      {
                        "type": "container",
                        "properties": {
                          "bg": {
                            "color": {
                              "color": "surface"
                            }
                          },
                          "padding": {
                            "edgeInsets": {
                              "top": 0,
                              "right": 0,
                              "bottom": 0,
                              "left": 0,
                              "token": "lg"
                            }
                          },
                          "radius": {
                            "radius": {
                              "topLeft": 6,
                              "topRight": 6,
                              "bottomLeft": 6,
                              "bottomRight": 6
                            }
                          },
                          "border": {
                            "border": {
                              "width": 1,
                              "color": "divider"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "column",
                            "properties": {
                              "spacing": {
                                "stringVal": {
                                  "value": "md"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "@rank_item",
                                "properties": {
                                  "rank": {
                                    "stringVal": {
                                      "value": "1"
                                    }
                                  },
                                  "name": {
                                    "stringVal": {
                                      "value": "Marc Dupont"
                                    }
                                  },
                                  "subtitle": {
                                    "stringVal": {
                                      "value": "Heure moy. 08:32"
                                    }
                                  },
                                  "value": {
                                    "stringVal": {
                                      "value": "8"
                                    }
                                  }
                                },
                                "editorId": "rank1"
                              },
                              {
                                "type": "divider",
                                "properties": {
                                  "color": {
                                    "color": {
                                      "color": "divider"
                                    }
                                  }
                                },
                                "editorId": "div1"
                              },
                              {
                                "type": "@rank_item",
                                "properties": {
                                  "rank": {
                                    "stringVal": {
                                      "value": "2"
                                    }
                                  },
                                  "name": {
                                    "stringVal": {
                                      "value": "Sarah Benali"
                                    }
                                  },
                                  "subtitle": {
                                    "stringVal": {
                                      "value": "Heure moy. 08:24"
                                    }
                                  },
                                  "value": {
                                    "stringVal": {
                                      "value": "5"
                                    }
                                  }
                                },
                                "editorId": "rank2"
                              },
                              {
                                "type": "divider",
                                "properties": {
                                  "color": {
                                    "color": {
                                      "color": "divider"
                                    }
                                  }
                                },
                                "editorId": "div2"
                              },
                              {
                                "type": "@rank_item",
                                "properties": {
                                  "rank": {
                                    "stringVal": {
                                      "value": "3"
                                    }
                                  },
                                  "name": {
                                    "stringVal": {
                                      "value": "Jean-Baptiste L."
                                    }
                                  },
                                  "subtitle": {
                                    "stringVal": {
                                      "value": "Heure moy. 08:45"
                                    }
                                  },
                                  "value": {
                                    "stringVal": {
                                      "value": "3"
                                    }
                                  }
                                },
                                "editorId": "rank3"
                              }
                            ],
                            "editorId": "column62"
                          }
                        ],
                        "editorId": "container53"
                      }
                    ],
                    "editorId": "column61"
                  },
                  {
                    "type": "@std.button",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "Générer la synthèse Excel"
                        }
                      },
                      "variant": {
                        "stringVal": {
                          "value": "outline"
                        }
                      },
                      "full_width": {
                        "boolVal": {
                          "value": true
                        }
                      },
                      "icon": {
                        "stringVal": {
                          "value": "description_rounded"
                        }
                      }
                    },
                    "editorId": "stdbutton6"
                  },
                  {
                    "type": "sizedbox",
                    "properties": {
                      "height": {
                        "stringVal": {
                          "value": "lg"
                        }
                      }
                    },
                    "editorId": "sizedbox1"
                  }
                ],
                "editorId": "column56"
              }
            ],
            "editorId": "expanded7"
          }
        ],
        "editorId": "column54"
      }
    ],
    "editorId": "scaffold7"
  }
}
```

### 8. Exports & Files

- Frame ID: `frame5`
- Original page prompt: "Archive of generated PDF reports and Excel syntheses with options to open, rename, or share files."
- Follow-up prompts: _None_

#### DslDocument (JSON)

```json
{
  "root": {
    "type": "scaffold",
    "properties": {
      "bg": {
        "color": {
          "color": "background"
        }
      }
    },
    "children": [
      {
        "type": "column",
        "properties": {
          "cross_align": {
            "align": {
              "named": "stretch"
            }
          }
        },
        "children": [
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "topToken": "lg",
                  "rightToken": "md",
                  "bottomToken": "sm",
                  "leftToken": "md"
                }
              },
              "border": {
                "borderSided": {
                  "side": "bottom",
                  "width": 1,
                  "color": "divider"
                }
              }
            },
            "children": [
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  }
                },
                "children": [
                  {
                    "type": "row",
                    "properties": {
                      "align": {
                        "align": {
                          "named": "space_between"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Archives & Exports"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "title_large"
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          }
                        },
                        "editorId": "text93"
                      },
                      {
                        "type": "iconbutton",
                        "properties": {
                          "name": {
                            "icon": {
                              "name": "search_rounded"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary_text"
                            }
                          }
                        },
                        "editorId": "iconbutton17"
                      }
                    ],
                    "editorId": "row48"
                  },
                  {
                    "type": "row",
                    "properties": {
                      "align": {
                        "align": {
                          "named": "space_evenly"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "@tab_indicator",
                        "properties": {
                          "label": {
                            "stringVal": {
                              "value": "Rapports PDF"
                            }
                          },
                          "active": {
                            "boolVal": {
                              "value": true
                            }
                          }
                        },
                        "editorId": "tabindicator1"
                      },
                      {
                        "type": "@tab_indicator",
                        "properties": {
                          "label": {
                            "stringVal": {
                              "value": "Synthèses Excel"
                            }
                          },
                          "active": {
                            "boolVal": {
                              "value": false
                            }
                          }
                        },
                        "editorId": "tabindicator2"
                      }
                    ],
                    "editorId": "row49"
                  }
                ],
                "editorId": "column64"
              }
            ],
            "editorId": "container54"
          },
          {
            "type": "expanded",
            "children": [
              {
                "type": "column",
                "properties": {
                  "scroll": {
                    "boolVal": {
                      "value": true
                    }
                  },
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "token": "lg"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "stretch"
                    }
                  }
                },
                "children": [
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "RÉCENTS"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "label_small"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "secondary_text"
                        }
                      },
                      "margin": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "bottomToken": "md"
                        }
                      }
                    },
                    "editorId": "text94"
                  },
                  {
                    "type": "@file_card",
                    "properties": {
                      "name": {
                        "stringVal": {
                          "value": "rapport-pointage-2023-10-24.pdf"
                        }
                      },
                      "date": {
                        "stringVal": {
                          "value": "Aujourd'hui, 17:05"
                        }
                      },
                      "size": {
                        "stringVal": {
                          "value": "142 KB"
                        }
                      },
                      "type": {
                        "stringVal": {
                          "value": "pdf"
                        }
                      }
                    },
                    "editorId": "file1"
                  },
                  {
                    "type": "@file_card",
                    "properties": {
                      "name": {
                        "stringVal": {
                          "value": "synthese-octobre-2023.xlsx"
                        }
                      },
                      "date": {
                        "stringVal": {
                          "value": "Hier, 09:12"
                        }
                      },
                      "size": {
                        "stringVal": {
                          "value": "2.4 MB"
                        }
                      },
                      "type": {
                        "stringVal": {
                          "value": "excel"
                        }
                      }
                    },
                    "editorId": "file2"
                  },
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "OCTOBRE 2023"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "label_small"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "secondary_text"
                        }
                      },
                      "margin": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "topToken": "lg",
                          "bottomToken": "md"
                        }
                      }
                    },
                    "editorId": "text95"
                  },
                  {
                    "type": "@file_card",
                    "properties": {
                      "name": {
                        "stringVal": {
                          "value": "rapport-pointage-2023-10-23.pdf"
                        }
                      },
                      "date": {
                        "stringVal": {
                          "value": "23 oct. 2023"
                        }
                      },
                      "size": {
                        "stringVal": {
                          "value": "138 KB"
                        }
                      },
                      "type": {
                        "stringVal": {
                          "value": "pdf"
                        }
                      }
                    },
                    "editorId": "file3"
                  },
                  {
                    "type": "@file_card",
                    "properties": {
                      "name": {
                        "stringVal": {
                          "value": "rapport-pointage-2023-10-22.pdf"
                        }
                      },
                      "date": {
                        "stringVal": {
                          "value": "22 oct. 2023"
                        }
                      },
                      "size": {
                        "stringVal": {
                          "value": "145 KB"
                        }
                      },
                      "type": {
                        "stringVal": {
                          "value": "pdf"
                        }
                      }
                    },
                    "editorId": "file4"
                  },
                  {
                    "type": "@file_card",
                    "properties": {
                      "name": {
                        "stringVal": {
                          "value": "rapport-pointage-2023-10-21.pdf"
                        }
                      },
                      "date": {
                        "stringVal": {
                          "value": "21 oct. 2023"
                        }
                      },
                      "size": {
                        "stringVal": {
                          "value": "140 KB"
                        }
                      },
                      "type": {
                        "stringVal": {
                          "value": "pdf"
                        }
                      }
                    },
                    "editorId": "file5"
                  },
                  {
                    "type": "@file_card",
                    "properties": {
                      "name": {
                        "stringVal": {
                          "value": "synthese-semaine-42.xlsx"
                        }
                      },
                      "date": {
                        "stringVal": {
                          "value": "20 oct. 2023"
                        }
                      },
                      "size": {
                        "stringVal": {
                          "value": "1.1 MB"
                        }
                      },
                      "type": {
                        "stringVal": {
                          "value": "excel"
                        }
                      }
                    },
                    "editorId": "file6"
                  },
                  {
                    "type": "@file_card",
                    "properties": {
                      "name": {
                        "stringVal": {
                          "value": "rapport-pointage-2023-10-20.pdf"
                        }
                      },
                      "date": {
                        "stringVal": {
                          "value": "20 oct. 2023"
                        }
                      },
                      "size": {
                        "stringVal": {
                          "value": "139 KB"
                        }
                      },
                      "type": {
                        "stringVal": {
                          "value": "pdf"
                        }
                      }
                    },
                    "editorId": "file7"
                  }
                ],
                "editorId": "column65"
              }
            ],
            "editorId": "expanded9"
          },
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "token": "lg"
                }
              },
              "border": {
                "borderSided": {
                  "side": "top",
                  "width": 1,
                  "color": "divider"
                }
              },
              "shadow": {
                "stringVal": {
                  "value": "lg"
                }
              }
            },
            "children": [
              {
                "type": "row",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  }
                },
                "children": [
                  {
                    "type": "expanded",
                    "children": [
                      {
                        "type": "@std.button",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Nouveau PDF"
                            }
                          },
                          "variant": {
                            "stringVal": {
                              "value": "outline"
                            }
                          },
                          "icon": {
                            "stringVal": {
                              "value": "picture_as_pdf_rounded"
                            }
                          },
                          "full_width": {
                            "boolVal": {
                              "value": true
                            }
                          }
                        },
                        "editorId": "stdbutton7"
                      }
                    ],
                    "editorId": "expanded10"
                  },
                  {
                    "type": "expanded",
                    "children": [
                      {
                        "type": "@std.button",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Synthèse Excel"
                            }
                          },
                          "variant": {
                            "stringVal": {
                              "value": "primary"
                            }
                          },
                          "icon": {
                            "stringVal": {
                              "value": "add_chart_rounded"
                            }
                          },
                          "full_width": {
                            "boolVal": {
                              "value": true
                            }
                          }
                        },
                        "editorId": "stdbutton8"
                      }
                    ],
                    "editorId": "expanded11"
                  }
                ],
                "editorId": "row50"
              }
            ],
            "editorId": "container55"
          }
        ],
        "editorId": "column63"
      }
    ],
    "editorId": "scaffold8"
  }
}
```

### 9. User Management

- Frame ID: `frame6`
- Original page prompt: "Admin-only screen for creating and managing app users, roles (Admin/Agent), and account status."
- Follow-up prompts: _None_

#### DslDocument (JSON)

```json
{
  "root": {
    "type": "scaffold",
    "properties": {
      "bg": {
        "color": {
          "color": "background"
        }
      }
    },
    "children": [
      {
        "type": "column",
        "properties": {
          "cross_align": {
            "align": {
              "named": "stretch"
            }
          }
        },
        "children": [
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "topToken": "lg",
                  "rightToken": "md",
                  "bottomToken": "lg",
                  "leftToken": "md"
                }
              },
              "border": {
                "borderSided": {
                  "side": "bottom",
                  "width": 1,
                  "color": "divider"
                }
              }
            },
            "children": [
              {
                "type": "row",
                "properties": {
                  "align": {
                    "align": {
                      "named": "space_between"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "center"
                    }
                  }
                },
                "children": [
                  {
                    "type": "row",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "iconbutton",
                        "properties": {
                          "name": {
                            "icon": {
                              "name": "arrow_back_rounded"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary_text"
                            }
                          }
                        },
                        "editorId": "iconbutton18"
                      },
                      {
                        "type": "column",
                        "properties": {
                          "cross_align": {
                            "align": {
                              "named": "start"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "ADMINISTRATION"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "label_small"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "secondary_text"
                                }
                              }
                            },
                            "editorId": "text96"
                          },
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "Gestion Utilisateurs"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "title_medium"
                                }
                              },
                              "font_weight": {
                                "stringVal": {
                                  "value": "bold"
                                }
                              }
                            },
                            "editorId": "text97"
                          }
                        ],
                        "editorId": "column67"
                      }
                    ],
                    "editorId": "row52"
                  },
                  {
                    "type": "iconbutton",
                    "properties": {
                      "name": {
                        "icon": {
                          "name": "search_rounded"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "primary_text"
                        }
                      }
                    },
                    "editorId": "iconbutton19"
                  }
                ],
                "editorId": "row51"
              }
            ],
            "editorId": "container56"
          },
          {
            "type": "expanded",
            "children": [
              {
                "type": "column",
                "properties": {
                  "scroll": {
                    "boolVal": {
                      "value": true
                    }
                  },
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "token": "lg"
                    }
                  },
                  "spacing": {
                    "stringVal": {
                      "value": "lg"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "stretch"
                    }
                  }
                },
                "children": [
                  {
                    "type": "row",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "container",
                        "properties": {
                          "bg": {
                            "color": {
                              "color": "surface"
                            }
                          },
                          "padding": {
                            "edgeInsets": {
                              "top": 0,
                              "right": 0,
                              "bottom": 0,
                              "left": 0,
                              "token": "md"
                            }
                          },
                          "radius": {
                            "radius": {
                              "topLeft": 6,
                              "topRight": 6,
                              "bottomLeft": 6,
                              "bottomRight": 6
                            }
                          },
                          "border": {
                            "border": {
                              "width": 1,
                              "color": "divider"
                            }
                          },
                          "expanded": {
                            "expanded": {
                              "enabled": true,
                              "flex": 1
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "column",
                            "properties": {
                              "spacing": {
                                "stringVal": {
                                  "value": "xs"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "text",
                                "properties": {
                                  "content": {
                                    "stringVal": {
                                      "value": "TOTAL"
                                    }
                                  },
                                  "style": {
                                    "textStyle": {
                                      "styleName": "label_small"
                                    }
                                  },
                                  "color": {
                                    "color": {
                                      "color": "secondary_text"
                                    }
                                  }
                                },
                                "editorId": "text98"
                              },
                              {
                                "type": "text",
                                "properties": {
                                  "content": {
                                    "stringVal": {
                                      "value": "12"
                                    }
                                  },
                                  "style": {
                                    "textStyle": {
                                      "styleName": "headline_small"
                                    }
                                  },
                                  "font_weight": {
                                    "stringVal": {
                                      "value": "bold"
                                    }
                                  },
                                  "color": {
                                    "color": {
                                      "color": "primary_text"
                                    }
                                  }
                                },
                                "editorId": "text99"
                              }
                            ],
                            "editorId": "column69"
                          }
                        ],
                        "editorId": "container57"
                      },
                      {
                        "type": "container",
                        "properties": {
                          "bg": {
                            "color": {
                              "color": "surface"
                            }
                          },
                          "padding": {
                            "edgeInsets": {
                              "top": 0,
                              "right": 0,
                              "bottom": 0,
                              "left": 0,
                              "token": "md"
                            }
                          },
                          "radius": {
                            "radius": {
                              "topLeft": 6,
                              "topRight": 6,
                              "bottomLeft": 6,
                              "bottomRight": 6
                            }
                          },
                          "border": {
                            "border": {
                              "width": 1,
                              "color": "divider"
                            }
                          },
                          "expanded": {
                            "expanded": {
                              "enabled": true,
                              "flex": 1
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "column",
                            "properties": {
                              "spacing": {
                                "stringVal": {
                                  "value": "xs"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "text",
                                "properties": {
                                  "content": {
                                    "stringVal": {
                                      "value": "ACTIFS"
                                    }
                                  },
                                  "style": {
                                    "textStyle": {
                                      "styleName": "label_small"
                                    }
                                  },
                                  "color": {
                                    "color": {
                                      "color": "secondary_text"
                                    }
                                  }
                                },
                                "editorId": "text100"
                              },
                              {
                                "type": "row",
                                "properties": {
                                  "spacing": {
                                    "stringVal": {
                                      "value": "xs"
                                    }
                                  },
                                  "cross_align": {
                                    "align": {
                                      "named": "center"
                                    }
                                  }
                                },
                                "children": [
                                  {
                                    "type": "text",
                                    "properties": {
                                      "content": {
                                        "stringVal": {
                                          "value": "11"
                                        }
                                      },
                                      "style": {
                                        "textStyle": {
                                          "styleName": "headline_small"
                                        }
                                      },
                                      "font_weight": {
                                        "stringVal": {
                                          "value": "bold"
                                        }
                                      },
                                      "color": {
                                        "color": {
                                          "color": "success"
                                        }
                                      }
                                    },
                                    "editorId": "text101"
                                  },
                                  {
                                    "type": "icon",
                                    "properties": {
                                      "name": {
                                        "icon": {
                                          "name": "check_circle_rounded"
                                        }
                                      },
                                      "color": {
                                        "color": {
                                          "color": "success"
                                        }
                                      },
                                      "size": {
                                        "numberVal": {
                                          "value": 16
                                        }
                                      }
                                    },
                                    "editorId": "icon18"
                                  }
                                ],
                                "editorId": "row54"
                              }
                            ],
                            "editorId": "column70"
                          }
                        ],
                        "editorId": "container58"
                      }
                    ],
                    "editorId": "row53"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "cross_align": {
                        "align": {
                          "named": "stretch"
                        }
                      },
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "ADMINISTRATEURS"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_large"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          }
                        },
                        "editorId": "text102"
                      },
                      {
                        "type": "@user_card",
                        "properties": {
                          "initials": {
                            "stringVal": {
                              "value": "AL"
                            }
                          },
                          "name": {
                            "stringVal": {
                              "value": "Amina Lemrani"
                            }
                          },
                          "email": {
                            "stringVal": {
                              "value": "a.lemrani@crfc.ma"
                            }
                          },
                          "job": {
                            "stringVal": {
                              "value": "Directrice RH"
                            }
                          },
                          "is_admin": {
                            "boolVal": {
                              "value": true
                            }
                          }
                        },
                        "editorId": "user1"
                      },
                      {
                        "type": "@user_card",
                        "properties": {
                          "initials": {
                            "stringVal": {
                              "value": "KB"
                            }
                          },
                          "name": {
                            "stringVal": {
                              "value": "Karim Bensaid"
                            }
                          },
                          "email": {
                            "stringVal": {
                              "value": "k.bensaid@crfc.ma"
                            }
                          },
                          "job": {
                            "stringVal": {
                              "value": "Admin Système"
                            }
                          },
                          "is_admin": {
                            "boolVal": {
                              "value": true
                            }
                          }
                        },
                        "editorId": "user2"
                      }
                    ],
                    "editorId": "column71"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "cross_align": {
                        "align": {
                          "named": "stretch"
                        }
                      },
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "AGENTS DE POINTAGE"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_large"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          }
                        },
                        "editorId": "text103"
                      },
                      {
                        "type": "@user_card",
                        "properties": {
                          "initials": {
                            "stringVal": {
                              "value": "OM"
                            }
                          },
                          "name": {
                            "stringVal": {
                              "value": "Omar Mansouri"
                            }
                          },
                          "email": {
                            "stringVal": {
                              "value": "o.mansouri@crfc.ma"
                            }
                          },
                          "job": {
                            "stringVal": {
                              "value": "Agent d'accueil"
                            }
                          },
                          "is_admin": {
                            "boolVal": {
                              "value": false
                            }
                          }
                        },
                        "editorId": "user3"
                      },
                      {
                        "type": "@user_card",
                        "properties": {
                          "initials": {
                            "stringVal": {
                              "value": "HI"
                            }
                          },
                          "name": {
                            "stringVal": {
                              "value": "Hafsa Idrissi"
                            }
                          },
                          "email": {
                            "stringVal": {
                              "value": "h.idrissi@crfc.ma"
                            }
                          },
                          "job": {
                            "stringVal": {
                              "value": "Sécurité"
                            }
                          },
                          "is_admin": {
                            "boolVal": {
                              "value": false
                            }
                          }
                        },
                        "editorId": "user4"
                      },
                      {
                        "type": "@user_card",
                        "properties": {
                          "initials": {
                            "stringVal": {
                              "value": "YB"
                            }
                          },
                          "name": {
                            "stringVal": {
                              "value": "Youssef Bakri"
                            }
                          },
                          "email": {
                            "stringVal": {
                              "value": "y.bakri@crfc.ma"
                            }
                          },
                          "job": {
                            "stringVal": {
                              "value": "Contrôleur"
                            }
                          },
                          "is_admin": {
                            "boolVal": {
                              "value": false
                            }
                          }
                        },
                        "editorId": "user5"
                      },
                      {
                        "type": "@user_card",
                        "properties": {
                          "initials": {
                            "stringVal": {
                              "value": "ST"
                            }
                          },
                          "name": {
                            "stringVal": {
                              "value": "Sonia Tazi"
                            }
                          },
                          "email": {
                            "stringVal": {
                              "value": "s.tazi@crfc.ma"
                            }
                          },
                          "job": {
                            "stringVal": {
                              "value": "Accueil Bâtiment B"
                            }
                          },
                          "is_admin": {
                            "boolVal": {
                              "value": false
                            }
                          }
                        },
                        "editorId": "user6"
                      }
                    ],
                    "editorId": "column72"
                  },
                  {
                    "type": "container",
                    "properties": {
                      "bg": {
                        "color": {
                          "color": "surface_variant"
                        }
                      },
                      "padding": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "token": "md"
                        }
                      },
                      "radius": {
                        "radius": {
                          "topLeft": 6,
                          "topRight": 6,
                          "bottomLeft": 6,
                          "bottomRight": 6
                        }
                      },
                      "border": {
                        "border": {
                          "width": 1,
                          "color": "divider"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "row",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "md"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "icon",
                            "properties": {
                              "name": {
                                "icon": {
                                  "name": "lock_person_rounded"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "secondary_text"
                                }
                              }
                            },
                            "editorId": "icon19"
                          },
                          {
                            "type": "column",
                            "properties": {
                              "cross_align": {
                                "align": {
                                  "named": "start"
                                }
                              },
                              "expanded": {
                                "expanded": {
                                  "enabled": true,
                                  "flex": 1
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "text",
                                "properties": {
                                  "content": {
                                    "stringVal": {
                                      "value": "1 Compte désactivé"
                                    }
                                  },
                                  "style": {
                                    "textStyle": {
                                      "styleName": "body_medium"
                                    }
                                  },
                                  "font_weight": {
                                    "numberVal": {
                                      "value": 600
                                    }
                                  }
                                },
                                "editorId": "text104"
                              },
                              {
                                "type": "text",
                                "properties": {
                                  "content": {
                                    "stringVal": {
                                      "value": "Mouloud E. (Ancien Agent)"
                                    }
                                  },
                                  "style": {
                                    "textStyle": {
                                      "styleName": "body_small"
                                    }
                                  },
                                  "color": {
                                    "color": {
                                      "color": "secondary_text"
                                    }
                                  }
                                },
                                "editorId": "text105"
                              }
                            ],
                            "editorId": "column73"
                          },
                          {
                            "type": "@std.button",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "Gérer"
                                }
                              },
                              "variant": {
                                "stringVal": {
                                  "value": "ghost"
                                }
                              },
                              "size": {
                                "stringVal": {
                                  "value": "small"
                                }
                              }
                            },
                            "editorId": "stdbutton9"
                          }
                        ],
                        "editorId": "row55"
                      }
                    ],
                    "editorId": "container59"
                  }
                ],
                "editorId": "column68"
              }
            ],
            "editorId": "expanded12"
          },
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "token": "lg"
                }
              },
              "border": {
                "borderSided": {
                  "side": "top",
                  "width": 1,
                  "color": "divider"
                }
              },
              "shadow": {
                "stringVal": {
                  "value": "lg"
                }
              }
            },
            "children": [
              {
                "type": "@std.button",
                "properties": {
                  "content": {
                    "stringVal": {
                      "value": "Nouvel Utilisateur"
                    }
                  },
                  "variant": {
                    "stringVal": {
                      "value": "primary"
                    }
                  },
                  "full_width": {
                    "boolVal": {
                      "value": true
                    }
                  },
                  "icon": {
                    "stringVal": {
                      "value": "person_add_rounded"
                    }
                  }
                },
                "editorId": "stdbutton10"
              }
            ],
            "editorId": "container60"
          }
        ],
        "editorId": "column66"
      }
    ],
    "editorId": "scaffold9"
  }
}
```

### 10. Profile Settings

- Frame ID: `frame3`
- Original page prompt: "User profile page to edit personal details, job title, and change password."
- Follow-up prompts: _None_

#### DslDocument (JSON)

```json
{
  "root": {
    "type": "scaffold",
    "properties": {
      "bg": {
        "color": {
          "color": "background"
        }
      }
    },
    "children": [
      {
        "type": "column",
        "properties": {
          "cross_align": {
            "align": {
              "named": "stretch"
            }
          }
        },
        "children": [
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "topToken": "lg",
                  "rightToken": "md",
                  "bottomToken": "lg",
                  "leftToken": "md"
                }
              },
              "border": {
                "borderSided": {
                  "side": "bottom",
                  "width": 1,
                  "color": "divider"
                }
              }
            },
            "children": [
              {
                "type": "row",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  },
                  "align": {
                    "align": {
                      "named": "space_between"
                    }
                  }
                },
                "children": [
                  {
                    "type": "row",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "iconbutton",
                        "properties": {
                          "name": {
                            "icon": {
                              "name": "arrow_back_rounded"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary_text"
                            }
                          }
                        },
                        "editorId": "iconbutton20"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "MON PROFIL"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "title_medium"
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          }
                        },
                        "editorId": "text106"
                      }
                    ],
                    "editorId": "row57"
                  },
                  {
                    "type": "@std.button",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "Enregistrer"
                        }
                      },
                      "variant": {
                        "stringVal": {
                          "value": "ghost"
                        }
                      },
                      "size": {
                        "stringVal": {
                          "value": "small"
                        }
                      }
                    },
                    "editorId": "stdbutton11"
                  }
                ],
                "editorId": "row56"
              }
            ],
            "editorId": "container61"
          },
          {
            "type": "expanded",
            "children": [
              {
                "type": "column",
                "properties": {
                  "scroll": {
                    "boolVal": {
                      "value": true
                    }
                  },
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "token": "lg"
                    }
                  },
                  "spacing": {
                    "stringVal": {
                      "value": "lg"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "stretch"
                    }
                  }
                },
                "children": [
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "avatar",
                        "properties": {
                          "text": {
                            "stringVal": {
                              "value": "AR"
                            }
                          },
                          "size": {
                            "numberVal": {
                              "value": 80
                            }
                          },
                          "bg": {
                            "color": {
                              "color": "primary"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "on_primary"
                            }
                          },
                          "font_size": {
                            "numberVal": {
                              "value": 28
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          }
                        },
                        "editorId": "avatar4"
                      },
                      {
                        "type": "column",
                        "properties": {
                          "cross_align": {
                            "align": {
                              "named": "center"
                            }
                          },
                          "spacing": {
                            "stringVal": {
                              "value": "xs"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "Alex Rivera"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "headline_small"
                                }
                              },
                              "font_weight": {
                                "stringVal": {
                                  "value": "bold"
                                }
                              }
                            },
                            "editorId": "text107"
                          },
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "ADMINISTRATEUR"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "label_small"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "primary"
                                }
                              }
                            },
                            "editorId": "text108"
                          }
                        ],
                        "editorId": "column77"
                      }
                    ],
                    "editorId": "column76"
                  },
                  {
                    "type": "@setting_card",
                    "properties": {
                      "title": {
                        "stringVal": {
                          "value": "Informations personnelles"
                        }
                      },
                      "icon": {
                        "stringVal": {
                          "value": "person_outline_rounded"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "column",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "md"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "@profile_field_group",
                            "properties": {
                              "label": {
                                "stringVal": {
                                  "value": "Prénom"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "@std.textfield",
                                "properties": {
                                  "value": {
                                    "stringVal": {
                                      "value": "Alex"
                                    }
                                  },
                                  "variant": {
                                    "stringVal": {
                                      "value": "outlined"
                                    }
                                  }
                                },
                                "editorId": "stdtextfield2"
                              }
                            ],
                            "editorId": "profilefieldgroup1"
                          },
                          {
                            "type": "@profile_field_group",
                            "properties": {
                              "label": {
                                "stringVal": {
                                  "value": "Nom"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "@std.textfield",
                                "properties": {
                                  "value": {
                                    "stringVal": {
                                      "value": "Rivera"
                                    }
                                  },
                                  "variant": {
                                    "stringVal": {
                                      "value": "outlined"
                                    }
                                  }
                                },
                                "editorId": "textfield2"
                              }
                            ],
                            "editorId": "profilefieldgroup2"
                          },
                          {
                            "type": "@profile_field_group",
                            "properties": {
                              "label": {
                                "stringVal": {
                                  "value": "Fonction / Poste"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "@std.textfield",
                                "properties": {
                                  "value": {
                                    "stringVal": {
                                      "value": "Responsable d'Exploitation"
                                    }
                                  },
                                  "variant": {
                                    "stringVal": {
                                      "value": "outlined"
                                    }
                                  }
                                },
                                "editorId": "textfield3"
                              }
                            ],
                            "editorId": "profilefieldgroup3"
                          },
                          {
                            "type": "@profile_field_group",
                            "properties": {
                              "label": {
                                "stringVal": {
                                  "value": "Email (Identifiant)"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "@std.textfield",
                                "properties": {
                                  "value": {
                                    "stringVal": {
                                      "value": "a.rivera@crfc.dz"
                                    }
                                  },
                                  "variant": {
                                    "stringVal": {
                                      "value": "outlined"
                                    }
                                  },
                                  "disabled": {
                                    "boolVal": {
                                      "value": true
                                    }
                                  }
                                },
                                "editorId": "textfield4"
                              }
                            ],
                            "editorId": "profilefieldgroup4"
                          }
                        ],
                        "editorId": "column78"
                      }
                    ],
                    "editorId": "settingcard1"
                  },
                  {
                    "type": "@setting_card",
                    "properties": {
                      "title": {
                        "stringVal": {
                          "value": "Sécurité"
                        }
                      },
                      "icon": {
                        "stringVal": {
                          "value": "lock_outline_rounded"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "column",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "md"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "Changer le mot de passe"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "body_medium"
                                }
                              },
                              "font_weight": {
                                "numberVal": {
                                  "value": 600
                                }
                              }
                            },
                            "editorId": "text109"
                          },
                          {
                            "type": "@profile_field_group",
                            "properties": {
                              "label": {
                                "stringVal": {
                                  "value": "Mot de passe actuel"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "@std.textfield",
                                "properties": {
                                  "hint": {
                                    "stringVal": {
                                      "value": "••••••••"
                                    }
                                  },
                                  "variant": {
                                    "stringVal": {
                                      "value": "outlined"
                                    }
                                  },
                                  "trailing_icon": {
                                    "stringVal": {
                                      "value": "visibility_off_rounded"
                                    }
                                  }
                                },
                                "editorId": "textfield5"
                              }
                            ],
                            "editorId": "profilefieldgroup5"
                          },
                          {
                            "type": "@profile_field_group",
                            "properties": {
                              "label": {
                                "stringVal": {
                                  "value": "Nouveau mot de passe"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "@std.textfield",
                                "properties": {
                                  "hint": {
                                    "stringVal": {
                                      "value": "Minimum 8 caractères"
                                    }
                                  },
                                  "variant": {
                                    "stringVal": {
                                      "value": "outlined"
                                    }
                                  },
                                  "trailing_icon": {
                                    "stringVal": {
                                      "value": "visibility_off_rounded"
                                    }
                                  }
                                },
                                "editorId": "textfield6"
                              }
                            ],
                            "editorId": "profilefieldgroup6"
                          },
                          {
                            "type": "@std.button",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "Mettre à jour le mot de passe"
                                }
                              },
                              "variant": {
                                "stringVal": {
                                  "value": "outline"
                                }
                              },
                              "full_width": {
                                "boolVal": {
                                  "value": true
                                }
                              }
                            },
                            "editorId": "stdbutton12"
                          }
                        ],
                        "editorId": "column79"
                      }
                    ],
                    "editorId": "settingcard2"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "sm"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "stretch"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "SESSION"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_small"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          },
                          "padding": {
                            "edgeInsets": {
                              "top": 0,
                              "right": 0,
                              "bottom": 0,
                              "left": 0,
                              "leftToken": "xs"
                            }
                          }
                        },
                        "editorId": "text110"
                      },
                      {
                        "type": "container",
                        "properties": {
                          "bg": {
                            "color": {
                              "color": "surface"
                            }
                          },
                          "radius": {
                            "radius": {
                              "topLeft": 0,
                              "topRight": 0,
                              "bottomLeft": 0,
                              "bottomRight": 0,
                              "token": "md"
                            }
                          },
                          "border": {
                            "border": {
                              "width": 1,
                              "color": "divider"
                            }
                          },
                          "clip": {
                            "boolVal": {
                              "value": true
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "column",
                            "properties": {
                              "divider": {
                                "boolVal": {
                                  "value": true
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "row",
                                "properties": {
                                  "padding": {
                                    "edgeInsets": {
                                      "top": 0,
                                      "right": 0,
                                      "bottom": 0,
                                      "left": 0,
                                      "token": "md"
                                    }
                                  },
                                  "align": {
                                    "align": {
                                      "named": "space_between"
                                    }
                                  }
                                },
                                "children": [
                                  {
                                    "type": "row",
                                    "properties": {
                                      "spacing": {
                                        "stringVal": {
                                          "value": "md"
                                        }
                                      }
                                    },
                                    "children": [
                                      {
                                        "type": "icon",
                                        "properties": {
                                          "name": {
                                            "icon": {
                                              "name": "brightness_6_rounded"
                                            }
                                          },
                                          "color": {
                                            "color": {
                                              "color": "secondary_text"
                                            }
                                          },
                                          "size": {
                                            "numberVal": {
                                              "value": 20
                                            }
                                          }
                                        },
                                        "editorId": "icon20"
                                      },
                                      {
                                        "type": "text",
                                        "properties": {
                                          "content": {
                                            "stringVal": {
                                              "value": "Mode sombre"
                                            }
                                          },
                                          "style": {
                                            "textStyle": {
                                              "styleName": "body_medium"
                                            }
                                          }
                                        },
                                        "editorId": "text111"
                                      }
                                    ],
                                    "editorId": "row59"
                                  },
                                  {
                                    "type": "@std.switch",
                                    "properties": {
                                      "active": {
                                        "boolVal": {
                                          "value": false
                                        }
                                      }
                                    },
                                    "editorId": "stdswitch1"
                                  }
                                ],
                                "editorId": "row58"
                              },
                              {
                                "type": "row",
                                "properties": {
                                  "padding": {
                                    "edgeInsets": {
                                      "top": 0,
                                      "right": 0,
                                      "bottom": 0,
                                      "left": 0,
                                      "token": "md"
                                    }
                                  },
                                  "align": {
                                    "align": {
                                      "named": "space_between"
                                    }
                                  }
                                },
                                "children": [
                                  {
                                    "type": "row",
                                    "properties": {
                                      "spacing": {
                                        "stringVal": {
                                          "value": "md"
                                        }
                                      }
                                    },
                                    "children": [
                                      {
                                        "type": "icon",
                                        "properties": {
                                          "name": {
                                            "icon": {
                                              "name": "logout_rounded"
                                            }
                                          },
                                          "color": {
                                            "color": {
                                              "color": "error"
                                            }
                                          },
                                          "size": {
                                            "numberVal": {
                                              "value": 20
                                            }
                                          }
                                        },
                                        "editorId": "icon21"
                                      },
                                      {
                                        "type": "text",
                                        "properties": {
                                          "content": {
                                            "stringVal": {
                                              "value": "Déconnexion"
                                            }
                                          },
                                          "style": {
                                            "textStyle": {
                                              "styleName": "body_medium"
                                            }
                                          },
                                          "color": {
                                            "color": {
                                              "color": "error"
                                            }
                                          }
                                        },
                                        "editorId": "text112"
                                      }
                                    ],
                                    "editorId": "row61"
                                  },
                                  {
                                    "type": "icon",
                                    "properties": {
                                      "name": {
                                        "icon": {
                                          "name": "chevron_right_rounded"
                                        }
                                      },
                                      "color": {
                                        "color": {
                                          "color": "secondary_text"
                                        }
                                      }
                                    },
                                    "editorId": "icon22"
                                  }
                                ],
                                "editorId": "row60"
                              }
                            ],
                            "editorId": "column81"
                          }
                        ],
                        "editorId": "container62"
                      }
                    ],
                    "editorId": "column80"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "cross_align": {
                        "align": {
                          "named": "center"
                        }
                      },
                      "spacing": {
                        "stringVal": {
                          "value": "xs"
                        }
                      },
                      "padding": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "topToken": "lg",
                          "bottomToken": "lg"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "CRFC Pointage v2.4.0"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_small"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          }
                        },
                        "editorId": "text113"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Dernière connexion : Aujourd'hui à 08:02"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "body_small"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "hint"
                            }
                          }
                        },
                        "editorId": "text114"
                      }
                    ],
                    "editorId": "column82"
                  }
                ],
                "editorId": "column75"
              }
            ],
            "editorId": "expanded13"
          },
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "token": "lg"
                }
              },
              "border": {
                "borderSided": {
                  "side": "top",
                  "width": 1,
                  "color": "divider"
                }
              },
              "shadow": {
                "stringVal": {
                  "value": "lg"
                }
              }
            },
            "children": [
              {
                "type": "@std.button",
                "properties": {
                  "content": {
                    "stringVal": {
                      "value": "Enregistrer les modifications"
                    }
                  },
                  "variant": {
                    "stringVal": {
                      "value": "primary"
                    }
                  },
                  "full_width": {
                    "boolVal": {
                      "value": true
                    }
                  },
                  "icon": {
                    "stringVal": {
                      "value": "check_rounded"
                    }
                  }
                },
                "editorId": "button3"
              }
            ],
            "editorId": "container63"
          }
        ],
        "editorId": "column74"
      }
    ],
    "editorId": "scaffold10"
  }
}
```