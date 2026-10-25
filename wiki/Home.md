# CMU Tweaks development

This Wiki is maintained from `wiki/` on the development branch.

- [Manifest format](Manifest-format)
- [Worker contract](Worker-contract)
- [Repository structure](Repository-structure)
- [Vehicle testing](Vehicle-testing)

Edit sources in a PR. The Wiki sync workflow publishes them after a push to
`development`. Initial setup requires enabling this repository's Wiki, creating
its first page and adding a `WIKI_TOKEN` Actions secret with write access to that
Wiki repository. Without that secret, synchronization is skipped with a notice.
The workflow never needs a token in the USB package.
