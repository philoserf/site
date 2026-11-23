---
title: "The mathematics underlying Magic: The Gathering"
description: Build a sound 60-card deck with 24 lands and you will still miss your fourth land drop in more than a third of your games. Nothing went wrong. What else is the arithmetic deciding?
date: 2027-02-08
---

Build a sound 60-card deck with 24 lands, shuffle it well, and play first. In more than a third of your games you will miss your fourth land drop on turn four. Nothing went wrong. That miss is built into the arithmetic of the deck.

_Magic: The Gathering_ is full of facts like this. Under the dragons and planeswalkers sits a mathematical system of unusual depth. Probability decides what you draw. Combinatorics counts how cards combine. Deckbuilding is an optimization problem, combat is a game-theory problem, and trading cards for mana for life for time is economics. Information theory explains why looking at cards matters, and computational complexity shows that some board states cannot be solved even with nothing hidden.

All of it serves one goal. The aim in Magic is to maximize your chance of eventually winning, with incomplete information, limited resources, and an opponent working against you.

## Probability: what's in the library

Magic's first mathematics is the shuffled library. A deck is a finite population, and every draw changes what remains, so successive draws are not independent. The right tool is the _hypergeometric distribution_.

Take a 60-card deck with 24 lands and draw seven. The expected number of lands is

$$
E[X]=n\frac{K}{N}=7\frac{24}{60}=2.8
$$

where $N$ is the deck size, $K$ the number of lands, and $n$ the number of cards drawn.

An average of 2.8 lands says little about how often you get a hand you can keep. For that you need the chance of drawing exactly $k$ lands:

$$
P(X=k)=
\frac{\binom{K}{k}\binom{N-K}{n-k}}
{\binom{N}{n}}
$$

Here $\binom{a}{b}$ counts the ways to choose $b$ objects from $a$, ignoring order. Run the numbers across common land counts, for a random seven before any mulligan or card selection, and a tradeoff appears:

| Lands in deck | 0–1 lands | 2–4 lands | 5–7 lands |
| ------------- | --------: | --------: | --------: |
| 20            |     24.7% |     71.7% |      3.6% |
| 22            |     19.0% |     75.4% |      5.6% |
| 24            |     14.3% |     77.5% |      8.3% |
| 26            |     10.4% |     77.8% |     11.8% |
| 28            |      7.4% |     76.5% |     16.1% |

Each land you add makes a mana-starved hand less likely and a flooded one more likely. No land count is right for every deck; the answer depends on what the deck wants to do with its mana. Cheap spells get by on fewer lands. A deck that must cast five- and six-drops (spells that cost five or six mana) on time needs more. Card draw, ramp, and alternative costs shift the numbers again.

That pattern runs through the whole game: improving one probability usually worsens another.

## Mana curves: hitting land drops on time

Lands in the opening hand are only the start. You also need to keep drawing them on schedule.

Assume a 60-card deck, no mulligans, no extra draw or ramp, and that you play first in a two-player game. You have seen nine cards by turn three and ten by turn four.

| Lands | 3+ by turn 3 | 4+ by turn 4 |
| ----- | -----------: | -----------: |
| 20    |        63.8% |        44.1% |
| 22    |        71.9% |        53.9% |
| 24    |        78.9% |        63.2% |
| 26    |        84.6% |        71.6% |
| 28    |        89.2% |        79.0% |

These are raw odds of making the land drops, not of having the right colors or anything to spend the mana on. The 24-land row is the case this piece opened with: about 37% of games miss the fourth land on turn four.

### Colors add a second constraint

Now suppose only 10 of your 24 lands make blue. Your chance of at least one blue source in the opening seven is about 74%. Raise that to 16 blue sources and it climbs to about 90%.

Color intensity matters too. A spell costing `{1}{U}` and one costing `{U}{U}` have the same mana value, but the second asks far more of the mana base. Frank Karsten, a mathematician and professional player, built his well-known mana-base guidelines on exactly this problem, using probability models to estimate how many lands and colored sources a deck needs to cast its spells on curve, each on the turn its cost first allows.

