#!/bin/sh
## vim: ft=sh ts=4 sts=4 sw=4 et
## lua vim.b.autoformat=false


git checkout master                         && \
git fetch --all --tags                      && \
git rebase upstream/master                  && \
git fetch upstream --tags                   && \
git push origin --tags --force              && \
git push origin master --force-with-lease   && \
echo "Done"

