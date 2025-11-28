# Git Commands Reference

A complete list of commonly used Git commands for daily development:
commits, merges, tags, comparisons, branching, stashing, logs, remotes,
and more.

---

## 1. Basic Commands

### Initialize Repository

``` bash
git init
```

### Clone Repository

``` bash
git clone <repo-url>
```

### Check Status

``` bash
git status
```

### Add Files

``` bash
git add <file>
git add .
git add -A
```

### Remove Files

``` bash
git rm <file>
git rm --cached <file>
```

### Change Default Branch Name
``` bash
git config --global init.defaultBranch <branch-name>
```

---

## 2. Commit Commands

### Commit with message

``` bash
git commit -m "message"
```

### Commit all changes

``` bash
git commit -a -m "message"
```

### Amend last commit

``` bash
git commit --amend
```

---

## 3. Branch Commands

### List branches

``` bash
git branch
```

### Create branch

``` bash
git branch <name>
```

### Switch branch

``` bash
git checkout <branch>
git switch <branch>
```

### Create & switch branch

``` bash
git checkout -b <branch>
git switch -c <branch>
```

### Delete branch

``` bash
git branch -d <branch>
git branch -D <branch>
```

---

## 4. Merge Commands

### Merge branch into current

``` bash
git merge <branch>
```

### Abort merge

``` bash
git merge --abort
```

---

## 5. Rebase Commands

### Rebase onto another branch

``` bash
git rebase <branch>
```

### Interactive rebase

``` bash
git rebase -i HEAD~5
```

### Abort rebase

``` bash
git rebase --abort
```

---

## 6. Tag Commands

### Create tag

``` bash
git tag <tag-name>
```

### Create annotated tag

``` bash
git tag -a <tag-name> -m "message"
```

### List tags

``` bash
git tag
```

### Push tag

``` bash
git push origin <tag>
```

### Push all tags

``` bash
git push --tags
```

### Delete tag

``` bash
git tag -d <tag>
git push origin :refs/tags/<tag>
```

---

## 7. Compare Files (Diff)

### Compare working directory changes

``` bash
git diff
```

### Compare staged changes

``` bash
git diff --staged
```

### Compare two commits

``` bash
git diff <commit1> <commit2>
```

### Compare branches

``` bash
git diff <branch1> <branch2>
```

---

## 8. Log Commands

### Basic log

``` bash
git log
```

### One-line log

``` bash
git log --oneline
```

### Log with graph

``` bash
git log --graph --oneline --decorate --all
```

### Show commit details

``` bash
git show <commit>
```

---

## 9. Stash Commands

### Save changes

``` bash
git stash
```

### Save with message

``` bash
git stash push -m "message"
```

### List stash

``` bash
git stash list
```

### Apply stash

``` bash
git stash apply
git stash apply stash@{n}
```

### Pop stash

``` bash
git stash pop
```

### Drop stash

``` bash
git stash drop stash@{n}
```

---

## 10. Remote Commands

### List remotes

``` bash
git remote -v
```

### Add remote

``` bash
git remote add origin <url>
```

### Change remote URL

``` bash
git remote set-url origin <url>
```

### Remove remote

``` bash
git remote remove <name>
```

### Fetch

``` bash
git fetch
git fetch --all
```

### Pull

``` bash
git pull
```

### Push

``` bash
git push
```

### Force push

``` bash
git push --force
```

---

## 11. Reset Commands

### Soft reset

``` bash
git reset --soft <commit>
```

### Mixed reset (default)

``` bash
git reset <commit>
```

### Hard reset

``` bash
git reset --hard <commit>
```

---

## 12. Clean Commands

### Preview clean

``` bash
git clean -n
```

### Delete untracked files

``` bash
git clean -f
```

---

## 13. Submodule Commands

### Add submodule

``` bash
git submodule add <url> <path>
```

### Update submodules

``` bash
git submodule update --init --recursive
```

---

## 14. Useful Shortcuts

### View last commit

``` bash
git log -1
```

### Check which branch you are on

``` bash
git branch --show-current
```

---

If you want, I can also generate separate cheat sheets (PDF / DOCX /
Markdown) or advanced Git workflow guides.
