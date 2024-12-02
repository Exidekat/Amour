# Amour
AMOUR: A collection of build tools to automate platform distributions for LÖVE games.

## Installation

AMOUR can be installed as a git submodule in your existing LOVE project:

`$ git submodule add https://github.com/Exidekat/Amour.git`

Or if your project is not a git repository, a resursive clone will suffice:

`$ git clone --recurse-submodules https://github.com/Exidekat/Amour.git`

AMOUR expects your LOVE files to be in an adjacent "gamedata" directory.
Finished distributions will appear in the adjacent 'build' directory.
Both of these can be configured in AMOUR's `variables.sh` to the user's liking!
```
MyAwesomeLOVEProject
├── Amour
│   └── ...
├── build
│   └── ...
└── gamedata
    ├── scripts
    ├── ...
    ├── main.lua
    └── conf.lua
```
## Usage - Desktop Builds
Builds are extremely straight-forward! Bash/zsh users can execute builds directly from their Project's root directory:

```
$ cd MyAwesomeLOVEProject
$ ./Amour/bash/build.sh
```

Powershell scripts are also on the way!

## Usage - Mobile Builds
Android APK & AAB  
Make sure you have updated the appropriate Android Manifest data for your game!

```
$ cd MyAwesomeLOVEProject
$ ./Amour/bash/android-build.sh
```
iOS support coming soon!