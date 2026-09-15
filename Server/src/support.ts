/// The support page, served as a page of its own.
///
/// App Store Connect requires a support URL, and it has to be a page someone can actually
/// get help from rather than a policy. It lives here beside the privacy policy. French
/// first, English below, same as the policy.
///
/// Keep it true. Every answer below is an answer about the code, and the code moves.

const CONTACT = "contact@quentinvedrenne.com";
const PRIVACY = "/privacy";

export function supportPage(): Response {
  return new Response(page, {
    headers: {
      "content-type": "text/html; charset=utf-8",
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
  ol, ul { padding-left: 1.15rem; }
  li { margin: .35rem 0; }
  .mail { display: inline-block; margin: .5rem 0 0; font-weight: 600; }
  .lang { display: inline-block; margin-bottom: 2rem; font-size: .9rem; }
`;

const french = `
<h1>Aide — Who's First</h1>
<p class="sub">Une question, un bug, une idée : écrivez, on répond.</p>

<p class="mail"><a href="mailto:${CONTACT}">${CONTACT}</a></p>
<p>Dites quel iPhone ou iPad vous avez et ce que vous faisiez au moment du problème. C'est
presque toujours suffisant pour le reproduire.</p>

<h2>Comment on joue</h2>
<ol>
  <li>Ouvrez l'application : il n'y a rien à configurer.</li>
  <li>Chacun pose <strong>un doigt</strong> sur l'écran et ne bouge plus.</li>
  <li>À partir de deux doigts, le compte à rebours démarre tout seul.</li>
  <li>Un doigt s'allume. C'est la réponse.</li>
</ol>

<h2>Rien ne se passe quand je touche l'écran</h2>
<p>Il faut au moins deux doigts. Avec un seul, l'application affiche « Waiting for players »
et attend. Si vous êtes seul, ouvrez les options en haut à droite et touchez
<em>Try a round</em> pour voir une manche complète avec des joueurs virtuels.</p>

<h2>Le compte à rebours repart sans arrêt</h2>
<p>C'est voulu : il repart dès que quelqu'un arrive ou retire son doigt, pour que personne ne
se glisse au dernier moment. Tout le monde garde le doigt posé jusqu'au résultat.</p>

<h2>Peut-on désigner plusieurs personnes ?</h2>
<p>Oui. Dans les options, réglez <strong>Winners</strong> entre 1 et 9. Il faut au moins un
joueur de plus que le nombre choisi.</p>

<h2>Comment marchent les équipes ?</h2>
<p>Passez en mode <strong>Teams</strong> dans les options. Tout le monde est réparti en deux
groupes équilibrés : à six on obtient 3 contre 3, à cinq 3 contre 2. <em>Shuffle teams</em>
retire au sort.</p>

<h2>C'est vraiment aléatoire ?</h2>
<p>Oui. Chaque doigt a exactement la même chance à chaque manche. Le halo qui court d'un
doigt à l'autre pendant le compte à rebours n'est là que pour le suspense : le tirage se fait
indépendamment et n'est pas influencé par l'animation. Les équipes sont mélangées
correctement et toujours équilibrées.</p>

<h2>Combien de doigts au maximum ?</h2>
<p>Jusqu'à dix, selon ce que votre appareil accepte en multi-touch.</p>

<h2>Il n'y a pas de son</h2>
<p>Vérifiez que <strong>Music &amp; sound</strong> est activé dans les options. L'application
respecte aussi le bouton silencieux et se mélange poliment à la musique déjà en cours.</p>

<h2>Peut-on couper les vibrations ?</h2>
<p>Oui, désactivez <strong>Haptics</strong> dans les options.</p>

<h2>Pourquoi l'écran ne tourne pas sur iPhone ?</h2>
<p>C'est volontaire : si le plateau tournait pendant que les doigts sont posés, tous les
doigts se déplaceraient. L'iPad, souvent posé à plat sur une table, accepte toutes les
orientations.</p>

<h2>Les succès</h2>
<p>L'application propose huit succès Game Center, gagnés en jouant de vraies manches :
première manche, 10, 50 et 250 manches, une manche en équipes, dix doigts d'un coup, dix
défis distribués, et une manche dans chacun des six thèmes. Les manches d'essai
(<em>Try a round</em>) ne comptent jamais.</p>
<p>Il faut être connecté à Game Center (<em>Réglages iOS → Game Center</em>). Si vous
refusez, le jeu fonctionne exactement pareil : votre progression continue d'être comptée sur
l'appareil et sera envoyée le jour où vous vous connecterez.</p>

<h2>Faut-il une connexion internet ?</h2>
<p>Non pour jouer : le jeu fonctionne entièrement hors ligne. Seuls les succès Game Center
ont besoin d'une connexion, et ils sont facultatifs.</p>

<h2>Quelles données sont collectées ?</h2>
<p>Aucune. Vos réglages sont enregistrés sur votre appareil et nulle part ailleurs. Voir la
<a href="${PRIVACY}">politique de confidentialité</a>.</p>

<h2>Configuration requise</h2>
<p>iPhone ou iPad sous iOS 17 ou version ultérieure.</p>
`;

const english = `
<h1>Support — Who's First</h1>
<p class="sub">A question, a bug, an idea: write in and you'll get an answer.</p>

<p class="mail"><a href="mailto:${CONTACT}">${CONTACT}</a></p>
<p>Say which iPhone or iPad you have and what you were doing when it went wrong. That is
almost always enough to reproduce it.</p>

<h2>How to play</h2>
<ol>
  <li>Open the app — there is nothing to set up.</li>
  <li>Everyone puts <strong>one finger</strong> on the screen and holds still.</li>
  <li>With two or more fingers down, a countdown starts on its own.</li>
  <li>One finger lights up. That's your answer.</li>
</ol>

<h2>Nothing happens when I touch the screen</h2>
<p>The app needs at least two fingers. One finger on its own shows "Waiting for players" and
waits. If you're on your own, open the options button in the top-right corner and tap
<em>Try a round</em> to watch a full round with virtual players.</p>

<h2>The countdown keeps restarting</h2>
<p>That happens on purpose whenever somebody joins or lifts off, so nobody can sneak in at
the last second. Everyone needs to hold still until the reveal.</p>

<h2>Can I pick more than one person?</h2>
<p>Yes. In the options sheet, set <strong>Winners</strong> to anything from 1 to 9. You'll
need at least one more player than the number you're keeping.</p>

<h2>How do teams work?</h2>
<p>Switch the mode to <strong>Teams</strong> in the options sheet. Everyone on the screen is
split into two balanced groups — six players become 3 vs 3, five become 3 vs 2. Tap
<em>Shuffle teams</em> to redraw.</p>

<h2>Is it actually random?</h2>
<p>Yes. Every finger has exactly the same chance in every round. The spotlight that races
between fingers during the countdown is only for suspense — the real draw happens
independently, and the animation has no influence on it. Team assignments are shuffled
properly and always balanced.</p>

<h2>How many fingers can it handle?</h2>
<p>Up to ten, depending on your device's own multi-touch limit.</p>

<h2>There's no sound</h2>
<p>Check that <strong>Music &amp; sound</strong> is on in the options sheet. The app also
respects your device's Silent switch and mixes politely with any music you already have
playing.</p>

<h2>Can I turn off the vibration?</h2>
<p>Yes — toggle <strong>Haptics</strong> off in the options sheet.</p>

<h2>Why won't the screen rotate on my iPhone?</h2>
<p>That's deliberate. If the board rotated while people were holding still, every finger
would move. iPad, which is usually flat on a table, supports every orientation.</p>

<h2>Achievements</h2>
<p>There are eight Game Center achievements, earned by playing real rounds: your first round,
10, 50 and 250 rounds, a team round, ten fingers at once, ten challenges handed out, and a
round in each of the six themes. Practice rounds (<em>Try a round</em>) never count.</p>
<p>You need to be signed in to Game Center (<em>iOS Settings → Game Center</em>). If you
decline, the game behaves exactly the same: your progress keeps being counted on the device
and is sent up the day you do sign in.</p>

<h2>Does it need an internet connection?</h2>
<p>Not to play — the game works completely offline. Only Game Center achievements need a
connection, and they are optional.</p>

<h2>What data do you collect?</h2>
<p>None at all. Your settings are saved on your device and nowhere else. See the
<a href="${PRIVACY}">privacy policy</a>.</p>

<h2>Requirements</h2>
<p>iPhone or iPad running iOS 17 or later.</p>
`;

const page = `<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Aide · Who's First</title>
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
