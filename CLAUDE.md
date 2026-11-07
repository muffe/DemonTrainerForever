# Demon Trainer Forever

## Releasing

1. Push the changes to `main`.
2. Create and push an annotated tag: `git tag -a v1.0.1 -m "v1.0.1" && git push origin v1.0.1`.

The release workflow runs the tests, then the BigWigs packager uploads the build to CurseForge, Wago and GitHub Releases. The changelog is generated from the commit messages since the last tag, so write them for players to read.

## After a WoW Forever patch

1. Run `python3 tools/generate_data.py` and review the diff of `Data.lua`.
2. If the patch changed the interface number, update `## Interface` in `DemonTrainerForever.toc`.
