## GitHub Actions Usage

This repository provides GitHub Actions for managing Solana program deployments and verification.
It is highly recommended to use the squads integration for program deployments.

> **Repository location:** This repo lives at [`solana-foundation/github-actions`](https://github.com/solana-foundation/github-actions). If you still reference `solana-developers/github-actions` in a workflow, update the `uses:` path to `solana-foundation/github-actions` (tags and commit SHAs stay the same). GitHub redirects the old URL after a transfer, but explicit updates are recommended.

### Features

- ✅ Automated program builds
- ✅ Program verification against source code
- ✅ IDL buffer creation and uploads
- ✅ Squads multisig integration
- ✅ Program deploys for both devnet and mainnet
- ✅ Compute budget optimization
- ✅ Retry mechanisms for RPC failures
- ✅ Program Metadata IDL uploads (alternative to Anchor IDL)

### How to use

The easiest way to use the github actions is using one of the [reusable workflows](https://github.com/solana-foundation/github-workflows).
You can also follow this [Video Walkthrough](https://youtu.be/h-ngRgWW_IM)

There are three examples:

- [Anchor Program](https://github.com/Woody4618/anchor-github-action-example)
- [Native Program](https://github.com/Woody4618/native-solana-github-action-example)
- [Anchor Program using Squads](https://github.com/Woody4618/workflow-tutorial)

### Required Secrets for specific actions

Some of the actions of the build workflow require you to add secrets to your repository:

```bash
# Network RPC URLs
DEVNET_SOLANA_DEPLOY_URL=   # Your devnet RPC URL - Recommended to use a payed RPC url
MAINNET_SOLANA_DEPLOY_URL=  # Your mainnet RPC URL - Recommended to use a payed RPC url

# Deployment Keys
DEVNET_DEPLOYER_KEYPAIR=    # Base58 encoded keypair for devnet
MAINNET_DEPLOYER_KEYPAIR=   # Base58 encoded keypair for mainnet

PROGRAM_ADDRESS_KEYPAIR=    # Keypair of the program address - Needed for initial deploy and for native programs to find the program address. Can also be overwritten in the workflow if you dont have the keypair.

# For Squads integration
MAINNET_MULTISIG=          # Mainnet Squads multisig address
MAINNET_MULTISIG_VAULT=    # Mainnet Squads vault address
```

Customize the workflow to your needs!

## Key Actions

### Setup & Configuration

- `setup-all`: Comprehensive development environment setup

  - Installs and configures Solana CLI tools
  - Sets up Anchor framework (if needed)
  - Installs solana-verify for build verification
  - Configures Node.js environment
  - Handles caching for faster subsequent runs
  - Inputs:
    - `solana_version`: Solana version to install
    - `anchor_version`: Anchor version to install
    - `verify_version`: solana-verify version to install
    - `node_version`: Node.js version to install

- `extract-versions`: Automatically detects required versions
  - Extracts Solana version from Cargo.lock
  - Detects Anchor version from Anchor.toml or Cargo.lock
  - Provides fallback versions if not found
  - Outputs:
    - `solana_version`: Detected Solana version
    - `anchor_version`: Detected Anchor version

### Build & Verification

- `build-verified`: Builds program with verification support
  - Uses solana-verify for reproducible builds
  - Supports both native and Anchor programs
  - Handles feature flags and conditional compilation
  - Inputs:
    - `program`: Program name to build
    - `features`: Optional Cargo features to enable

### Cargo Publishing

- `cargo-publish`: Publishes one Rust crate to crates.io using Trusted Publishing
  - Uses GitHub OIDC and `rust-lang/crates-io-auth-action`
  - Runs `cargo publish --dry-run` before publishing
  - Optionally checks whether the crate version already exists on crates.io
  - Leaves checkout, tests, generated clients, tags, and GitHub releases to the caller workflow
  - Inputs:
    - `package`: Package name to publish, or empty to infer from the current package
    - `working-directory`: Directory containing the Cargo manifest or workspace
    - `toolchain`: Rust toolchain to install and use
    - `locked`: Pass `--locked` to `cargo publish`
    - `allow-dirty`: Pass `--allow-dirty` to `cargo publish` for generated files that are created during the workflow and are intentionally not checked into source control
    - `dry-run`: Validate without publishing to crates.io
    - `check-version-available`: Fail early when this crate version already exists on crates.io
    - `skip-existing`: Skip publishing successfully when this crate version already exists on crates.io
  - Outputs:
    - `package`: Published package name
    - `version`: Published package version
    - `published`: Whether the action published to crates.io
    - `already-published`: Whether this crate version already existed on crates.io

Caller workflows must grant OIDC token access and configure Trusted Publishing for the crate on crates.io. The Trusted Publisher configuration should match the caller repository and workflow file, not this shared action repository:

```yaml
permissions:
  contents: read
  id-token: write
```

Pin this action to a released tag or commit SHA instead of `main`.

Only set `allow-dirty: "true"` when a prior workflow step intentionally generated files that must be included in the crate but are not checked into source control.

Single crate:

```yaml
- uses: actions/checkout@v6

- name: Build package
  working-directory: path/to/package
  run: cargo build

- uses: solana-foundation/github-actions/cargo-publish@<release-tag-or-commit-sha>
  with:
    package: my-crate
    working-directory: path/to/package
```

Workspace package:

```yaml
- uses: actions/checkout@v6

- name: Build workspace
  working-directory: path/to/workspace
  run: cargo build --workspace

- uses: solana-foundation/github-actions/cargo-publish@<release-tag-or-commit-sha>
  with:
    package: my-workspace-crate
    working-directory: path/to/workspace
```

Generated client:

```yaml
- uses: actions/checkout@v6

- run: pnpm run generate-clients

- name: Build generated client
  working-directory: path/to/generated-crate
  run: cargo build

- uses: solana-foundation/github-actions/cargo-publish@<release-tag-or-commit-sha>
  with:
    package: my-generated-crate
    working-directory: path/to/generated-crate
    allow-dirty: "true"
    skip-existing: "true"
```

### NPM Publishing

- `npm-publish`: Publishes one TypeScript package to npm with pnpm using Trusted Publishing
  - Uses GitHub OIDC and npm provenance, with no `NODE_AUTH_TOKEN`
  - Packs and validates the tarball, then publishes the built package
  - Resolves the npm dist-tag automatically (`beta` for prerelease versions, otherwise `latest`)
  - Optionally checks whether the package version already exists on npm
  - Leaves checkout, install, build, tests, generated clients, tags, and GitHub releases to the caller workflow
  - Inputs:
    - `package`: Package name to publish, or empty to infer from the package manifest
    - `package-directory`: Directory containing the built package manifest to pack and publish
    - `node-version`: Node.js version to install
    - `pnpm-version`: pnpm version to install, or empty to use the `packageManager` field
    - `tag`: npm dist-tag to publish under, or empty to resolve automatically
    - `dry-run`: Validate without publishing to npm
    - `check-version-available`: Fail early when this package version already exists on npm
    - `skip-existing`: Skip publishing successfully when this package version already exists on npm
  - Outputs:
    - `package`: Published package name
    - `version`: Published package version
    - `tag`: npm dist-tag used for publishing
    - `published`: Whether the action published to npm
    - `already-published`: Whether this package version already existed on npm

Caller workflows must grant OIDC token access and configure Trusted Publishing for the package on npm. The Trusted Publisher configuration should match the caller repository and workflow file, not this shared action repository:

```yaml
permissions:
  contents: read
  id-token: write
```

Trusted Publishing requires npm 11.5.1 or newer. The action upgrades npm when the installed version is older, so `node-version: lts/*` works without a token.

Pin this action to a released tag or commit SHA instead of `main`.

The caller installs dependencies and builds the package before invoking the action.

Single package:

```yaml
- uses: actions/checkout@v6

- uses: pnpm/action-setup@v6

- run: pnpm install --frozen-lockfile

- name: Build package
  run: pnpm --filter "@scope/my-package" build

- uses: solana-foundation/github-actions/npm-publish@<release-tag-or-commit-sha>
  with:
    package: "@scope/my-package"
    package-directory: clients/typescript
```

Generated client:

```yaml
- uses: actions/checkout@v6

- uses: pnpm/action-setup@v6

- run: pnpm install --frozen-lockfile

- run: pnpm run generate-clients

- name: Build generated client
  run: pnpm --filter "@scope/my-client" build

- uses: solana-foundation/github-actions/npm-publish@<release-tag-or-commit-sha>
  with:
    package: "@scope/my-client"
    package-directory: clients/typescript
    skip-existing: "true"
```

### Deployment

- `write-program-buffer`: Writes a buffer that will then later be set either from the provided keypair or from the squads multisig

  - Creates buffer for program deployment
  - Set the buffer authority either to the provided keypair or to the squads multisig
  - Supports priority fees for faster transactions
  - Inputs:
    - `program-id`: Target program ID
    - `program`: Program name
    - `rpc-url`: Solana RPC endpoint
    - `keypair`: Deployer keypair
    - `buffer-authority-address`: Authority for the buffer
    - `priority-fee`: Transaction priority fee

- `prepare-squads-release`: Creates release buffers for a Squads-controlled upgrade without creating a Squads proposal from CI

  - Creates the program buffer
  - Transfers program buffer authority to the Squads vault
  - Optionally creates a program-metadata buffer and transfers its authority to the Squads vault
  - Optionally exports a `solana-verify` PDA transaction using the Squads vault as uploader
  - Does not require the deployer keypair to be a Squads member
  - Inputs:
    - `program-id`: Target program ID
    - `program`: Program name
    - `rpc-url`: Solana RPC endpoint
    - `keypair`: Payer keypair used for buffer preparation
    - `squads-vault`: Squads vault to set as buffer authority
    - `metadata-path`: Optional IDL or metadata JSON path
    - `priority-fee`: Transaction priority fee
    - `export-verify-pda`: Export a verify PDA transaction
    - `repo-url`: GitHub repository URL for the verify PDA transaction
    - `commit-hash`: Git commit hash for the verify PDA transaction

- `write-idl-buffer`: Writes an Anchor IDL buffer that will then later be set either from the provided keypair or from the squads multisig
  - Creates IDL buffer
  - Sets up IDL authority
  - Prepares for IDL updates
  - Inputs:
    - `program-id`: Program ID
    - `program`: Program name
    - `rpc-url`: Solana RPC endpoint
    - `keypair`: Deployer keypair
    - `idl-authority`: Authority for IDL updates

### Program Metadata (IDL Upload via program-metadata program)

These actions use the [program-metadata](https://github.com/solana-program/program-metadata) program to attach metadata (IDL, security.txt, etc.) to any Solana program. This is the newer alternative to Anchor's built-in IDL commands and supports any program, not just Anchor programs.

- `metadata-upload`: Writes metadata directly to a program or from a pre-created buffer

  - Supports any seed type (idl, security, or custom)
  - Handles both direct upload and Squads multisig workflows
  - Can export transactions for Squads signing
  - Inputs:
    - `program-id`: The program address
    - `idl-path`: Path to the metadata file (for direct upload)
    - `seed`: Metadata seed type (default: "idl")
    - `rpc-url`: Solana RPC endpoint
    - `keypair`: Deployer/authority keypair
    - `buffer`: Buffer address (for Squads workflow, instead of direct file upload)
    - `close-buffer`: Address to receive rent when closing buffer, or "true" for payer
    - `priority-fees`: Priority fees in micro-lamports (default: 100000)
    - `export`: Export transactions for multisig (provide vault address)
    - `export-encoding`: Encoding for exported transactions (default: base64)

- `write-metadata-buffer`: Creates a program-metadata buffer and transfers authority (for Squads multisig workflow)
  - Creates buffer with metadata content
  - Transfers buffer authority to the Squads vault
  - Outputs the buffer address for use in `metadata-upload`
  - Inputs:
    - `idl-path`: Path to the metadata file
    - `rpc-url`: Solana RPC endpoint
    - `keypair`: Keypair for buffer creation
    - `buffer-authority`: Address to set as buffer authority (e.g. Squads vault)
    - `priority-fees`: Priority fees in micro-lamports (default: 100000)
  - Outputs:
    - `buffer`: Created buffer address

### Additional Actions

- `build-anchor`: Specialized Anchor program builder
- `program-upgrade`: Handles the exteding of the program account in case the program is getting bigger and either sets the buffer or skips that in case of squads deploy
- `idl-upload`: Either sets the Anchor IDL buffer or skips that in case of squads deploy
- `verify-build`: Verifies on-chain programs match source using solana-verify andthe osec api

### Squads buffer-only release

For teams that do not want to add a CI-owned keypair as a Squads proposer, use `prepare-squads-release`. The keypair only pays for buffer preparation transactions. The resulting program buffer is owned by the Squads vault, and the upgrade proposal can be created manually in Squads.

Pin this action to a released tag or commit SHA instead of `main`.

```yaml
- name: Prepare Squads release buffers
  uses: solana-foundation/github-actions/prepare-squads-release@<release-tag-or-commit-sha>
  with:
    program: ${{ env.PROGRAM }}
    program-id: ${{ env.PROGRAM_ID }}
    rpc-url: ${{ env.RPC_URL }}
    keypair: ${{ secrets.MAINNET_DEPLOYER_KEYPAIR }}
    squads-vault: ${{ secrets.MAINNET_MULTISIG_VAULT }}
    metadata-path: ./target/idl/${{ env.PROGRAM }}.json
    priority-fee: ${{ inputs.priority-fee }}
    export-verify-pda: "true"
    repo-url: ${{ github.server_url }}/${{ github.repository }}
    commit-hash: ${{ github.sha }}
```

After the action completes, use the program buffer from the job summary when creating the program upgrade in Squads.

## 📝 Todo List

### Program Verification

- [x] Trigger verified build PDA upload
- [x] Verify build remote trigger
- [x] Support and test squads Verify
- [x] Support and test squads IDL
- [x] Support and test squads Program deploy

### Action Improvements

- [x] Separate IDL and Program buffer action
- [x] Remove deprecated cache functions
- [x] Remove node-version from anchor build
- [x] Skip anchor build when native program build
- [ ] Make verify build and anchor build in parallel
- [x] Trigger release build on tag push
- [x] Trigger devnet releases on develop branch?
- [x] Make solana verify also work locally using cat
- [x] Use keypairs to find deployer address to remove 2 secrets
- [x] Add priority fees
- [x] Add extend program if needed
- [x] Bundle the needed TS scripts with the .github actions for easier copy paste

### Testing & Integration

- [x] Add running tests
  - Research support for different test frameworks
- [x] Add program-metadata IDL upload support
- [ ] Add Codama support
- [ ] Add to solana helpers or mucho -> release
- [ ] Write guide and record video

# Close Buffer in case of failure

There may the occasions where the release flow fails in between writing the program buffer and the program deploy in squads.
In that case you may want to close a buffer that was already transferred authority to your multisig.
You can do that using the following command:

```bash
solana program show --buffers --buffer-authority <You multisig vault address>

npx ts-node scripts/squad-closebuffer.ts \
 --rpc "https://api.mainnet-beta.solana.com" \
 --multisig "FJviNjW3L2u2kR4TPxzUNpfe2ZjrULCRhQwWEu3LGzny" \
 --buffer "7SGJSG8aoZj39NeAkZvbUvsPDMRcUUrhRhPzgzKv7743" \
 --keypair ~/.config/solana/id.json \
 --program "BhV84MZrRnEvtWLdWMRJGJr1GbusxfVMHAwc3pq92g4z"
```

# Release v0.2.11

## Repository

- Move repository references from `solana-developers` to `solana-foundation`

## New Features

- `cu-benchmark`: posts PR comments with per-instruction compute-unit deltas vs a committed baseline
- `npm-publish`: publishes TypeScript packages to npm with pnpm using Trusted Publishing (OIDC, no `NODE_AUTH_TOKEN`)
- `cargo-publish`: publishes Rust crates to crates.io using Trusted Publishing
- `prepare-squads-release`: prepares program and metadata buffers with Squads vault authority, without creating a Squads proposal from CI

## Improvements

- Faster CLI installs in `setup-all` via `taiki-e/install-action`
- More resilient program buffer writes with partial resume, diagnostics, and configurable RPC/TPU transport
- Hardened `cargo-publish` and `npm-publish` validation and error handling

## Documentation

- Added README usage examples for publishing and Squads buffer-only releases
- Added `cu-benchmark` README with report contract and workflow example
- Added migration notice for the `solana-foundation` org move

# Release v0.2.7

## Pass library name to export pda tx

# Release v0.2.3

## Bug Fixes

- Fix extend program size check

# Release v0.2.2

## Bug Fixes

- Remove compute unit price from program extend

# Release v0.2.1

## Bug Fixes

- Fixed program size extraction in buffer write action

# Release v0.2.0

## Major Changes

- Combined setup actions into a single `setup-all` action
- Improved version management with override capabilities
- Added support for feature flags in builds and tests
- Enhanced caching strategy for faster builds

## New Features

- Added version override inputs:
  - `override-solana-version`
  - `override-anchor-version`
- Added feature flags support for tests
- Added toml-cli caching
- Improved error handling in buffer management

## Breaking Changes

- Removed individual setup actions in favor of `setup-all`
- Changed input parameter naming convention (using underscores instead of hyphens)
- Simplified build-verified action inputs

## Bug Fixes

- Fixed version extraction logic
- Fixed cache key generation
- Fixed buffer authority handling

## Documentation

- Updated README with detailed action descriptions
- Added comprehensive input/output documentation
- Added buffer cleanup instructions
