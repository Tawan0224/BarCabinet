# Bar Cabinet

An iOS app that flips the usual recipe-app flow: instead of finding a drink and discovering you're missing half of it, you tell the app what you have and it shows you what you can make right now.

**Course:** iOS Application Development (Project 02)

**Team**
- Aung Khant Zaw — 6611947
- Aung Myint Myat — 6611906
- Soe Min Min Latt — 6611938

## What it does

- Browse cocktails, mocktails, and shakes by category on the **Discover** tab.
- **Search** by drink name or by ingredient (scans the whole catalogue, so ingredient search actually returns useful results despite the API's per-ingredient cap).
- Open the **Mix Guide** on any drink for the photo, glass, ingredients with measures, and step-by-step instructions. Ingredients you already have are ticked automatically.
- Build your **cabinet** in the *My Bar → Ingredients* segment (searchable list from TheCocktailDB, plus a free-text "Add \"…\"" row for anything the API doesn't know).
- **You can make N drinks** — computed live from the API by cross-referencing every candidate drink against your cabinet; tap the card to see the full list.
- Save drinks to **Favorites** from the Mix Guide (heart or "Save to Favorites" button). Persists across launches.
- **Settings** — Light / Dark / System theme, saved with `@AppStorage`.
- Custom splash screen with logo slot and progress bar on launch.

## Tech stack

- SwiftUI (iOS 17+)
- `@Observable` view models
- SwiftData for persistent Favorites and Cabinet
- `URLSession` + `async/await`, `Codable` decoding
- [TheCocktailDB](https://www.thecocktaildb.com) free public REST API (no key required)

## Project structure

```
BarCabinet/
├── BarCabinetApp.swift          # App entry + modelContainer
├── Assets.xcassets              # AppIcon, AppLogo, colors
├── Models/
│   ├── Drink.swift              # Drink + Ingredient + DrinkSummary (custom decoding for 15 flat fields)
│   ├── FavoriteDrink.swift      # SwiftData @Model
│   └── CabinetIngredient.swift  # SwiftData @Model
├── Services/
│   └── CocktailAPI.swift        # URLSession client for filter/lookup/search/random endpoints
├── ViewModels/
│   ├── DiscoverViewModel.swift
│   ├── SearchViewModel.swift
│   ├── MyBarViewModel.swift
│   ├── MixGuideViewModel.swift
│   ├── AddIngredientViewModel.swift
│   └── MatchStore.swift         # Cabinet ↔ full catalogue matching engine
└── Views/
    ├── ContentView.swift        # TabView + splash + theme
    ├── SplashView.swift
    ├── DiscoverView.swift
    ├── AllDrinksView.swift
    ├── SearchView.swift
    ├── MyBarView.swift
    ├── MakeableDrinksView.swift
    ├── MixGuideView.swift
    ├── AddIngredientView.swift
    ├── SettingsView.swift
    └── DrinkCard.swift
```

## Matching logic (the interesting bit)

The proposal called out ingredient matching as the piece we most wanted to build. TheCocktailDB's free `filter.php?i=<ingredient>` endpoint is capped at 1 drink per call, so it can't be used to build a real candidate set. Instead:

1. Fetch the full drink catalogue via `search.php?f=<letter>` for `a–z` + `0–9` in parallel (returns full drinks with ingredients).
2. Also fetch `search.php?s=<term>` for each cabinet ingredient name to catch drinks past the 25-per-letter cap (e.g. "Banana Strawberry Shake" isn't in the first 25 'B' drinks but shows up under `s=banana`).
3. Union everything by drink ID into a pool of ~450 drinks.
4. Filter to drinks where **every** ingredient is in the cabinet (case-insensitive).
5. Cache by cabinet key so re-opens are instant; invalidate on cabinet change.

Concurrency is bounded to 4 with exponential-backoff retries because bursts trigger rate-limiting on the free key.

## Running

Requires Xcode 15+ and iOS 17+.

```bash
open BarCabinet/BarCabinet.xcodeproj
```

Select an iOS 17+ simulator or device, then Run. No API key or configuration needed.

## API endpoints used

- `filter.php?c=<category>` — Discover categories (Cocktail, Ordinary Drink, Shake).
- `filter.php?a=Non_Alcoholic` — Mocktail filter.
- `search.php?s=<term>` — Search drinks by name (and, for ingredient search, by cabinet name).
- `search.php?f=<letter>` — Bulk fetch full drinks starting with a letter.
- `lookup.php?i=<id>` — Full drink details by ID (Mix Guide).
- `list.php?i=list` — 100 suggested ingredients in the Add Ingredient sheet.

## Known limitations

- The free API key (v1 `/1/`) caps `filter.php?i=<ingredient>` at 1 result and `search.php?f=<letter>` at 25 results per letter. We work around these with the strategies above, but obscure drinks may still be missed.
- The `list.php?i=list` catalogue returns only 100 suggested ingredients — hence the "Add \"...\"" free-text row.
- First cabinet compute takes a few seconds (~5–15s depending on network); repeat computes for the same cabinet are instant thanks to caching.

## Data source

Drink data and photos come from [TheCocktailDB](https://www.thecocktaildb.com), used under their free-tier terms.
