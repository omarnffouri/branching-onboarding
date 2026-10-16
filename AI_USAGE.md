# AI usage

## Tools

- **Claude Code** (Claude Opus 5.5) in the Claude desktop app, used as a pair programmer for the whole exercise: reading the brief, planning, architecture, code, tests, copy, and driving the iOS Simulator to check the result.
- **Claude's built-in browser**, to look for free-licence photos on Unsplash and the welcome video on Pexels.

No image or video generators were used. Photos are real Unsplash photos, the video is a real Pexels clip, and the fonts come from Google Fonts' repository.

## How I worked with it

1. **Discussion before code.** We went through the brief together, agreed what "wow" should mean for *this* reviewer (polish, branching, RTL, honest scope), and settled the big decisions before writing anything. Those were Riverpod with a pure-Dart engine, Traininpink's own visual language rather than a new one, photos bundled for offline use, and iPhone as the target.
2. **Engine first, UI second.** The flow engine and its tests (including a 1,000-member random walk) were written and green before any screen existed.
3. **Every screen checked in the simulator**, in English *and* Arabic, by actually tapping through the flow. Several bugs below were only found that way.
4. **Small commits** at each milestone, with the analyzer at zero issues and the tests passing each time.

## Where it helped most

- Turning "the branching rules live in the config" into a design: derived path, backwards-only conditions, a validator with readable errors.
- Writing the property-style test that walks the real config 1,000 times. I would not have budgeted time for it by hand.
- Getting RTL details right that are easy to miss: directional insets and icons, no negative letter spacing in Arabic, the email field always left to right, ICU plural forms including the Arabic dual.
- Drafting bilingual copy in a consistent voice (feminine Arabic forms throughout).

## What I rejected or changed, and why

| Suggestion / output | What I did instead | Why |
|---|---|---|
| A single screen that swaps questions with an `AnimatedSwitcher` | Real `CupertinoPage`s derived from state | On iPhone, people swipe back from the edge. A switcher breaks that, and a reviewer would notice in seconds |
| A lookup table from step type to widget | Sealed step classes and an exhaustive `switch` | The compiler then forces every new step type to get a screen |
| Bloc, GetX, go_router, freezed | Plain Riverpod `Notifier` + Dart 3 sealed classes and records | Less code to explain, and every dependency has to earn its place |
| `google_fonts` | Font files bundled in `assets/fonts` | It downloads at runtime, and the brief says the app runs offline |
| A testimonial screen copied from the real app's pattern, with an invented member and numbers | Educational info screens ("Feeling heavy isn't a willpower problem") | Fabricated social proof is the wrong habit, even in a demo |
| Timers or an `isNavigating` flag against double taps | Intents carry their origin (`continueFrom(stepId)`) and stale ones are ignored | Deterministic, testable, no timing races |
| An `OnboardingAnalytics` interface with one method | A function typedef | Simpler, and what the lint rules asked for |
| Email suggestions by edit distance alone | Added a list of real domains that are never "corrected" | It would have turned `mail.com` and `ymail.com` into `gmail.com`. Caught in review, now covered by a test |
| Copying Traininpink's cocoa palette and photo-light screens | Our own dusty rose palette, a "flow" motion language, a welcome video and per-step photos set in the config | My call after using the first version: matching their app exactly showed less judgment than giving the flow its own identity |
| "تجربة مجانية لـ7 أيام" | "تجربة مجانية لمدة 7 أيام" | The attached prefix next to a digit reads awkwardly in Arabic |

## Mistakes it made that were caught

- A staggered animation whose last interval ended past 100%, which threw an assertion and blanked the welcome screen. Found on first launch, fixed by clamping.
- The "building your plan" screen rendered off-centre. Found in the simulator.
- Coming back to an answered single-choice question showed no Continue button, because the page stayed alive under the next one and remembered its first visit. Fixed by reacting to the page becoming current again.
- A test helper that shadowed `flutter_test`'s own `addTearDown`. Removed.
- A random-walk assertion expecting 6 distinct paths when the config has exactly 5. The test was wrong, not the engine.

## Ownership

The brief says I must be able to explain every line. The code is deliberately small and commented where a decision is not obvious. The README's *Key decisions* table is the map I'd use to walk through it. Anything I couldn't defend, I cut.
