# ProfilBarres — profils de barres d'action pour WoW: Forever

Addon pour **World of Warcraft: Forever** qui permet d'enregistrer plusieurs **profils de barres d'action** et de passer de l'un à l'autre en un clic.

> Statut : **version 0.1.0, pas encore testée en jeu.** La logique est validée par des tests automatisés sur une API WoW simulée (`./dev.sh test`). Le comportement réel dans le client Forever reste à vérifier.

## Fonctionnalités

- **Bouton sur la minicarte** « Profil » qui ouvre et ferme la fenêtre de l'addon. Il est déplaçable autour de la minicarte et sa position est mémorisée. L'addon est aussi accessible depuis le menu des addons (Addon Compartment) et par la commande `/profil`.
- **Fenêtre de gestion des profils** :
  - créer un profil à partir de l'état actuel des barres, en lui donnant un nom ;
  - lister les profils enregistrés, avec la spécialisation, le nombre d'actions et de raccourcis et la date de mise à jour ;
  - **charger**, **renommer**, **écraser** ou **supprimer** un profil, avec une confirmation.
- **Contenu d'un profil** :
  - pour **chaque emplacement de barre d'action** : le sort, la macro, l'objet, la monture ou l'ensemble d'équipement qui s'y trouve ;
  - les **raccourcis clavier** associés à chaque emplacement (barre principale, barres multiples, barre de posture et barre de familier).
- **Restauration** : les barres et les raccourcis sont remis exactement comme dans le profil. Les emplacements vides dans le profil sont vidés, et les éléments indisponibles (sort non appris, objet absent des sacs, etc.) sont signalés dans le chat.

## Compatibilité

| Élément | Valeur |
|---|---|
| Jeu | WoW: Forever (Classic+ de Blizzard, sortie le 4 novembre 2026) |
| Client | Base Mainline/Midnight (API 12.1.x) |
| `## Interface` | `16001` (valeur de la bêta 1.60.1, à revérifier au lancement) |
| Type de jeu | `camelot` (nom interne de Forever) |
| Langue de l'interface | Français |

Les clients Classic Era, Cataclysm Classic et TBC Anniversary ne sont **pas** visés : leur API est différente.

## Installation (joueur)

### Téléchargement

