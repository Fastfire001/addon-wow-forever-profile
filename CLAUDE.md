# CLAUDE.md

Guide pour Claude Code sur ce dépôt.

## Projet

**ProfilBarres** est un addon WoW pour **World of Warcraft: Forever**. Le joueur enregistre plusieurs profils de barres d'action, puis les recharge :
- un bouton sur la minicarte (aussi accessible par l'Addon Compartment et `/profil`) ouvre une fenêtre ;
- cette fenêtre permet de créer, lister, charger, écraser et supprimer des profils nommés ;
- un profil contient, pour **chaque emplacement d'action** (1 à 180), le sort, la macro, l'objet, la monture ou l'ensemble d'équipement qui s'y trouve, ainsi que les **raccourcis clavier** liés à chaque emplacement.

Le README.md décrit les fonctionnalités et les limitations côté utilisateur. Il doit être tenu à jour quand le comportement change.

## Méthode de travail

- **Avancer par étapes validées** : ne pas commencer à coder une fonctionnalité sans l'accord explicite de l'utilisateur. Proposer d'abord, puis implémenter.
- L'utilisateur s'exprime en **français**. Les réponses, les textes visibles en jeu et les commentaires de code sont en français. Les identifiants de code sont en anglais.
- Pas de commit ni de push sans demande explicite.

## Plateforme : WoW: Forever

Ce qui suit vient de sources communautaires de la bêta (novembre 2026). En cas de doute, revérifier sur [warcraft.wiki.gg](https://warcraft.wiki.gg).

- **Le client est Mainline (Midnight), pas Classic.** L'API correspond à la 12.1.x : `C_Spell`, `C_Item`, `C_MountJournal`, `C_EquipmentSet`, `C_ChatInfo`, etc. Il ne faut pas reprendre de code ou de documentation propre à Classic Era.
- **TOC** :
  - `## Interface: 16001` ;
  - le type de jeu interne est `camelot` ;
  - le client accepte les suffixes `_Forever.toc` et `_Camelot.toc`, mais le packager BigWigs ne reconnaît que `_Camelot`. Utiliser un **TOC unique sans suffixe**.
- **Détection de la version** : `WOW_PROJECT_ID == WOW_PROJECT_CAMELOT` (18) sur les builds récents, mais il valait `1` sur d'anciens builds. Ne jamais brancher uniquement sur cette valeur. Préférer tester l'existence de la fonction (`if C_Spell and C_Spell.PickupSpell then ...`).
- **Fonctions globales dépréciées** : `GetSpellInfo`, `GetItemInfo`, `PickupSpell` et `PickupItem` peuvent être absentes. Utiliser `C_Spell.GetSpellName`, `C_Spell.PickupSpell`, `C_Item.GetItemNameByID` et `C_Item.PickupItem`, avec repli si besoin.
- **Restrictions Midnight** :
  - **valeurs secrètes** en combat : on ne peut ni les comparer ni calculer avec. Les tester avec `issecretvalue(v)` avant tout usage ;
  - `COMBAT_LOG_EVENT_UNFILTERED` n'est pas accessible ;
  - les messages entre addons sont bloqués en instance (`C_ChatInfo.InChatMessagingLockdown()`) ;
  - les GUID sont brouillés.
- **Pas de royaumes** : les noms de personnage sont uniques par région, avec des noms de famille. Ne pas identifier un personnage par `Nom-Royaume`.
- **Dossier des addons** : `_classic_beta_\Interface\AddOns` en bêta. Le nom du dossier au lancement n'est pas confirmé (probablement `_forever_`).

## Contraintes Lua et WoW

- **Lua 5.1** : pas de `goto`, pas d'opérateur `//`, pas d'opérateurs binaires natifs (utiliser `bit.band`, etc.), pas de `_ENV`, `require`, `io` ni `os`. L'ordre de chargement des fichiers est défini dans le TOC.
- **Espace de noms** : chaque fichier commence par `local ADDON, ns = ...`. Tout passe par `ns`. Les seuls globaux autorisés sont les variables sauvegardées `ProfilBarresDB` (compte) et `ProfilBarresCharDB` (personnage), les noms des frames, `SLASH_PROFILBARRES1` / `SlashCmdList.PROFILBARRES` et `ProfilBarres_OnAddonCompartmentClick`.
- **Initialisation** : lire et initialiser `ProfilBarresDB` et `ProfilBarresCharDB` dans `ADDON_LOADED` (filtrer sur `name == ADDON`), jamais au chargement du fichier.
- **Combat (taint et protection)** : `PlaceAction`, `PickupAction`, `CreateMacro`, `SetBinding` et `SaveBindings` doivent être refusés si `InCombatLockdown()` est vrai. Afficher alors un message à l'utilisateur au lieu d'échouer.
- **UI** : frames Blizzard standard (`BasicFrameTemplateWithInset`, `UIPanelButtonTemplate`, `InputBoxTemplate`, `UICheckButtonTemplate`, `UIPanelScrollFrameTemplate`) et `StaticPopupDialogs` pour les confirmations. Fermeture par Échap via `UISpecialFrames`. Aucune bibliothèque externe tant qu'elle n'est pas nécessaire : le bouton de minicarte est codé à la main, sans LibDBIcon.
- Préfixe des messages dans le chat : `|cff33ff99Profil|r :`.

## Notes techniques sur le domaine

- **Lecture d'un emplacement** : `HasAction(slot)`, puis `GetActionInfo(slot)`, qui renvoie `actionType, id, subType`. Types à gérer : `spell`, `macro`, `item`, `summonmount`, `equipmentset`. Les autres types (`flyout`, etc.) sont marqués comme non pris en charge et l'emplacement n'est pas modifié lors de la restauration.
- **Macros** : identifier la macro par son nom avec `GetActionText(slot)`, puis `GetMacroIndexByName`. Ne pas se fier à l'`id` renvoyé par `GetActionInfo`, qui peut valoir un spellID selon la version. Sauvegarder le nom, l'icône, le texte et s'il s'agit d'une macro de personnage (index > `MAX_ACCOUNT_MACROS`) pour pouvoir la recréer.
- **Poser une action** : `ClearCursor()`, puis prendre l'élément (`C_Spell.PickupSpell`, `PickupMacro`, `C_Item.PickupItem`, ...), vérifier `GetCursorInfo()`, puis `PlaceAction(slot)` et `ClearCursor()`. Pour vider un emplacement : `PickupAction(slot)` puis `ClearCursor()`. Ne pas toucher aux emplacements déjà identiques au profil.
- **Raccourcis** : liste de commandes `ACTIONBUTTON1-12`, `MULTIACTIONBAR1..7BUTTON1-12`, `SHAPESHIFTBUTTON1-10`, `BONUSACTIONBUTTON1-10`. Capture avec `GetBindingKey(cmd)` (plusieurs touches possibles). Restauration en trois temps : délier les touches actuelles de ces commandes (`SetBinding(key)`), lier celles du profil (`SetBinding(key, cmd)`), puis `SaveBindings(GetCurrentBindingSet())`.
- **Correspondance emplacements et barres** (Mainline) : 1-12 barre principale, 13-24 page 2, 25-36 barre droite (MULTIACTIONBAR3), 37-48 barre gauche (MULTIACTIONBAR4), 49-60 barre en bas à droite (MULTIACTIONBAR2), 61-72 barre en bas à gauche (MULTIACTIONBAR1), 73-120 barres de posture et de forme, 121-144 barres spéciales, 145-180 barres 5 à 7 (MULTIACTIONBAR5-7).

## Format des données

Les **profils sont propres à chaque personnage**, ils ne sont jamais partagés. Ils sont stockés dans une variable `SavedVariablesPerCharacter`. Seuls les réglages d'interface sont communs au compte.

```lua
-- ## SavedVariables : réglages communs au compte
ProfilBarresDB = {
  version = 1,
  minimap = { angle = 225, hide = false },
  options = { actions = true, bindings = true },
}

-- ## SavedVariablesPerCharacter : profils de ce personnage
ProfilBarresCharDB = {
  version  = 1,
  profiles = {
    ["Nom"] = {
      name = "Nom", created = <time()>, updated = <time()>,
      spec = "Givre",
      actions  = { [slot] = { type = "spell", id = 116, name = "Éclair de givre" }, ... },
      bindings = { ["ACTIONBUTTON1"] = { "1" }, ... },
    },
  },
}
```

## Outillage : tout passe par Docker

- **Ne rien installer sur la machine hôte** (ni apt, ni luarocks, ni npm). Tout outil nécessaire s'ajoute dans `docker/Dockerfile`, puis on lance `./dev.sh build`.
- Tout l'outillage fonctionne dans Docker. Si `docker` est indisponible, demander à l'utilisateur de le démarrer.
- Commandes :
  - `./dev.sh check` : `luac5.1 -p` puis `luacheck`. **À lancer après chaque modification de Lua.**
  - `./dev.sh test` : tests de la logique contre l'API simulée (`tests/wow_mock.lua`, `tests/run.lua`).
  - `./dev.sh package [version]` : archive zip (version par défaut : `dev`).
  - `./dev.sh deploy` : copie l'addon vers `WOW_ADDONS_DIR` défini dans `.env`.
  - `./dev.sh shell` : shell dans le conteneur.
- Les conteneurs tournent avec l'UID et le GID de l'hôte, pour que les fichiers créés n'appartiennent pas à root.
- Quand l'addon utilise une nouvelle fonction de l'API WoW, l'ajouter dans `read_globals` de `.luacheckrc`. Un nouveau global écrit par l'addon va dans `globals`.

## Vérification

- Avant de rendre la main, `./dev.sh check` (zéro avertissement) et `./dev.sh test` (zéro échec) doivent passer.
- **Tests sur l'API simulée** : `tests/wow_mock.lua` reproduit uniquement ce que l'addon utilise. Toute nouvelle fonction WoW appelée par l'addon doit y être ajoutée, et chaque nouveau comportement doit avoir un scénario dans `tests/run.lua`. La simulation valide la logique, pas l'API réelle : ne jamais présenter un test réussi comme une preuve que cela marche en jeu.
- Points dont le comportement réel n'est **pas confirmé** et que le mock suppose (à vérifier en jeu, puis corriger le mock si besoin) :
  - `GetActionText(slot)` renvoie le nom de la macro ;
  - `C_Spell.PickupSpell(spellID)` d'une monture permet de la poser ;
  - `C_Item.PickupItem` ne prend pas un objet absent des sacs ;
  - `SetBinding(key)` sans commande délie la touche ;
  - `frame.TitleText` existe sur `BasicFrameTemplateWithInset`, et `check.Text` sur `UICheckButtonTemplate`. Il y a un repli dans les deux cas ;
  - le champ de saisie d'un `StaticPopup` avec `hasEditBox` est accessible par `popup:GetEditBox()`, `popup.editBox` ou `popup.EditBox` (repli dans `GetPopupEditBox`), et `EditBoxOnEnterPressed` reçoit bien l'EditBox, dont le parent est le popup.

## Distribution (GitHub)

- Le dépôt public `Fastfire001/addon-wow-forever-profile` est la source de téléchargement des joueurs, via les **releases GitHub**.
- **Version** : le TOC du dépôt garde `## Version: @project-version@`. **Ne jamais y écrire de numéro.** `scripts/package.sh` le remplace dans l'archive, puis vérifie le résultat.
- `ci.yml` lance build, check, test et un empaquetage de contrôle à chaque push et pull request. `release.yml` publie la release quand un tag `vX.Y.Z` est poussé ; un tag avec suffixe `-...` crée une pré-version.
- Les workflows se vérifient en local avec actionlint, via Docker : `docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:1.7.7 -no-color`.
- Ne jamais créer ni pousser de tag sans demande explicite : cela publie une version auprès des joueurs.
- **Préserver les données des joueurs** entre les versions :
  - ne jamais renommer l'addon (dossier, TOC) ni ses variables sauvegardées ;
  - ne jamais retirer les lignes `SavedVariables` du TOC ;
  - prévoir une conversion des données à chaque changement de format.

## Suivi

`todo.md` contient les fonctionnalités validées mais reportées, ainsi que celles qui ont été abandonnées. Ne pas les commencer sans feu vert, et mettre le fichier à jour quand une décision change.
- Test en jeu : `/reload`, BugSack ou `/console scriptErrors 1`, puis vérifier les fichiers `WTF\Account\<COMPTE>\SavedVariables\ProfilBarres.lua` (réglages) et `WTF\Account\<COMPTE>\<royaume>\<perso>\SavedVariables\ProfilBarres.lua` (profils).
- Toujours tester : enregistrement, chargement, chargement avec un sort non appris, macro supprimée puis recréée, tentative de chargement en combat (doit être refusée).
