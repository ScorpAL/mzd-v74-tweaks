#!/bin/sh
# Publish only reviewed Markdown sources. The Wiki must already be initialized.
set -eu
if [ -z "${WIKI_TOKEN:-}" ]; then
    printf '%s\n' '::notice::Wiki sync skipped: configure the WIKI_TOKEN repository secret.'
    exit 0
fi
: "${WIKI_REPOSITORY:?Repository is required}"
case "$WIKI_REPOSITORY" in *[!A-Za-z0-9_./-]*|../*|/*) exit 1 ;; esac
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' 0
trap 'exit 130' INT
trap 'exit 143' TERM
cat > "$scratch/askpass" <<'ASKPASS'
#!/bin/sh
case "$1" in *Username*) printf 'x-access-token\n' ;; *) printf '%s\n' "$WIKI_TOKEN" ;; esac
ASKPASS
chmod 700 "$scratch/askpass"
GIT_ASKPASS="$scratch/askpass"; GIT_TERMINAL_PROMPT=0
export GIT_ASKPASS GIT_TERMINAL_PROMPT WIKI_TOKEN
git clone "https://github.com/$WIKI_REPOSITORY.wiki.git" "$scratch/wiki"
# This checkout is disposable and only the Markdown source set is published.
find "$scratch/wiki" -maxdepth 1 -type f -name '*.md' -exec rm -f {} \;
cp wiki/*.md "$scratch/wiki/"
git -C "$scratch/wiki" add --all
if git -C "$scratch/wiki" diff --cached --quiet; then exit 0; fi
git -C "$scratch/wiki" -c user.name='Wiki sync' -c user.email='wiki-sync@users.noreply.github.com' commit -m "Sync Wiki from development"
git -C "$scratch/wiki" push origin HEAD
