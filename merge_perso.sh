#!/bin/bash
# retrieve upstream modifications from main on github.
set -e
git fetch github
git fetch naver
# rebase local work (keeping its merge commits) on its own remote first, so the push below is never rejected
git switch work
git rebase --rebase-merges naver/work
# fast-forward main from github
git switch main
git merge --ff-only github/main
# apply modifications to work branch
git switch work
git merge main --quiet --no-edit
git push naver work
git push naver main
