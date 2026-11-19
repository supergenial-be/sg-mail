# SG Mail

Super Génial Mail : client mail multi-boîtes et multi-utilisateurs pour les clients de Super Génial.

- [Note de cadrage](docs/cadrage.md)

## Lancer en local

Prérequis : Ruby 3.4.13 (`.ruby-version` et `.tool-versions` pour asdf), PostgreSQL.

```sh
bin/setup --skip-server
cp .env.example .env   # puis remplir GOOGLE_CLIENT_ID et GOOGLE_CLIENT_SECRET
bin/rails sg_mail:staff EMAIL=toi@exemple.be NAME="Ton nom"   # affiche un mot de passe
bin/dev                # http://localhost:3000, avec Solid Queue
```

`sg_mail:staff` crée un compte de l'équipe Super Génial (création des clients). Les boîtes importées
pendant la phase 0 se retrouvent dans un client « Compte initial », dont ce compte devient admin.

## Héberger sur Hatchbox

Une seule base Postgres : Solid Queue, Solid Cache et Solid Cable ont leurs tables dans la base principale.

1. **App** : créer l'app sur le serveur, branche `main`, puis attacher une base PostgreSQL
   (Hatchbox renseigne `DATABASE_URL`). Le rôle Postgres ne doit **pas** être superutilisateur,
   sinon la Row Level Security ne s'applique pas. Vérifier avec
   `bin/rails runner 'puts ActiveRecord::Base.connection.select_value("select rolsuper from pg_roles where rolname = current_user")'`
   (doit afficher `false`).
2. **Processus** (fichier `Procfile`) : `web` (Puma), `jobs` (`bin/jobs` : synchros, envois, relance
   toutes les 5 min) et `idle` (`bin/idle` : IMAP en temps réel).