His work leads to a useful way of seeing a deck: as a probability distribution, tuned to produce a sequence of plays you can afford.

## Combinatorics: finding the cards that matter

Next question: how reliably can a deck find one particular card?

Say your deck runs four copies of a card the strategy depends on. Rather than adding up the chances of drawing one, two, three, or four copies, find the chance of drawing none and subtract it from one:

$$
P(\text{at least one})=
1-\frac{\binom{56}{7}}{\binom{60}{7}}
\approx 39.95\%
$$

By turn four, going first, with ten cards seen, that rises only to 52.77%. Even a four-of goes missing through turn four in nearly half your games.

Deckbuilders answer this in two ways. _Redundancy_ means running several cards that do roughly the same job. _Selection_ means running effects that dig for a specific card. A deck that needs early removal can play several different removal spells instead of leaning on four copies of one. What matters is the chance of having the _effect_, not the particular card.

### Commander

Commander changes the arithmetic sharply. The library holds 99 cards, with the commander starting outside it. If a given card appears exactly once, your chance of seeing it in the opening seven is

$$
P=\frac{7}{99}\approx7.07\%
$$

Compare that with nearly 40% for a four-of in a 60-card deck. The commander itself is the exception: always available from the command zone, it is one reliable strategic piece set beside 99 cards you can barely count on individually. The format rewards redundancy, cards that work with many others, and cards that do several jobs, which helps explain why Commander and 60-card Constructed feel like different games on the same rules engine.

## Mulligans: trading quantity for quality

The London mulligan, adopted in 2019, makes the trade explicit. You draw a fresh hand at your starting size, normally seven, then put one card on the bottom of your library for each mulligan you've taken. Multiplayer games grant one free mulligan that costs no cards.

You give up quantity to buy quality. Six cards chosen from seven can beat an unfiltered seven, because what counts is whether the cards work together as well as how many lands you hold. Compare two hands with three lands each. One adds two cheap creatures, a removal spell, and a five-drop. The other adds four spells costing six or more. The land counts match; the second hand can be far worse.

Framed as a decision:

$$
\text{Keep if }P(\text{win}\mid H)
\geq
E[P(\text{win}\mid H_{\text{mulligan}})]
$$

where $H$ is the hand in front of you and the right side is your expected chance of winning after mulliganing and losing a card. You rarely know either number precisely, but this is the comparison you are making. It also explains why the right mulligan depends on the opponent: a slow hand can be excellent against control and hopeless against aggro.

## Outs: playing to win

An _out_ is a card that can rescue your position. Suppose 8 of the 50 cards left in your library will save you. Your chance on the next draw is

$$
P=\frac{8}{50}=16\%
$$

With two draws, the chance of finding at least one is

$$
P=1-\frac{42}{50}\times\frac{41}{49}\approx29.7\%
$$

The calculation keeps two questions apart that players tend to merge: how likely am I to draw the answer, and how likely am I to win if I do? A card can answer a threat without winning the game, and several different cards can open different paths to victory.

This is what _playing to your outs_ means. When you're behind and must choose between a safe play that keeps you alive longer and a risky one that preserves your only realistic winning line, the right choice is the one with the better chance of winning, even when the safe play would survive longer.

## Expected value: cards, life, and mana

Magic is a resource-allocation game, and its resources don't convert cleanly into one another: cards in hand, mana available now, permanents on the battlefield, life, turns, and information about your opponent. Their values also shift. A point of life is worth little at 20 and a great deal at 2. An extra land is precious on turn three and close to useless on turn fifteen. This is where economic thinking helps.

### Card advantage

A removal spell that trades for one creature is a one-for-one. A spell that kills two creatures for one card is a two-for-one. But counting cards only approximates value: killing the one creature that would win the game can matter more than killing three that don't. The true measure is how much an action moves your chance of winning:

$$
\Delta V=
P(\text{win after action})-
P(\text{win before action})
$$

You can seldom compute it exactly, but it names the right target.

### Tempo

