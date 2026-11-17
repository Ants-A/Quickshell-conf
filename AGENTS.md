# Project guidance

This project uses **Quickshell**, the desktop shell and ricing framework, with **Qt Quick** and QML for its user interface.

When working in this repository:

- Implement shell components and configuration using Quickshell APIs and Qt Quick/QML.
- Make liberal use of small, reusable QML components; extract repeated or independently useful UI into components instead of building monolithic files.
- Keep changes compatible with the project's installed Quickshell and Qt Quick versions.
- Consult the official Quickshell and Qt Quick documentation regularly while working. Check the relevant documentation whenever using or changing an API, and verify details against the versions installed for this project.
- Official documentation: [Quickshell](https://quickshell.org/docs/v0.3.2) · [Qt Quick](https://doc.qt.io/qt-6/qtquick-index.html).
- Before choosing an implementation, consult the relevant official documentation and compare the available supported approaches. Choose the simplest, most efficient approach that fits this project and its installed versions; do not assume the first workable option is optimal.
- Prefer native QML and Quickshell patterns over introducing unrelated UI frameworks.
- Keep interface code aligned with the project's organic Material design language, as established in `shell.qml`: warm botanical colors, soft rounded forms, and clear, readable typography. Adapt Material 3 patterns to native Qt Quick and Quickshell components.
- Commit each completed workpiece.
- Do all new work on its own branch. Once a workpiece is complete, commit it, confirm with the user that the code is of quality, merge it into `main`, and push `main` to `origin`. !IMPORTANT: Must check with user
