# Wiki publishing

The Wiki is user space. Keep installation, operation, backup, restore and
troubleshooting pages in `wiki/`; keep contracts, implementation notes, examples
and test instructions under `development/`.

Wiki publishing is currently disabled. Its workflow is stored as a template in
`development/workflows/wiki-sync.yml`, outside GitHub Actions' active directory.
The user pages in `wiki/` remain available as repository documentation.

To enable publishing later, move the template to `.github/workflows/wiki-sync.yml`.
It publishes `wiki/*.md` after matching pushes to `development`.
Enable the repository Wiki, create its first page, and configure
the `WIKI_TOKEN` Actions secret with write access to that Wiki repository.
Without the secret, synchronization is skipped with a notice. No token belongs
in the USB package.

`tools/sync-wiki.sh` replaces the published Markdown set with the reviewed source
set, including deleting pages removed from `wiki/`. Moving developer pages here
therefore removes them from the published Wiki on the next successful sync.
Keep Home and the sidebar limited to user pages.
