# Homebrew Distribution

Loupe should be distributed as a Homebrew tap formula.

## User Install

```bash
brew tap heoblitz/loupe
brew install loupe
```

`loupe` declares `cameroncooke/axe/axe` as a Homebrew dependency. Users should
not need to install AXe separately.

## Tap Layout

Publish this formula in the tap repository:

```text
heoblitz/homebrew-loupe
└── Formula
    └── loupe.rb
```

The canonical formula source in this repo is `Formula/loupe.rb`.

## Release Checklist

1. Make the source archive public and immutable.
2. Tag the release, for example `v0.1.0`.
3. Replace the all-zero `sha256` in `Formula/loupe.rb`.
4. Copy `Formula/loupe.rb` into `heoblitz/homebrew-loupe/Formula/loupe.rb`.
5. Run:

```bash
brew tap heoblitz/loupe
brew audit --strict --online heoblitz/loupe/loupe
brew install --build-from-source heoblitz/loupe/loupe
brew test heoblitz/loupe/loupe
```

For local tap smoke testing before the public tap exists:

```bash
brew tap heoblitz/loupe https://github.com/heoblitz/Loupe.git
brew install --HEAD heoblitz/loupe/loupe
```

That path still requires the GitHub URL to be reachable from the installing
machine.

## Current Blocker

`Formula/loupe.rb` is tap-shaped and build-verified with a local archive, but it
is not ready for a public stable `brew install` until the GitHub release archive
is reachable and the real release checksum replaces the all-zero checksum.
