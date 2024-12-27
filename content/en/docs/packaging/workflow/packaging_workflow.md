+++
title = 'Packing Workflow'
date = 2024-12-27T16:25:00Z
weight = 10
description = "Building and testing `stone.yaml` recipe build artifacts"
+++


Before the system can build recipes, a few prerequisites need to be installed and a new directory for storing build
artefacts needs to be set up.

## `build-essentials`

We maintain a `build-essentials` metapackage that should contain the basics for getting started with packaging on
Serpent OS.

```bash
sudo moss sync -u
sudo moss it build-essentials
```

## Understanding moss-format repositories

When building and testing packages locally, boulder (and moss) can be configured to consult a local moss-format repository
containting `.stone` build artifacts and a `stone.index` local repository index.

The index is what both moss and boulder consult when they check what packages are available to be installed into moss-maintained
system roots.

Every time a package is built, boulder calls out to moss to have it construct a pristine build root directory with the necessary
.stones installed.

The packages in this build root are resolved from one or more moss stone.index files, sorted in descending priority,
such that the highest priority repository "wins" when package providers are resolved.

The lowest priority repository will typically be the official Serpent OS upstream package repository.

If higher priority repositories are added, these will in turn override the official Serpent OS upstream package repository.

### Activating the Serpent OS helper scripts

The easiest way to create a local repo is to use the helper script distributed with the Serpent OS recipe repo in the /tools/ directory.

```bash
mkdir -pv repos/serpent-os/
pushd repos/serpent-os
git clone https://github.com/serpent-os/recipes
popd
ln -sv ~/repos/serpent-os/recipes/tools/helpers.sh ~/.bashrc.d/90-serpent-helpers.sh
```

### Creating a local repository

After the helper script has been activated in `bash`, open a new tab or a new terminal, and execute the following commands:

```bash
# create a new tab or open a new terminal
gotoserpentroot
just ls-local
```

The `just ls-local` invocation will set up an empty `~/.cache/local_repo/x86_64/` directory and create an empty `stone.index` file.

### Making boulder use the local repository

Boulder will need to have its list of "build profiles" be updated before it will consult the `~/.cache/local_repo/x86_64/stone.index`
moss-format repository index created above:

```bash
boulder profile list
boulder profile add --repo name=volatile,uri=https://packages.serpentos.com/volatile/x86_64/stone.index,priority=0 local-x86_64
boulder profile update --repo name=local,uri=file://${HOME}/.cache/local_repo/x86_64/stone.index,priority=100 local-x86_64
boulder profile list
```

### Making moss able to install packages from the local repository

Because boulder builds from the `volatile` repository (which users of Serpent OS should not be using un)

```bash
moss repo list
moss repo add volatile https://packages.serpentos.com/volatile/x86_64/stone.index -p 10
moss repo disable volatile 
moss repo add local file://${HOME}/.cache/local_repo/x86_64/stone.index -p 100
moss repo disable local
moss repo list
```

In the above priority tower, moss-format packages would first get resolved via the `local` repostory (priority 100),
then from the `volatile` reposistory (priority 10) and finally from the `unstable` repository (priority 0), the latter
of which is the official upstream Serpent OS moss-format .stone package repository.

Users of Serpent OS should generally not have the `volatile` repository be enabled, because this repository is where
new .stone packages land right after being built, which means the repository can potentially be in an undefined and
volatile state when building large build queues (hence the name).

However, when testing locally built packages, they _must_ be built against the local-x86_64 boulder build profile,
which in turns relies on the `volatile` repostiory via the boulder `local-x86_64` build profile.

Hence, when testing locally built packages, you may need to _**temporarily**_ enable the `volatile` repository for moss
to resolve from.

### Updating installed system state

Testing your packages is now as simple as:

- Enabling (or disabling) the relevant moss-format repositories with:
  `moss repo enable/disable <the repoistory>`
- Updating moss' view of the enabled moss-format repository indices with:
  `moss sync -u`

### Cleaning the local repository

Often, it will be prudent to clean out the local repository after the associated recipe PR has been accepted upstream.

```bash
gotoserpentroot
just clean-local
sudo moss repo disable volatile
sudo moss repo disable local
sudo moss sync -u 
```

This will sync the installed system state with the upstream `unstable` moss-format .stone package repository state.
