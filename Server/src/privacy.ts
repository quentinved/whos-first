/// The privacy policy, served as a page of its own.
///
/// App Store Connect needs a public URL for this, and there is no other server in this
/// project, so it lives here. French first: that is where most of the people reading it are.
///
/// Keep it true. Every claim below is a claim about the code, and the code moves. The game
/// itself has no networking of any kind — no analytics, no SDKs, no accounts, no ads. The
/// one exception is Game Center, which is Apple's and is optional. If that ever changes,
/// this page changes first.

const UPDATED = "14 September 2026";
const MISE_A_JOUR = "14 septembre 2026";
const CONTACT = "contact@quentinvedrenne.com";

export function privacyPage(): Response {
  return new Response(page, {
    headers: {
      "content-type": "text/html; charset=utf-8",
      // Crawled by Apple rather than read often. A day is plenty.
      "cache-control": "public, max-age=86400",
    },
  });
}

const style = `
  :root { color-scheme: light; }
  body { margin: 0; background: #FAFAF7; color: #17171F; font: 16px/1.6 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
  main { max-width: 42rem; margin: 0 auto; padding: 2.5rem 1.25rem 4rem; }
  h1 { font-size: 1.8rem; line-height: 1.2; margin: 0 0 .25rem; letter-spacing: -.02em; }
  h2 { font-size: 1.15rem; margin: 2.25rem 0 .5rem; color: #3F6B2C; }
  .sub { color: #5D5D68; margin: 0 0 2rem; }
  hr { border: 0; border-top: 1px solid #DEDED6; margin: 3.5rem 0; }
  a { color: #5B4BB8; }
  ul { padding-left: 1.15rem; }
  li { margin: .35rem 0; }
  .lang { display: inline-block; margin-bottom: 2rem; font-size: .9rem; }
`;

const french = `
<h1>Confidentialité — Who's First</h1>
<p class="sub">Dernière mise à jour : ${MISE_A_JOUR}</p>

<p>Who's First est une application développée par Quentin Vedrenne : chacun pose un doigt sur
l'écran, et l'application en désigne un au hasard ou répartit tout le monde en deux équipes.
Il n'y a pas de compte à créer, pas de mot de passe et pas d'adresse e-mail à donner.</p>

<h2>Ce que nous collectons</h2>
<p>Rien. Who's First ne collecte, ne transmet, ne vend et ne partage aucune donnée
personnelle ni aucune donnée d'usage. Il n'existe aucun moyen de vous identifier à travers
l'application.</p>

<h2>Aucun serveur de notre côté</h2>
<p>Nous n'avons aucun serveur et l'application ne nous envoie rien. Le jeu lui-même
fonctionne entièrement hors ligne, exactement de la même façon en mode avion. Elle n'embarque
aucune régie publicitaire, aucun outil de mesure d'audience, aucun rapporteur de plantage et
aucune bibliothèque tierce.</p>

<h2>Les succès Game Center</h2>
<p>L'application propose des succès via <strong>Game Center</strong>. C'est le service
d'Apple : si vous y êtes connecté, votre progression (par exemple « 10 manches terminées »)
est envoyée à Apple pour apparaître dans Game Center, et votre pseudo Game Center est celui
d'Apple. Ce traitement est celui d'Apple, décrit dans sa
<a href="https://www.apple.com/legal/privacy/">politique de confidentialité</a>. Nous ne
recevons rien et n'avons accès à aucune de ces données.</p>
<p>C'est entièrement facultatif. Refusez la connexion, ou restez déconnecté de Game Center,
et rien n'est envoyé : le jeu fonctionne exactement pareil et votre progression continue
d'être comptée sur votre appareil.</p>

<h2>Ce qui reste sur votre appareil</h2>
<p>L'application enregistre vos réglages en local, pour les retrouver au prochain lancement :</p>
<ul>
  <li>le thème choisi ;</li>
  <li>le son et les retours haptiques ;</li>
  <li>la durée du compte à rebours ;</li>
  <li>le mode de jeu, le nombre de gagnants et le nombre de joueurs ;</li>
  <li>le nombre de manches terminées, et de quoi suivre les succès : manches en équipes,
      défis distribués, plus grand nombre de doigts, thèmes déjà joués.</li>
</ul>
<p>Tout cela est stocké sur l'appareil uniquement, via le stockage local d'Apple. Rien n'est
transmis où que ce soit et nous n'y avons pas accès. Désinstaller l'application efface tout.</p>

<h2>Les doigts posés sur l'écran</h2>
<p>L'application lit la position des doigts posés sur l'écran pour dessiner un cercle sous
chacun et choisir entre eux. Ces positions n'existent qu'en mémoire, le temps de la manche,
et disparaissent aussitôt après. Elles ne sont ni enregistrées ni conservées.</p>
<p>L'application n'utilise ni Touch ID, ni Face ID, ni aucune donnée biométrique, et n'a
aucun accès à vos véritables empreintes digitales. L'empreinte du logo est décorative.</p>

<h2>Publicité et achats</h2>
<p>Il n'y en a pas. L'application est gratuite, sans publicité et sans achat intégré.</p>

<h2>Enfants</h2>
<p>L'application est classée 4+ et convient à tous les âges. Comme elle ne collecte aucune
donnée, elle n'en collecte pas davantage auprès des enfants. Elle ne contient ni publicité,
ni achat intégré, ni messagerie. Game Center est facultatif : un compte enfant sans Game
Center joue exactement au même jeu.</p>

<h2>Vos droits</h2>
<p>Aucune donnée personnelle n'étant collectée ni transmise, il n'y a rien à consulter, à
corriger ou à supprimer de notre côté : supprimer l'application supprime tout ce qui existe.
Pour toute question, écrivez à <strong>${CONTACT}</strong>. Vous pouvez également saisir la
CNIL.</p>

<h2>Modifications</h2>
<p>Si cette politique change, la date en haut de page change avec elle.</p>
`;

