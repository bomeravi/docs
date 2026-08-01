# Resolving Merge Conflicts

Merge conflicts happen when `git pull` (or `git merge`) finds competing changes on the same lines. Git pauses and marks the conflicting sections — you resolve them manually, then complete the merge.

---

## How a Conflict Looks

```text
<<<<<<< HEAD
your local change
=======
incoming change from remote
>>>>>>> origin/main
```

- `<<<<<<< HEAD` — your local version
- `=======` — separator
- `>>>>>>> origin/main` — incoming remote version

---

## Step-by-Step: Resolve After `git pull`

### 1. Pull (conflict occurs)

```bash
git pull origin main
# Auto-merging src/app.js
# CONFLICT (content): Merge conflict in src/app.js
# Automatic merge failed; fix conflicts and then commit the result.
```

### 2. Find conflicting files

```bash
git status
# Both modified:   src/app.js
```

### 3. Open and edit each conflicted file

Remove the conflict markers and keep the correct version:

**Before:**
```text
<<<<<<< HEAD
const port = 3000;
=======
const port = 8080;
>>>>>>> origin/main
```

**After (pick one or merge both):**
```javascript
const port = 8080;
```

### 4. Stage resolved files

```bash
git add src/app.js
```

### 5. Complete the merge

```bash
git commit
# Editor opens with a pre-filled merge commit message — save and close.
```

---

## Abort and Start Over

If mid-conflict and want to undo everything back to pre-pull state:

```bash
git merge --abort
```

---

## Use a Merge Tool

### VS Code (recommended)

```bash
git config --global merge.tool vscode
git config --global mergetool.vscode.cmd 'code --wait $MERGED'
git mergetool
```

VS Code shows a 3-way diff with **Accept Current**, **Accept Incoming**, **Accept Both** buttons.

### Vimdiff

```bash
git mergetool --tool=vimdiff
```

### List available tools

```bash
git mergetool --tool-help
```

---

## Rebase Instead of Merge

`git pull --rebase` replays your commits on top of the remote branch — produces a linear history and fewer merge commits.

```bash
git pull --rebase origin main
```

If a conflict occurs during rebase:

```bash
# 1. Fix the conflicted file(s)
# 2. Stage the fix
git add <file>
# 3. Continue rebase
git rebase --continue
# Or abort entirely
git rebase --abort
```

Set rebase as default pull strategy:

```bash
git config --global pull.rebase true
```

---

## Stash Local Changes Before Pull

If you have uncommitted local work that may conflict:

```bash
# Stash local changes
git stash

# Pull cleanly
git pull origin main

# Re-apply stash
git stash pop

# If stash pop conflicts, resolve the same way as above
```

---

## Common Scenarios

### Keep only remote version (theirs)

```bash
git checkout --theirs src/app.js
git add src/app.js
```

### Keep only local version (ours)

```bash
git checkout --ours src/app.js
git add src/app.js
```

### Accept all incoming for an entire file

```bash
git checkout --theirs -- path/to/file
git add path/to/file
```

---

## Quick Reference

| Command | Action |
|---------|--------|
| `git status` | List conflicted files |
| `git diff` | Show conflict markers in working tree |
| `git add <file>` | Mark file as resolved |
| `git merge --abort` | Abandon merge, restore pre-pull state |
| `git rebase --abort` | Abandon rebase |
| `git rebase --continue` | Continue after resolving rebase conflict |
| `git checkout --ours <file>` | Take local version |
| `git checkout --theirs <file>` | Take remote version |
| `git mergetool` | Open configured visual merge tool |

---

## Related

- [Git Commands](./git-commands.md) — full command reference
- [Git Setup](./git-setup.md) — configure identity and merge tool defaults