Spend two mana to remove a creature your opponent paid five for. You each lost one card, but they spent more mana on the exchange, and you may now be well ahead on tempo.

Tempo isn't speed. It is how far each player's position has developed over time. A player who forces the opponent to spend whole turns answering cheap threats can pull ahead without ever gaining a card. That is why aggressive decks will trade cards inefficiently to keep up pressure, and why control decks take early damage so they can deploy stronger answers later.

What a resource is worth depends on when you can use it as much as on how much of it you hold.

## Game theory: combat and bluffing

A probability exercise has no opponent. Magic does, and every attack, block, and spell is a decision for both players.

Your 3/3 (three power, three toughness) attacks into an opposing 5/5. Your opponent knows a trick like Giant Growth would let the 3/3 win. They can block and risk the 5/5, or let three damage through. You, meanwhile, could attack with the trick in hand, attack without it as a bluff, or not attack at all.

Your best choice depends partly on what your opponent believes about you. If you never bluff, they learn that an attack means a trick. If you always bluff, they learn to block. The strongest play is sometimes to vary your actions on purpose, which game theory calls a _mixed strategy_.

Frank Karsten worked through exactly this in his 2007 article "Introduction to Game Theory," where a simplified combat model shows randomized bluffing beating a predictable strategy. The idea underneath is the Nash equilibrium: a pair of strategies in which neither player gains by changing theirs alone.

Real games are messier, since decks, hands, and futures are only partly known. The principle holds anyway: the correct action is often a strategy that accounts for how your opponent might respond.

## Information theory: knowing changes everything

Magic is a game of imperfect information. You see your hand, the battlefield, the graveyards, and some other public cards, but usually not your opponent's hand or the order of either library. That makes information a resource in its own right.

Compare two spells. One draws a card. The other looks at the top three cards of your library, puts one in your hand, and sends the rest elsewhere. Both net one card, but the second adds selection, and its edge comes from cutting your uncertainty about what you get.

Shannon entropy is the standard measure of that uncertainty:

$$
H(X)=-\sum_i p_i\log_2(p_i)
$$

A library with many equally likely next draws has high entropy. One whose top card you already know has none. Drawing, scrying and surveilling (looking at the top cards and choosing where they go), tutoring (searching the library for a card), and revealing all change what a player knows. Less uncertainty isn't always better, though: revealing your hand can give your opponent more than you gain.

### Bayesian reasoning at the table

Your opponent leaves two blue mana open and passes. You suspect a counterspell. Before they passed you held some belief about whether they had one, and their choice to keep mana up updates it. Bayes' theorem describes the update:

$$
P(C\mid E)=
\frac{P(E\mid C)P(C)}{P(E)}
$$

$C$ is the hypothesis that they hold a counterspell, and $E$ is the behavior you observed. The key quantity is how likely they would be to leave that mana open with a counterspell and without one. Skilled players estimate these odds by feel. Beyond remembering which cards might be in the deck, they keep revising a model of the hidden hand.

## Limited: mathematics in design and drafting

In Limited, the player doesn't control the card pool, so the mathematics moves partly to the designers. They decide how often particular mechanics, creature sizes, removal spells, and combinations show up in boosters.

Their basic measure is _as-fan_, short for _as-fanned_: the average number of cards with a given trait per booster. Mark Rosewater, Magic's head designer, discusses it in his June 2025 article "Do the Math," along with _as-played_, which accounts for how likely opened cards are to make it into actual games.

Picture a hypothetical booster with ten commons drawn from 100 equally likely commons. If 20 of those commons carry a mechanic,

$$
\text{As-fan}=10\times\frac{20}{100}=2
$$

The mechanic appears twice per booster on average. That guarantees neither two copies in any given pack nor two appearances in any given game. Players still have to draft the cards, put them in decks, draw them, and find a moment to play them. So there is a chain:

1. As-fan: how often the mechanic appears in boosters.
2. Draft and deck selection: which of those cards players take and play.
3. As-played: how often the mechanic actually shows up in games.
4. Gameplay experience: how often players meet the interactions that matter.