const english = `
<h1>Privacy — Who's First</h1>
<p class="sub">Last updated: ${UPDATED}</p>

<p>Who's First is an app made by Quentin Vedrenne: everyone puts a finger on the screen, and
the app picks one at random or splits everybody into two teams. There is no account to
create, no password and no email address to hand over.</p>

<h2>What we collect</h2>
<p>Nothing. Who's First does not collect, transmit, sell or share any personal information or
usage data. There is no way to identify you through the app.</p>

<h2>No server on our side</h2>
<p>We run no server and the app sends us nothing. The game itself works entirely offline,
exactly the same in airplane mode. It ships with no advertising network, no analytics, no
crash reporter and no third-party libraries.</p>

<h2>Game Center achievements</h2>
<p>The app offers achievements through <strong>Game Center</strong>. That is Apple's service:
if you are signed in, your progress (for example "10 rounds finished") is sent to Apple so it
can appear in Game Center, under your Game Center alias. That processing is Apple's, and is
described in its <a href="https://www.apple.com/legal/privacy/">privacy policy</a>. We
receive none of it and have no access to any of it.</p>
<p>It is entirely optional. Decline the sign-in prompt, or stay signed out of Game Center,
and nothing is sent: the game behaves exactly the same and your progress keeps being counted
on your device.</p>

<h2>What stays on your device</h2>
<p>The app saves your settings locally so it can remember them next time you open it:</p>
<ul>
  <li>your chosen theme;</li>
  <li>sound and haptics;</li>
  <li>countdown length;</li>
  <li>game mode, number of winners and number of players;</li>
  <li>how many rounds you have finished, and what the achievements need: team rounds,
      challenges handed out, the largest number of fingers, and which themes you have played.</li>
</ul>
<p>This is kept on your device only, using Apple's standard local storage. It is never
transmitted anywhere and we have no access to it. Deleting the app deletes all of it.</p>

<h2>Fingers on the screen</h2>
<p>The app reads the position of fingers touching the screen in order to draw a ring under
each one and pick between them. Those positions exist only in memory for the length of a
round and are discarded immediately afterwards. They are never recorded or stored.</p>
<p>The app does not use Touch ID, Face ID or any biometric data, and has no access to your
actual fingerprints. The fingerprint in the artwork is decorative.</p>

<h2>Advertising and purchases</h2>
<p>There are none. The app is free, with no ads and no in-app purchases.</p>

<h2>Children</h2>
<p>The app is rated 4+ and is safe for all ages. Because it collects no data at all, it
collects no data from children either. It contains no advertising, no in-app purchases and no
chat. Game Center is optional, and a child account without it plays exactly the same game.</p>

<h2>Your rights</h2>
<p>Since no personal data is collected or transmitted, there is nothing for us to give you
access to, correct or delete: removing the app removes everything that exists. For any
question, write to <strong>${CONTACT}</strong>. You may also complain to your data protection
authority — in France, the CNIL.</p>

<h2>Changes</h2>
<p>If this policy changes, the date at the top changes with it.</p>
`;

const page = `<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Confidentialité · Who's First</title>
<style>${style}</style>
</head>
<body>
<main>
<p class="lang"><a href="#en">Read in English ↓</a></p>
${french}
<hr>
<div id="en" lang="en">${english}</div>
</main>
</body>
</html>`;