👉 **[Télécharger la dernière version](https://github.com/Fastfire001/addon-wow-forever-profile/releases/latest)** : prendre le fichier **`ProfilBarres-x.y.z.zip`** dans la section *Assets*.

> ⚠️ Ne pas utiliser le bouton vert *Code > Download ZIP*, ni les fichiers *Source code* de la release. Ils contiennent tout le projet de développement, et le jeu ne les reconnaîtra pas comme un addon.

### Installation

1. Ouvrir le dossier des addons **de Forever** (et non celui de Retail ou de Classic). On le trouve via Battle.net > roue dentée > *Afficher dans l'explorateur* :
   - lancement : `World of Warcraft\_forever_\Interface\AddOns\` (nom du dossier non confirmé) ;
   - bêta : `World of Warcraft\_classic_beta_\Interface\AddOns\`.
2. Y décompresser le zip. On doit obtenir `...\Interface\AddOns\ProfilBarres\ProfilBarres.toc`, et non `...\AddOns\ProfilBarres\ProfilBarres\...`.
3. Relancer le jeu ou taper `/reload`.
4. Si l'addon n'apparaît pas, cocher *Charger les addons périmés* dans la liste des addons.

### Mise à jour

Supprimer l'ancien dossier `ProfilBarres`, puis décompresser la nouvelle version au même endroit. **Les profils ne sont pas perdus** : le jeu les enregistre dans le dossier `WTF`, pas dans celui de l'addon.

Les gestionnaires d'addons qui savent installer depuis GitHub (par exemple WowUp) peuvent aussi suivre les releases du dépôt `Fastfire001/addon-wow-forever-profile`. Leur prise en charge de Forever reste à vérifier.

## Utilisation

| Action | Comment |
|---|---|
| Ouvrir ou fermer la fenêtre | Clic sur le bouton de la minicarte, ou `/profil` |
| Déplacer le bouton | Glisser-déposer autour de la minicarte |
| Enregistrer un profil | Saisir un nom, puis *Enregistrer* (ou Entrée) |
| Charger un profil | *Charger*, puis confirmer |
| Mettre à jour un profil | *Écraser* : remplace le contenu par l'état actuel |
| Renommer un profil | *Renommer*, saisir le nouveau nom, puis valider (ou Entrée) |
| Supprimer un profil | *X*, puis confirmer |
| Masquer ou afficher le bouton | `/profil minimap` |

Deux cases à cocher permettent de choisir ce qui est restauré : **les actions**, **les raccourcis**, ou les deux.

Commandes de chat :

| Commande | Effet |
|---|---|
| `/profil` | Ouvre ou ferme la fenêtre |
| `/profil sauver <nom>` | Enregistre les barres actuelles sous ce nom (écrase s'il existe déjà) |
| `/profil charger <nom>` | Charge le profil, selon les options cochées |
| `/profil renommer <ancien> > <nouveau>` | Renomme un profil (le caractère `>` est donc interdit dans les noms) |
| `/profil liste` | Liste les profils du personnage |
| `/profil minimap` | Affiche ou masque le bouton de la minicarte |

Après un chargement, un résumé s'affiche dans le chat : nombre d'actions posées, retirées et inchangées, raccourcis restaurés, éléments introuvables et macros recréées.

## Limitations connues

- **Pas de chargement en combat** : poser des actions, créer des macros et modifier des raccourcis sont des opérations protégées par le jeu.
- **Les barres dépendent de la spécialisation** : un profil capture les barres de la spécialisation active au moment de l'enregistrement.
- **Profils propres à chaque personnage** : chaque personnage a sa propre liste de profils. Seuls les réglages (position du bouton de minicarte, options de restauration) sont communs au compte.
- **Macros** : elles sont retrouvées par leur nom et leur texte, ce qui permet d'avoir plusieurs macros du même nom (par exemple `" "` pour masquer le texte sur la barre). Une macro modifiée depuis l'enregistrement est retrouvée par son icône. Si une macro n'existe plus (ni même texte ni même icône), l'addon tente de la recréer à partir du texte sauvegardé, à condition qu'il reste de la place. Les profils enregistrés avec une version antérieure à cette correction peuvent contenir le mauvais texte pour des macros homonymes : il faut les réenregistrer.
- **Macros homonymes avec la même icône** : à l'enregistrement, si le jeu n'indique pas quelle macro est posée, l'addon les départage par l'icône affichée. Deux macros de même nom et de même icône (ou dont l'icône suit le sort, avec `#showtooltip`) peuvent alors être confondues : donne-leur des noms ou des icônes différents.
- **Non pris en charge** : les menus déroulants de sorts (flyouts, comme les portails du mage) et les actions de familier ne sont pas restaurés.
- Les profils sont écrits sur le disque par le jeu à la **déconnexion** ou au `/reload`. En cas de crash du client, les modifications de la session sont perdues.

## Développement

### Prérequis

Tous les outils tournent dans **Docker** : rien d'autre n'est à installer sur la machine.

- **Docker Desktop**, avec l'intégration WSL activée pour ta distribution (*Settings > Resources > WSL integration*).
- Le client WoW: Forever.
- Addons utiles pour le test en jeu : **BugSack** et **BugGrabber** (capture des erreurs Lua).
- Optionnel : un éditeur qui prend en charge Lua 5.1 (extension VS Code *WoW API* de Ketho, ou EmmyLua pour JetBrains).

### Environnement Docker

L'image `profilbarres-tools` (Debian, voir `docker/Dockerfile`) contient Lua 5.1, luacheck, zip, unzip et rsync. Toutes les commandes passent par `./dev.sh` :

| Commande | Effet |
|---|---|
| `./dev.sh build` | Construit l'image (à refaire seulement si `docker/Dockerfile` change) |
| `./dev.sh check` | Vérifie la syntaxe Lua 5.1 (`luac5.1 -p`), puis lance `luacheck` (configuré par `.luacheckrc`) |
| `./dev.sh test` | Lance les tests automatisés sur l'API WoW simulée (`tests/`) |
| `./dev.sh package [version]` | Crée `.release/ProfilBarres-<version>.zip` (par défaut `dev`), avec la version inscrite dans le TOC de l'archive |
| `./dev.sh deploy` | Copie `ProfilBarres/` dans le dossier AddOns du jeu (version affichée : `dev`) |
| `./dev.sh shell` | Ouvre un shell dans le conteneur |

Configuration du déploiement : copier `.env.example` en `.env` (fichier ignoré par git), puis renseigner `WOW_ADDONS_DIR` avec le chemin du dossier AddOns vu depuis WSL, par exemple :

```
WOW_ADDONS_DIR=/mnt/c/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns
```

`.luacheckrc` contient la liste des globaux WoW autorisés. Si luacheck signale une fonction WoW légitime comme inconnue (`W113`), il faut l'ajouter dans `read_globals`.

### Structure

```
.github/workflows/
├── ci.yml             # vérification à chaque push / pull request
└── release.yml        # publication d'une release quand un tag vX.Y.Z est poussé
compose.yaml           # services Docker : tools (vérification, packaging) et deploy
dev.sh                 # point d'entrée des commandes de développement
docker/Dockerfile      # image des outils
scripts/               # check.sh, test.sh, package.sh, deploy.sh (exécutés dans le conteneur)
tests/
├── wow_mock.lua       # simulation de l'API WoW utilisée par l'addon
└── run.lua            # scénarios de test
.luacheckrc            # configuration de luacheck (globaux WoW)
.env.example           # modèle de configuration locale (WOW_ADDONS_DIR)
todo.md                # fonctionnalités validées mais reportées
ProfilBarres/
├── ProfilBarres.toc   # métadonnées et ordre de chargement des fichiers
├── Core.lua           # bases de données, capture et restauration des profils, commande /profil
├── UI.lua             # fenêtre de gestion des profils et confirmations
└── Minimap.lua        # bouton de la minicarte
```

### Tests automatisés

`tests/wow_mock.lua` simule la partie de l'API WoW utilisée par l'addon : emplacements d'action, curseur, sorts, objets, jouets, montures, ensembles d'équipement, macros, raccourcis, combat, valeurs secrètes et frames factices. `tests/run.lua` charge l'addon dans l'ordre du TOC, déclenche `ADDON_LOADED` et vérifie les scénarios : capture, restauration, sorts introuvables, macros recréées, refus en combat, options de restauration, commandes, fenêtre et bouton de minicarte.

Ces tests valident **la logique**, pas l'API réelle. Le comportement exact des fonctions du client (par exemple ce que renvoie `GetActionInfo` pour une macro) doit être confirmé en jeu.

### Tester une modification

1. `./dev.sh check` puis `./dev.sh test` : les deux doivent se terminer sans erreur.
2. `./dev.sh deploy` : copie l'addon dans le jeu.
3. En jeu : `/reload`.
4. Les erreurs apparaissent dans BugSack. `/console scriptErrors 1` les affiche aussi directement.
5. Les données sauvegardées se trouvent dans `WTF\Account\<COMPTE>\SavedVariables\ProfilBarres.lua` (réglages communs) et `WTF\Account\<COMPTE>\<royaume>\<perso>\SavedVariables\ProfilBarres.lua` (profils du personnage).

### Intégration continue

À chaque push et à chaque pull request, GitHub Actions (`ci.yml`) construit l'image Docker puis lance `check`, `test` et un empaquetage de contrôle. Ce sont les mêmes commandes qu'en local.

### Publier une version

La version n'est **jamais écrite à la main** : le TOC du dépôt contient `## Version: @project-version@`, que l'empaquetage remplace par la version du tag.

1. Vérifier que `main` est prêt : la CI est verte, et le README et `todo.md` sont à jour.
2. Créer et pousser le tag :
   ```sh
   git tag v0.2.0
   git push origin v0.2.0
   ```
3. Le workflow `release.yml` relance `check` et `test`, construit `ProfilBarres-0.2.0.zip` et crée la release GitHub avec ce zip et des notes de version générées automatiquement à partir des commits.
4. Un tag avec suffixe (`v0.2.0-beta.1`) crée une **pré-version**. Elle n'apparaît pas comme « dernière version » sur le lien de téléchargement.

En cas d'échec, corriger, supprimer le tag (`git tag -d v0.2.0 && git push origin :refs/tags/v0.2.0`) puis recommencer.

Pour essayer un zip en local : `./dev.sh package v0.2.0`.

Plus tard, si l'addon doit aussi être publié sur CurseForge ou Wago, on pourra passer au packager BigWigs (v2.6.0 et plus), qui gère Forever et comprend déjà `@project-version@`.

## Ressources

- [Warcraft Wiki — API](https://warcraft.wiki.gg/wiki/World_of_Warcraft_API) et [format TOC](https://warcraft.wiki.gg/wiki/TOC_format)
- [ForeverMeta — addons et interface](https://forevermeta.me/en/guides/wow-forever-addons-interface)
- [Discussion sur le TOC et les bibliothèques pour Forever (bff-wow #3)](https://github.com/Shtian/bff-wow/issues/3)
- [Restrictions des addons sur Forever (Kami Labs)](https://kami-labs.fr/en/wow-classic/wow-forever-addons-restreints-comme-sur-midnight/)
