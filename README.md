# ProfilBarres — profils de barres d'action pour WoW: Forever

Addon pour **World of Warcraft: Forever** qui permet d'enregistrer plusieurs **profils de barres d'action** et de passer de l'un à l'autre en un clic.

> Statut : **en conception**. Le code n'est pas encore écrit.

## Fonctionnalités prévues

- **Bouton sur la minicarte** « Profil » qui ouvre et ferme la fenêtre de l'addon. Il est déplaçable autour de la minicarte et sa position est mémorisée. L'addon est aussi accessible depuis le menu des addons (Addon Compartment) et par la commande `/profil`.
- **Fenêtre de gestion des profils** :
  - créer un profil à partir de l'état actuel des barres, en lui donnant un nom ;
  - lister les profils enregistrés, avec le personnage, la classe, le nombre d'actions et de raccourcis et la date de mise à jour ;
  - **charger**, **écraser** ou **supprimer** un profil, avec une confirmation.
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

1. Télécharger ou copier le dossier `ProfilBarres/`.
2. Le placer dans le dossier des addons **de Forever** (et non dans celui de Retail ou de Classic) :
   - bêta : `World of Warcraft\_classic_beta_\Interface\AddOns\ProfilBarres\`
   - lancement : `World of Warcraft\_forever_\Interface\AddOns\ProfilBarres\` (nom du dossier non confirmé ; on le trouve via Battle.net > roue dentée > *Afficher dans l'explorateur*)
3. Relancer le jeu ou taper `/reload`.
4. Si l'addon n'apparaît pas, cocher *Charger les addons périmés* dans la liste des addons.

## Utilisation (prévue)

| Action | Comment |
|---|---|
| Ouvrir ou fermer la fenêtre | Clic sur le bouton de la minicarte, ou `/profil` |
| Déplacer le bouton | Glisser-déposer autour de la minicarte |
| Enregistrer un profil | Saisir un nom, puis *Enregistrer* (ou Entrée) |
| Charger un profil | *Charger*, puis confirmer |
| Mettre à jour un profil | *Écraser* : remplace le contenu par l'état actuel |
| Supprimer un profil | *X*, puis confirmer |
| Masquer ou afficher le bouton | `/profil minimap` |

Deux cases à cocher permettent de choisir ce qui est restauré : **les actions**, **les raccourcis**, ou les deux.

## Limitations connues

- **Pas de chargement en combat** : poser des actions, créer des macros et modifier des raccourcis sont des opérations protégées par le jeu.
- **Les barres dépendent de la spécialisation** : un profil capture les barres de la spécialisation active au moment de l'enregistrement.
- **Profils partagés entre personnages** : un profil créé avec une autre classe peut être chargé, mais les sorts inconnus seront retirés des barres. Une alerte s'affiche avant le chargement.
- **Macros** : elles sont retrouvées par leur nom. Si une macro n'existe plus, l'addon tente de la recréer à partir du texte sauvegardé, à condition qu'il reste de la place.
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

L'image `profilbarres-tools` (Debian, voir `docker/Dockerfile`) contient Lua 5.1, luacheck, zip et rsync. Toutes les commandes passent par `./dev.sh` :

| Commande | Effet |
|---|---|
| `./dev.sh build` | Construit l'image (à refaire seulement si `docker/Dockerfile` change) |
| `./dev.sh check` | Vérifie la syntaxe Lua 5.1 (`luac5.1 -p`), puis lance `luacheck` (configuré par `.luacheckrc`) |
| `./dev.sh package` | Crée `.release/ProfilBarres-<version>.zip`, avec la version lue dans le TOC |
| `./dev.sh deploy` | Copie `ProfilBarres/` dans le dossier AddOns du jeu |
| `./dev.sh shell` | Ouvre un shell dans le conteneur |

Configuration du déploiement : copier `.env.example` en `.env` (fichier ignoré par git), puis renseigner `WOW_ADDONS_DIR` avec le chemin du dossier AddOns vu depuis WSL, par exemple :

```
WOW_ADDONS_DIR=/mnt/c/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns
```

`.luacheckrc` contient la liste des globaux WoW autorisés. Si luacheck signale une fonction WoW légitime comme inconnue (`W113`), il faut l'ajouter dans `read_globals`.

### Structure

```
compose.yaml           # services Docker : tools (vérification, packaging) et deploy
dev.sh                 # point d'entrée des commandes de développement
docker/Dockerfile      # image des outils
scripts/               # check.sh, package.sh, deploy.sh (exécutés dans le conteneur)
.luacheckrc            # configuration de luacheck (globaux WoW)
.env.example           # modèle de configuration locale (WOW_ADDONS_DIR)
ProfilBarres/          # l'addon (à venir)
```

Fichiers prévus pour l'addon :

```
ProfilBarres/
├── ProfilBarres.toc   # métadonnées et ordre de chargement des fichiers
├── Core.lua           # base de données, capture et restauration des profils, commande /profil
├── UI.lua             # fenêtre de gestion des profils et confirmations
└── Minimap.lua        # bouton de la minicarte
```

### Tester une modification

1. `./dev.sh check` : il doit se terminer sans erreur ni avertissement.
2. `./dev.sh deploy` : copie l'addon dans le jeu.
3. En jeu : `/reload`.
4. Les erreurs apparaissent dans BugSack. `/console scriptErrors 1` les affiche aussi directement.
5. Les données sauvegardées se trouvent dans `WTF\Account\<COMPTE>\SavedVariables\ProfilBarres.lua`.

### Publication

- `./dev.sh package` produit l'archive zip, avec le dossier `ProfilBarres/` à sa racine.
- CurseForge propose une catégorie WoW Forever. Le packager BigWigs (v2.6.0 et plus) détecte automatiquement les interfaces `16xxx`.

## Ressources

- [Warcraft Wiki — API](https://warcraft.wiki.gg/wiki/World_of_Warcraft_API) et [format TOC](https://warcraft.wiki.gg/wiki/TOC_format)
- [ForeverMeta — addons et interface](https://forevermeta.me/en/guides/wow-forever-addons-interface)
- [Discussion sur le TOC et les bibliothèques pour Forever (bff-wow #3)](https://github.com/Shtian/bff-wow/issues/3)
- [Restrictions des addons sur Forever (Kami Labs)](https://kami-labs.fr/en/wow-classic/wow-forever-addons-restreints-comme-sur-midnight/)
