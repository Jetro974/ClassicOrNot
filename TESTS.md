# À vérifier en jeu — Classic or Not 0.1.0

Installer : `powershell -ExecutionPolicy Bypass -File C:\Dev\Addons\ClassicOrNot\deploy.ps1`, puis **redémarrer le jeu** (nouvel addon). BugSack allumé.

**Sans EllesmereUI** (le désactiver le temps du test) :
1. Échap > Options > AddOns > « Classic or Not » : 3 titres (Quêtes, Recettes, Objets et collections) et 8 cases, toutes cochées ; pas de case « Dans le suivi des quêtes ». `/classicornot` et le bouton de l'addon (compartiment de la minicarte) ouvrent cette page.
2. **Quêtes** : un donneur de quêtes de Forever (liste de dialogue, liste d'accueil, texte de la quête avant d'accepter) montre l'infini bleu après le titre d'une quête nouvelle, rien sur une quête d'origine ; journal de quêtes : l'infini sous la case de suivi d'une quête nouvelle. Décocher puis recocher : les marques partent et reviennent sans /reload.
3. **Recettes** : fenêtre de métier (après le nom et le compteur) et maître de métier (coin de l'icône) : une recette nouvelle marquée, une d'origine non. Changer un talent de métier : les marques suivent les compteurs.
4. **Objets** : infobulle d'un objet nouveau (dans les sacs, chez un marchand, un lien dans le chat) : ligne « ∞ Nouveau dans Forever » ; un objet d'origine (Agrandisseur de monde 18660, Snowmaster 9000 17716) : rien. En combat : pas d'erreur.
5. **Montures** : journal des montures : l'infini en haut à droite des Galestrider, du Venomhide Ravasaur ; rien sur le Cheval bai (Brown Horse) ni la Tortue de monte. Défiler, filtrer : les marques suivent les bonnes lignes.
6. **Mascottes** : journal des mascottes : marque sur les nouvelles (Sinister Squashling, Lanternes, le nouveau Panda), rien sur l'Écureuil mécanique ni les chats. Défiler, filtrer.
7. **Jouets** : coffre à jouets : marque en haut à droite de l'icône, à la même place pour tous les jouets quelle que soit la longueur du nom, sans cacher l'étoile des favoris ni « NOUVEAU » (à gauche), sur la Bannière centaure, la Tente d'aventurier ; rien sur l'Agrandisseur de monde ; changer de page : les marques suivent. Le clic sur un jouet marche toujours (aucune erreur « action bloquée »).
8. Ouvrir le journal des collections la première fois APRÈS la connexion (addon chargé à la demande) : les marques sont là dès la première ouverture.

**Avec EllesmereUI** :
9. Le panneau EUI a une section « Classic or Not » en bas, ligne « What's New in Forever » (en français : « Les nouveautés de Forever »), une page « Général » avec les 3 titres en capitales et les cases deux par ligne, comme les pages d'EUI, plus « Dans le suivi des quêtes ». Aucune fenêtre « addon à mettre à jour » d'EUI. `/classicornot` ouvre cette page. La recherche d'EUI trouve « montures ».
10. Suivi de quêtes personnalisé d'EUI : l'infini à droite du titre des quêtes nouvelles. Décocher « Dans le suivi des quêtes » : les marques partent (la place gardée à droite du titre reste jusqu'au prochain /reload, normal).
11. Pas de page en double dans Options > AddOns.

Noté : ______ (date, build, ce qui ne va pas).
