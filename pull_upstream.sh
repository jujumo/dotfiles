#!/bin/bash
# retrieve upstream modifications from main on github.
git switch main
git fetch github
git merge --ff-only github/main
# apply modifications to work branch
git switch work
git merge main --quiet --no-edit
git push naver work
