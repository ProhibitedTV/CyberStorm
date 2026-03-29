# Enemy Drama Note

This pass aimed to make hunter turns produce more memorable cut-offs and warnings without changing the game's fairness contract.

## What Changed

- Flankers now aim one tile ahead of the runner's last committed step instead of only chasing the current position.
- Sector-3 wardens use that same projected target once they are fully engaged, making them feel elite without granting extra movement.
- After hunters finish their turn, the game highlights the most dangerous nearby hunter so the next threat is visible before the player commits.
- Kill and hit flashes now localize to the tile where the action happened instead of reading only as global screen feedback.

## Balance Intent

- Hunters still take exactly one response step for each player action.
- No enemy gained hidden damage, extra turns, or pathfinding.
- Telegraphing is strongest precisely when the next turn could become dangerous, so losses stay understandable instead of feeling cheap.