3. **Variables d'environnement** :
   - `SECRET_KEY_BASE` (souvent déjà mis par Hatchbox, sinon `bin/rails secret`) ;
   - `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`, `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY`,
     `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` : générées une fois avec `bin/rails db:encryption:init`,
     à garder précieusement (sans elles, les jetons Google et mots de passe IMAP enregistrés sont illisibles) ;
   - `APP_HOST` (ex. `mail.supergenial.be`) ;
   - `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` ;
   - `MAILER_FROM`, `SMTP_ADDRESS`, `SMTP_PORT` (587), `SMTP_USERNAME`, `SMTP_PASSWORD` pour les invitations ;
   - facultatif : `GMAIL_PUBSUB_TOPIC`, `GMAIL_PUBSUB_TOKEN` (Gmail en temps réel, voir Synchros) ;
   - facultatif : `ANTHROPIC_API_KEY` (l'agent intégré, voir Agent).
4. **Google Cloud** : ajouter `https://<APP_HOST>/auth/google_oauth2/callback` aux URI de redirection
   autorisées du client OAuth.
5. **Premier compte**, une fois déployé : `bin/rails sg_mail:staff EMAIL=… NAME=…` dans la console Hatchbox.

Le déploiement lance `bin/rails db:prepare` ou `db:migrate` : les migrations s'appliquent seules. HTTPS est
obligatoire (`force_ssl`), ce qui convient au certificat géré par Hatchbox.

## Clients, membres et isolation

- **Client** (`Account`) : une organisation (Semisto, Silvéa…). Ses boîtes et ses emails lui appartiennent.
- **Membres** : rôle admin (invite, gère les rôles, déconnecte les boîtes) ou membre. Un utilisateur peut
  appartenir à plusieurs clients. Les adresses de l'app sont préfixées par l'id du client : `/12/mailboxes`.
- **Invitations** : envoyées par email (lien valable 14 jours, aussi visible dans la page Membres).
  L'équipe Super Génial crée un client et invite son premier admin, sans voir ses emails.
- **Isolation** (décision D3), deux verrous :
  - `acts_as_tenant` filtre `Mailbox`, `MailFolder` et `Message` sur le client courant, et refuse toute
    requête sans client ;
  - la Row Level Security de Postgres ne rend que les lignes du client fixé sur la connexion
    (`sg_mail.account_id`, voir `Tenancy`). Les tâches système qui traversent les clients passent par
    `Tenancy.across_accounts`.
  - Un superutilisateur Postgres échappe à la RLS : en production, l'app doit se connecter avec un rôle
    ordinaire (propriétaire des tables, sans `SUPERUSER` ni `BYPASSRLS`). Les tests vérifient la RLS
    avec un rôle ordinaire.
  - Les règles RLS vivent dans `db/structure.sql` (pas de `schema.rb` pour la base principale).
- **Passkeys** (cadrage §8) : menu « Passkeys » pour en ajouter une par appareil (Touch ID, Face ID, Windows Hello,
  clé de sécurité), puis « Se connecter avec une passkey » sur la page de connexion, sans adresse ni mot de passe.
  Gem `webauthn` ; l'identifiant de la partie de confiance est l'hôte de la requête. Le mot de passe reste possible.
- **Journal d'accès** (cadrage §4.2, `AccessLog`) : chaque ouverture d'un fil (interface, API/CLI, MCP) et chaque
  téléchargement de pièce jointe est noté, avec la personne et l'heure. Les admins le lisent depuis « Membres » →
  « Journal d'accès ». Effacé après un an (`PurgeAccessLogsJob`, chaque nuit).
- **Suppression complète d'un client** (cadrage §4.2) : réservée à l'équipe Super Génial, page « Clients », en
  retapant le nom du client. `Account#purge!` efface toutes les tables du client (`Account::OWNED_TABLES`) et
  révoque l'accès Google de ses boîtes Gmail. Déconnecter une boîte Gmail révoque aussi son accès Google.

## Boîtes et partage

- Une boîte connectée est **perso** : seule la personne qui l'a connectée la voit, même les admins du
  client ne la voient pas. Elle peut la **partager** (page « Partage » de la boîte) avec d'autres membres :
  lecture, lecture et envoi, ou gestion (partage et déconnexion). Il reste toujours au moins un gestionnaire.
- Quitter un client retire ses accès aux boîtes de ce client.
- **Signature et nom affiché**, par personne et par boîte (page de la boîte, « Quand j'écris depuis cette boîte ») :
  la signature se place sous les nouveaux messages, et entre la réponse et la citation ; le nom affiché remplace
  le nom de la personne dans « De » (ex. « Semisto Academy » pour formations@).

## Lecture

- **Réception** (page d'accueil d'un client) : les fils de toutes les boîtes accessibles qui ont un message
  dans INBOX ; filtre par boîte (tous ses fils) et « non lus seulement ».
- **Fils** (`Conversation`) : recalculés après chaque synchro (`Conversation.rebuild_for`), par threadId Gmail
  ou par en-têtes `References` en IMAP. Après la mise à jour, ils apparaissent à la synchro suivante.
- **Lu par…** (`Reading`) : chaque personne a son propre statut de lecture, affiché sous chaque message
  (« Lu par Michael · pas encore par Mohammad »). Le drapeau « lu » de Gmail ou du serveur IMAP n'est
  pas touché (D4). « Tout marquer comme lu » existe pour les vieux messages importés.
- **Pièces jointes** : listées à la synchro, téléchargées chez le fournisseur au moment du clic
  (toujours en téléchargement, jamais affichées sur le domaine de SG Mail). Pas encore de cache.

## Travail à plusieurs

- **Assignation** : chaque fil peut être confié à une personne qui a accès à la boîte
  (« Qui s'en occupe ? »). Filtre « Assignés à moi » dans la réception.
- **Notes internes** (`Note`) : sous le fil, visibles de l'équipe seulement, jamais envoyées.
  Seule l'autrice ou l'auteur peut supprimer sa note.

## L'esprit Hey (phase 2)

- **Screener** (« À trier ») : un expéditeur qui écrit pour la première fois n'entre pas dans la réception.
  Il attend dans « À trier » qu'on l'accepte (ses fils arrivent dans la réception) ou qu'on le bloque
  (ils restent dehors). Chaque personne décide pour elle seule (`Screening`, par personne et par adresse) ;
  rien n'est supprimé chez Gmail ou sur le serveur IMAP, et la recherche trouve toujours tout.
  Acceptés d'office : les expéditeurs déjà présents quand la personne a reçu l'accès à la boîte, et les
  personnes à qui la boîte a écrit (`Screening.accept_known_senders!`, après chaque synchro). Un fil retient
  l'expéditeur qui l'a ouvert (`conversations.sender_address`) ; un fil ouvert par la boîte n'est jamais trié.
- **Réception / Feed / Paper Trail** : on accepte un expéditeur dans une de ces trois piles (boutons du Screener),
  et on peut l'y déplacer plus tard depuis un de ses fils. Le Feed reçoit les lettres d'info et lectures,
  le Paper Trail les reçus, confirmations et notifications. Par personne aussi (`screenings.bucket`) ;
  un fil ouvert par la boîte va dans la réception. « Tout marquer comme lu » dans le Feed ou le Paper Trail
  ne touche que cette pile.
- **Répondre plus tard / Mis de côté** : deux piles personnelles (`ConversationState`, par personne et par fil).
  Boutons en haut d'un fil ; le fil quitte alors sa pile habituelle, et un lien « Répondre plus tard (n) » apparaît
  en haut de la réception. Envoyer une réponse depuis SG Mail sort le fil de « Répondre plus tard ».
- **Archiver** (cadrage §5 et §6) : « j'en ai fini », par personne (`conversation_states.archived_at`). Le fil
  quitte ma réception, mon Feed ou mon Paper Trail et « Répondre plus tard », et revient tout seul au prochain
  message. Lien « Voir mes fils archivés » sous la liste. Quand toutes les personnes qui ont accès à une boîte
  Gmail ont archivé un fil, `ProviderArchiveJob` retire aussi l'étiquette INBOX chez Gmail ; « Remettre dans la
  réception » la rend. En IMAP, rien n'est déplacé sur le serveur (SG Mail ne suit que INBOX et Envoyés).

## Aller vite

- **Actions groupées** : cases à cocher dans chaque liste, puis archiver, marquer lus ou non lus, « Répondre plus
  tard » ou « Mettre de côté » d'un coup (`conversations#bulk`, pour soi seulement).
- **Raccourcis clavier** (`shortcuts_controller.js`, aide avec `?`) : `j`/`k` pour se déplacer, `o` pour ouvrir,
  `x` pour cocher, `e` archiver, `l` répondre plus tard, `s` mettre de côté, `r`/`a`/`f` répondre, à tous,
  transférer, `u` revenir à la liste, `c` écrire, `/` rechercher, `g` puis `i`, `f`, `p`, `s`, `t`, `d` pour
  changer de page. Un élément déclare son raccourci avec `data-shortcut`.

## Recherche

Champ « Rechercher » en haut de chaque page (`/`) : les résultats s'affichent pendant la frappe (flèches pour
les parcourir, Entrée pour la page complète, qui se met aussi à jour en direct). Les mots cherchent dans
l'objet, l'expéditeur, les destinataires, le corps et les noms des pièces jointes des boîtes accessibles,
ainsi que dans les notes internes des fils. Sans accents et en début de mot (« inscri ete »
trouve « Inscription formation d'été ») ; `"bon de commande"` cherche l'expression exacte, `-mot` exclut.

Opérateurs, en anglais comme sur Gmail (`-` devant exclut, guillemets pour une valeur avec espaces) :

| Opérateur | Exemple |
| --- | --- |
| `from:` `to:` `cc:` `subject:` | `from:anne`, `subject:"devis jardin"` |
| `has:` `filename:` | `has:attachment`, `has:note`, `filename:pdf` |
| `before:` `after:` `older_than:` `newer_than:` | `after:2026/09/01`, `before:01/10/2026`, `newer_than:7d` (d, w, m, y) |
| `is:` `assignee:` | `is:unread`, `is:read`, `is:assigned`, `is:unassigned`, `assignee:me` |
| `in:` `mailbox:` | `in:inbox`, `in:feed`, `in:paper_trail`, `in:screener`, `in:reply_later`, `in:set_aside`, `in:archive`, `in:sent`, `in:formations` |

Les anciens filtres `de:`, `a:` et `avec:pj` restent compris. Un filtre non compris est signalé et ignoré.
Index plein texte Postgres (`messages.search_vector`, colonne calculée, extension `unaccent`) ; la logique
est dans `MessageSearch`, partagée par l'interface, l'API, le MCP et la CLI.

## API, MCP et CLI

Tout passe par `MailActions` : mêmes droits que dans l'interface, et un brouillon n'est jamais envoyé
sans action explicite.

- **Jetons personnels** : menu « Jetons d'API » (un jeton = une personne dans un client). Affiché une
  seule fois ; seule son empreinte SHA-256 est gardée. Il cesse de fonctionner si la personne quitte le client.
- **API JSON** `/api/v1` (en-tête `Authorization: Bearer sgm_…`) : `me`, `conversations` (`q`, `mailbox_id`,
  `unread`, `mine`, `before`), `conversations/:id` (+ `read`, `unread`, `notes`, PATCH `assignee_id`),
  `screener` (GET : en attente et bloqués ; POST `address`, `decision` accepted|blocked, `box`),
  `conversations?box=feed|paper_trail` pour les autres piles, `?stack=reply_later|set_aside` pour les piles
  personnelles (PATCH `conversations/:id` avec `reply_later`, `set_aside`, `archived` true|false ;
  `?archived=1` liste mes fils archivés),
  `drafts` (+ `deliver` pour envoyer).
- **MCP** `/mcp` (HTTP « streamable », sans état) : `whoami`, `search_conversations`, `get_conversation`,
  `mark_read`, `mark_unread`, `assign`, `add_note`, `list_screener`, `screen_sender`, `update_stacks`,
  `list_drafts`, `create_draft`, `update_draft`, `send_draft`.
  - **claude.ai** (connecteur personnalisé, adresse `https://<hôte>/mcp`) : serveur OAuth 2.1 intégré
    (`app/controllers/oauth/`) avec découverte (RFC 9728 et 8414), enregistrement dynamique (RFC 7591),
    PKCE S256, jeton d'accès d'une heure et rafraîchissement par rotation. À l'autorisation, la personne
    donne accès à tous ses clients (par défaut) ou à un seul ; les connecteurs se déconnectent depuis « Jetons d'API ».
    Avec plusieurs clients (`SgMailMcp::Accounts`), chaque outil s'exécute client par client avec l'isolation
    habituelle (RLS) : les listes rassemblent tous les clients et chaque élément porte son `account`,
    `account_id` restreint à un client.
  - **Claude Code**, avec un jeton personnel :

  ```sh
  claude mcp add --transport http sg-mail https://<hôte>/mcp --header "Authorization: Bearer sgm_…"
  ```

- **CLI** `sg-mail` (dossier `cli/`, gem Ruby avec Thor) :

  ```sh
  cd cli && gem build sg-mail.gemspec && gem install sg-mail-*.gem
  sg-mail login https://<hôte> sgm_…
  sg-mail inbox --unread          # ou : search, show 12 --read, note, assign
  sg-mail screener                # puis : accept zoe@example.org [--to feed|paper_trail], block spam@example.com
  sg-mail feed                    # ou : paper-trail, inbox --box feed
  sg-mail later 12                # ou : later (la pile), later 12 --off, aside 12, aside
  sg-mail archive 12              # ou : archive (mes fils archivés), archive 12 --off
  sg-mail reply 345 "Merci !"     # crée un brouillon, jamais envoyé
  sg-mail send 7                  # demande confirmation
  ```

  `--json` donne la réponse brute de l'API, pratique pour Claude Code.

## Agent

Chaque personne a son agent (prénom, couleur, style, consignes : Réglages → Agent → Personnaliser), le même dans
tous ses clients. Dans un fil, il résume, propose des actions et prépare brouillons et notes ; on lui parle
aussi en plein écran (« g a »). Note de conception : `cadrage/sg-mail-agent.md` dans les fichiers du projet.

- **Éteint par défaut** : un admin l'active client par client (Réglages → Agent), avec un plafond mensuel en dollars.
- **Lectures libres, écritures confirmées** : il appelle les mêmes outils que le MCP (`AgentToolbox`) ; tout ce qui
  change quelque chose s'affiche en carte « Confirmer / Refuser ». Il n'envoie jamais d'email (pas de `send_draft`).
- **Claude** : Sonnet 5.5 par l'API Anthropic (`ANTHROPIC_API_KEY`), boucle d'outils dans `AgentRun`, en tâche de
  fond (`AgentRunJob`) ; la page se rafraîchit à chaque étape (Turbo, Action Cable).
- Discussions privées, effacées après 90 jours sans activité ; les fils lus par l'agent vont au journal d'accès.
- **Outils connectés** (Réglages → Outils) : un admin déclare un outil du client par l'adresse de son serveur MCP
  (My Semisto, Claudy, l'admin d'un site…) ; chaque membre y connecte son propre compte (OAuth 2.1 avec inscription
  dynamique et PKCE, gérés par le client du gem `mcp`, retour sur `/integrations/callback`). Les jetons sont chiffrés
  dans `IntegrationConnection` et ne sortent jamais de SG Mail. L'agent voit leurs outils préfixés
  (`mysemisto__search`), en lecture libre si l'outil est marqué `readOnlyHint`, sinon avec confirmation (`RemoteMcp`).

## Synchros

- Les synchros tournent dans Solid Queue, hors du processus web : `bin/dev` lance Puma avec son
  superviseur Solid Queue (`SOLID_QUEUE_IN_PUMA`). On peut aussi lancer les jobs à part avec `bin/jobs`.
- **IMAP, temps réel** : `bin/idle` (ou `bin/rails sg_mail:idle`) garde une connexion IDLE par boîte IMAP
  et lance une synchro dès qu'un message arrive ou disparaît. `bin/dev` le lance aussi
  (`SKIP_IMAP_IDLE=1` pour s'en passer). En production, c'est le processus `idle` (voir Hatchbox).
- **Gmail, temps réel** : avec `GMAIL_PUBSUB_TOPIC` et `GMAIL_PUBSUB_TOKEN`, chaque synchro (re)lance
  `users.watch` (valable 7 jours) et Google prévient `/webhooks/gmail?token=…` à chaque changement.
  Réglage côté Google Cloud, une fois, quand l'app a une adresse publique :
  1. activer l'API Pub/Sub et créer le sujet (ex. `projects/<projet>/topics/sg-mail-gmail`) ;
  2. donner le rôle « Éditeur Pub/Sub » sur ce sujet à `gmail-api-push@system.gserviceaccount.com` ;
  3. créer un abonnement **push** vers `https://<hôte>/webhooks/gmail?token=<GMAIL_PUBSUB_TOKEN>`.
- `SyncAllMailboxesJob` relance toutes les boîtes toutes les 5 minutes (`config/recurring.yml`) :
  filet de sécurité si une notification se perd, et seule synchro Gmail en local (pas d'adresse publique).
- À la main : bouton « Synchroniser » sur une boîte, ou `bin/rails sg_mail:sync` / `sg_mail:watch`.
- `GMAIL_IMPORT_LIMIT` / `IMAP_IMPORT_LIMIT` limitent l'import initial pendant les essais.

## Phase 0 : preuve technique

Objectif : connecter une boîte Gmail (OAuth, API Gmail) et une boîte IMAP, importer puis synchroniser.
Terminée le 27 octobre 2026.

- **Gmail** : « Connecter une boîte Google », accepter l'écran « app non vérifiée » (Paramètres avancés → Continuer). L'import démarre tout de suite.
- **IMAP** : « Connecter une boîte IMAP », serveur + identifiants (mot de passe d'application si la validation en deux étapes est active).

### Comment ça marche

- `GmailSync` : import initial paginé et reprenable (`sync_state`), puis `history.list` à partir du dernier `historyId`. Réimport complet si l'historique a expiré. Lots de 25 messages, avec attente en cas de quota dépassé.
- `ImapSync` : INBOX + dossier Envoyés, reprise par UID, remise à zéro si `UIDVALIDITY` change, suppressions détectées. `EXAMINE` + `BODY.PEEK` : la synchro ne marque jamais un message comme lu.
- `MessageParser` : en-têtes, corps texte/HTML convertis en UTF-8, pièces jointes détectées.
- Jetons OAuth et mots de passe IMAP chiffrés (Active Record Encryption ; clés dérivées de `secret_key_base` en local).

### Tests

```sh
bin/rails test
# Test IMAP de bout en bout contre un vrai serveur (ex. Dovecot local) :
IMAP_TEST_HOST=127.0.0.1 IMAP_TEST_PORT=1143 IMAP_TEST_USER=… IMAP_TEST_PASSWORD=… IMAP_TEST_SSL=0 bin/rails test
```