Each link is related to the next, but none determines it. The designer's real job is controlling how often players meet a given experience. Too rare, and a mechanic never matters; too common, and it takes over the format.

This is where designing Magic and playing it part ways mathematically. The designer shapes probability distributions across thousands of games. The player makes decisions inside one draw from them.

## Computational complexity: Magic as a computer

One result stands apart. In 2020, Alex Churchill, Stella Biderman, and Austin Herrick published _Magic: The Gathering Is Turing Complete_, showing that Magic can simulate a universal Turing machine. They built a class of legal game states in which deciding who eventually wins is equivalent to deciding whether an arbitrary Turing machine halts.

That claim is far stronger than "Magic has a lot of possible moves." It means that, in the mathematical sense their construction establishes, no algorithm can determine the eventual winner for every such game state. The result doesn't rely on hidden cards or random draws, and the moves in the construction are forced. The obstacle is the computation itself.

None of this makes a Friday night game at the local store unanalyzable, or every Magic decision undecidable. The theorem concerns specially built positions that exploit the full expressive power of the rules. Still, it says something about the game. Magic began as a small set of rules about creatures, spells, and mana, and the interactions among those rules grew powerful enough to express arbitrary computation. It is still played with cardboard on a table.

## Statistics: measuring skill through noise

The last problem is telling whether a deck, or a player, is actually good.

A deck that goes 6–4 has won 60% of its matches, but that record says little about its true win rate. A deck that truly wins half its matches will post six or more wins in ten about 38% of the time.

Larger samples help. A standard approximation for the standard error of an observed win rate is

$$
SE=\sqrt{\frac{p(1-p)}{n}}
$$

If a deck wins 60 of 100 independent matches,

$$
SE=\sqrt{\frac{0.6(0.4)}{100}}
\approx0.049
$$

which gives a rough 95% confidence interval of $60\%\pm9.6\%$. That is a wide band, even after 100 matches.

The assumptions matter as well. Matches against different opponents and archetypes are not identically distributed, and they may not be independent. A deck's record reflects its pilot, its opponents, the metagame, the draws, and the matchups. That is why controlled playtesting and large datasets now matter so much to competitive play and to design. One spectacular win is weak evidence that a deck is good, and one miserable evening is weak evidence that it's broken.

## Deciding under uncertainty

Every branch above answers the same question: how should a rational player decide when the future is uncertain, resources are limited, and another rational player is pushing back? Written as an objective:

$$
a^*=\arg\max_{a\in A}E[P(\text{win}\mid a)]
$$

Choose the available action with the highest expected chance of winning. The rule is simple; the expectations are not. Every action changes the board, spends resources, reveals information, invites a response, and opens a different spread of futures. The best play may not deal the most damage or keep the most cards. It may mean sacrificing a strong creature, holding back a spell you could afford, taking a lot of damage, or taking a deliberate risk.

Magic's mathematics does not replace judgment; it gives judgment a structure. A good player doesn't compute probabilities every turn. A good player has intuitions that approximate those computations, knows when the intuitions can't be trusted, and recognizes the positions that call for slowing down.

The rules decide what can happen. Mathematics describes what might happen and how likely it is. Playing well is choosing which of those possibilities is worth chasing.

Sources: [Frank Karsten, How Many Sources Do You Need to Consistently Cast Your Spells? A 2022 Update](https://www.tcgplayer.com/content/article/How-Many-Sources-Do-You-Need-to-Consistently-Cast-Your-Spells-A-2022-Update/dc23a7d2-0a16-4c0b-ad36-586fcca03ad8/), [Wizards of the Coast, Frank Karsten, Introduction to Game Theory (May 30, 2007)](https://magic.wizards.com/en/news/feature/introduction-game-theory-2007-05-30), [Wizards of the Coast, Mark Rosewater, Do the Math (June 30, 2025)](https://magic.wizards.com/en/news/making-magic/do-the-math), [Alex Churchill, Stella Biderman, and Austin Herrick, Magic: The Gathering Is Turing Complete](https://arxiv.org/abs/1904.09828)
