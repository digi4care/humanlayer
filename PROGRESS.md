
# PROGRESS

## Doel

 Linux dev-workflow voor HumanLayer/CodeLayer stabiel krijgen op EndeavourOS (Arch-based), incl. `make setup`, `make wui-dev`, `make codelayer-dev`.

 Daarnaast: **reproducible Linux builds via Docker build-matrix** (Ubuntu/Debian/Arch/Fedora/openSUSE) zodat Linux build targets reproduceerbaar getest kunnen worden.

## Environment

- **OS**: EndeavourOS (Arch-based)
- **Session**: Wayland (workaround gebruikt om WUI te renderen)
- **JS runtime**: Bun
- **WUI**: Tauri + WebKitGTK

## Huidige lokale state

- **Werk-branch (lokaal)**: `work/progress-fixes` (bevat beide fixes om verder te werken)
- **Worktree voor PR #913**: `../humanlayer-pr913` (branch: `pr/913-linux-support`)
- **Docker build-matrix branch (fork)**: `origin/chore/docker-build-matrix` (gepusht; PR aanmaken vanuit je fork)
- **Git remotes**:
  - `origin`: `https://github.com/digi4care/humanlayer.git`
  - `upstream`: `https://github.com/humanlayer/humanlayer.git`

## Docker build-matrix (reproducible Linux builds)

 Status:

- Docker build-matrix is toegevoegd in branch `chore/docker-build-matrix` (fork: `digi4care/humanlayer`).
- In scope:
  - `docker-compose.build.yml`
  - `docker/build/{ubuntu,debian,arch,fedora,opensuse}/Dockerfile`
  - `hack/docker_build.sh`
  - docs in `DEVELOPMENT.md`
- Tooling pinned:
  - Node: `NODE_VERSION` (default `22.0.0`, engine requirement is `>=20`)
  - Go: `GO_VERSION` (default `1.24.0`)
  - Bun: `BUN_VERSION` (default `1.2.23`)
  - Rust: `RUST_TOOLCHAIN` (default `stable`)

 Quick commands:

- `bash hack/docker_build.sh arch -- node --version`
- `bash hack/docker_build.sh arch -- bun --version`
- `bash hack/docker_build.sh arch -- make setup`

## Next focus: Arch Docker testen + in orde maken

 Doel:

- Arch container moet dezelfde builds kunnen doen als je host-Arch (waar het al werkte).

 Checklist (minimale smoke test):

- [ ] `bash hack/docker_build.sh arch -- node --version`
- [ ] `bash hack/docker_build.sh arch -- bun --version`
- [ ] `bash hack/docker_build.sh arch -- go version`
- [ ] `bash hack/docker_build.sh arch -- rustc --version`

 Checklist (repo build test):

