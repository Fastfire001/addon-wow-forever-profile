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

- Le client WoW: Forever installé.
- Un éditeur avec la prise en charge de Lua 5.1. Recommandé : l'extension VS Code *WoW API* (Ketho) ou EmmyLua pour JetBrains.
- Addons utiles pour le test : **BugSack** et **BugGrabber** (capture des erreurs Lua).
- Optionnel : `luac5.1` ou `luacheck` pour vérifier la syntaxe hors du jeu.

### Structure prévue

```
ProfilBarres/
├── ProfilBarres.toc   # métadonnées et ordre de chargement des fichiers
├── Core.lua           # base de données, capture et restauration des profils, commande /profil
├── UI.lua             # fenêtre de gestion des profils et confirmations
└── Minimap.lua        # bouton de la minicarte
```

### Tester une modification

1. Créer un lien entre le dossier de l'addon dans le dépôt et le dossier AddOns du jeu, pour éviter de copier à chaque fois. Depuis Windows, dans un terminal administrateur :
   ```bat
   mklink /J "C:\...\World of Warcraft\_forever_\Interface\AddOns\ProfilBarres" "\\wsl$\<distro>\home\<user>\src\addon-wow-forever-profile\ProfilBarres"
   ```
   Si la jonction vers WSL ne fonctionne pas, copier le dossier à la main.
2. En jeu : `/reload` après chaque modification.
3. Les erreurs apparaissent dans BugSack. `/console scriptErrors 1` les affiche aussi directement.
4. Les données sauvegardées se trouvent dans `WTF\Account\<COMPTE>\SavedVariables\ProfilBarres.lua`.

### Publication

- Archive zip contenant le dossier `ProfilBarres/` à sa racine.
- CurseForge propose une catégorie WoW Forever. Le packager BigWigs (v2.6.0 et plus) détecte automatiquement les interfaces `16xxx`.

## Ressources

- [Warcraft Wiki — API](https://warcraft.wiki.gg/wiki/World_of_Warcraft_API) et [format TOC](https://warcraft.wiki.gg/wiki/TOC_format)
- [ForeverMeta — addons et interface](https://forevermeta.me/en/guides/wow-forever-addons-interface)
- [Discussion sur le TOC et les bibliothèques pour Forever (bff-wow #3)](https://github.com/Shtian/bff-wow/issues/3)
- [Restrictions des addons sur Forever (Kami Labs)](https://kami-labs.fr/en/wow-classic/wow-forever-addons-restreints-comme-sur-midnight/)