- [ ] `bash hack/docker_build.sh arch -- make setup`

 Checklist (PR #913 Linux targets in container):

- De Linux targets (`codelayer-nightly-bundle-linux`, etc) zitten in `../humanlayer-pr913` worktree.
- Optie A (meest clean): cherry-pick de Docker build-matrix commits naar die worktree-branch en run dan in die worktree:
  - `bash hack/docker_build.sh arch -- make codelayer-nightly-bundle-linux`
- Optie B: (sneller, minder netjes) copy alleen `docker-compose.build.yml`, `docker/build/**`, `hack/docker_build.sh` naar de worktree.

 Troubleshooting hints (als Arch container faalt, maar host-Arch werkt):

- Check missende system deps in `docker/build/arch/Dockerfile`.
- Tauri docs voor Arch noemen o.a. `appmenu-gtk-module` en `xdotool` (als er runtime/build errors zijn rond tray/menu of xdo, voeg deze toe).
- AppImage bundling blijft vaak het stabielst met:
  - `NO_STRIP=1`
  - `APPIMAGE_EXTRACT_AND_RUN=1`
  - `ARCH=x86_64`

## PRs

- **#913 (feature): Linux support**: <https://github.com/humanlayer/humanlayer/pull/913>
- **#914 (setup/Linux bootstrap fix):** <https://github.com/humanlayer/humanlayer/pull/914>
- **#916 (DB-path fix):** <https://github.com/humanlayer/humanlayer/pull/916>
- **#917 (fix): PostCSS `@import` order**: <https://github.com/humanlayer/humanlayer/pull/917>
- **#918 (fix): ticket port selection wrap**: <https://github.com/humanlayer/humanlayer/pull/918>

## Wat werkt nu (workaround workflow)

- **Daemon apart draaien**
  - Start `hld` daemon buiten de WUI om.
  - WUI verbinden met bestaande daemon.
- **WUI autolaunch uit**
  - `HUMANLAYER_WUI_AUTOLAUNCH_DAEMON=false`
- **Wayland rendering workaround (GBM/DMABUF issue)**
  - `WEBKIT_DISABLE_DMABUF_RENDERER=1`
  - (evt) `GDK_BACKEND=x11`
- **WUI naar daemon wijzen**
  - `VITE_HUMANLAYER_DAEMON_URL=http://localhost:7777` (of andere port)

## Afgerond

- **Fix: PostCSS warning `@import` order**
  - File: `humanlayer-wui/src/App.css`
  - Fix: Google Fonts `@import url(...)` helemaal bovenaan gezet.
  - PR: #917

- **Fix: `make codelayer-dev TICKET=ENG-9999` faalde op “Could not find available port”**
  - Root cause: port selection had edge-case bij hoge ticketnummers (zoals `9999`) → te weinig fallback candidates.
  - Fix: port berekening wrapt nu binnen ranges.
  - PR: #918

- **PR #913 smoke-test (in worktree `../humanlayer-pr913`)**
  - `make setup` faalde initieel omdat `mockgen` niet in `PATH` zat.
    - `mockgen` bestaat wel in `$(go env GOPATH)/bin/mockgen`.
    - Workaround: `export PATH="$(go env GOPATH)/bin:$PATH"`.
  - `make setup` geeft warning: `Unsupported distribution: endeavouros`.
  - Met `PATH` workaround:
    - `make setup` ✅
    - `make daemon-dev-build` ✅
    - `make check-wui` ✅ (format/lint/tsc + cargo check + clippy)
    - `make test-wui` ✅
    - `make wui-dev` start compile (lange first build; geen functionele failure gezien).

## Open issues / pending fixes

- **Vite warning: missing base tsconfig**
  - Root `tsconfig.json` verwijst naar missing `@codelayer/typescript-config/base.json`.
  - Fix optie: lokale fallback tsconfig (geen private package dependency) of workspace package toevoegen.

- **Wayland/GBM buffer error**
  - Symptom: `Failed to create GBM buffer ...`
  - Workaround: `WEBKIT_DISABLE_DMABUF_RENDERER=1` (+ evt `GDK_BACKEND=x11`).
  - Extra (Arch/KDE6/Wayland/Nvidia): soms start de app alleen met software rendering:
    - `WEBKIT_DISABLE_COMPOSITING_MODE=1`
    - of volledig software: `LIBGL_ALWAYS_SOFTWARE=1`
  - Nice-to-have: docs update (CONTRIBUTING/WUI README).

- **PR #913 extra bijdrage (optioneel)**
  - Test Linux build targets uit #913:
    - `make humanlayer-binary-linux-x64`
    - `make codelayer-bundle-linux`
  - Mogelijke follow-up PR:
    - EndeavourOS mapping (`endeavouros -> arch`)
    - Go bin dir in `PATH` zetten tijdens setup (mockgen).
    - Wayland workaround documenteren.

## Actieplan (checklist)

### 0) Upstream merge/review gates (blokkerend)

- [ ] **PR #914: review opvolgen / wachten op merge (maintainers)**
  - Done: PR is gemerged in `upstream` (door maintainers), en je lokale branch/worktree is bijgewerkt.
- [ ] **PR #916: review opvolgen / wachten op merge (maintainers)**
  - Done: PR is gemerged in `upstream` (door maintainers), en je lokale branch/worktree is bijgewerkt.
- [ ] **PR #917: review opvolgen / wachten op merge (maintainers)**
  - Done: PR is gemerged in `upstream` (door maintainers), en je lokale branch/worktree is bijgewerkt.
- [ ] **PR #918: review opvolgen / wachten op merge (maintainers)**
  - Done: PR is gemerged in `upstream` (door maintainers), en je lokale branch/worktree is bijgewerkt.

### 1) Linux bootstrap (EndeavourOS/Arch)

- [ ] **EndeavourOS mapping fixen** (`endeavouros -> arch`)
  - Doel: `make setup` zonder “Unsupported distribution” warning.
  - Done: op EndeavourOS wordt distro herkend als `arch` (of equivalent) en setup draait zonder warning.

### 2) Go tooling / `mockgen` op `PATH`

- [ ] **Setup maakt `mockgen` vindbaar zonder handmatige `export PATH=...`**
  - Opties: `$(go env GOPATH)/bin` toevoegen aan PATH in setup, of tooling detecteren + duidelijke instructie.
  - Done: in een schone shell werkt `make setup` zonder handmatige PATH workaround.

### 3) WUI rendering (Wayland/GBM/DMABUF)

- [ ] **Wayland/GBM issue vastleggen + workaround documenteren**
  - Symptom: `Failed to create GBM buffer ...`
  - Done: workaround staat in docs (CONTRIBUTING/WUI README) en je weet welke env vars je moet zetten:
    - `WEBKIT_DISABLE_DMABUF_RENDERER=1`
    - (evt) `GDK_BACKEND=x11`

### 4) TypeScript config warning (Vite: missing base tsconfig)

- [ ] **`@codelayer/typescript-config/base.json` ontbreekt oplossen**
  - Doel: geen Vite warning meer en consistente TS config.
  - Done: root `tsconfig.json` verwijst niet meer naar een ontbrekend bestand (fallback tsconfig of workspace package), en relevante checks/builds draaien clean.

### 5) PR #913 (optioneel) extra smoke/build targets

- [x] **Linux build targets uit #913 testen**
  - Run:
    - `make humanlayer-binary-linux-x64`
    - `make codelayer-bundle-linux`
  - AppImage bundling (linuxdeploy): **OK**
    - Artifact:
      - `humanlayer-pr913/humanlayer-wui/src-tauri/target/release/bundle/appimage/CodeLayer-Nightly-x86_64.AppImage`
      - sha256: `d144276827c87a9e292a66371410266b1d6800121b90c61f0b3a2aa76b7d19bf`
    - `.deb` output: **niet aangemaakt** (geen `.../bundle/deb/` directory)
  - Workarounds gebruikt:
    - `NO_STRIP=1` (anders linuxdeploy/strip faalt op `.relr.dyn`)
    - `APPIMAGE_EXTRACT_AND_RUN=1`
    - `ARCH=x86_64` (appimagetool klaagt anders over “more than one architectures”)
    - Bun sidecar (`humanlayer`) corrupt na RPATH patch: patchelf-wrapper in extracted linuxdeploy om `--set-rpath` voor die binary te skippen
    - gtk plugin reruns: `ln -sf` i.p.v. `ln -s` in `~/.cache/tauri/linuxdeploy-plugin-gtk.sh`
  - Done: resultaten (succes/failure + logs) gepost als feedback op PR #913.
