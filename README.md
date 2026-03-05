# DankMaterialShell FocusedApp widget remake

A slightly modified version of the FocusedApp widget that comes with DMS.

This version mixes some capabilities of the AppsDock widget in order to add the icon of the active
program and a right-click popup with actions.

Although it doesn't have all the features of both the FocusedApp nor the AppsDock because I just
picked what I wanted from both.

I've also changed the space between the bar and the popup/tooltip so it's consistent with other
widgets, and made it so middle-clicking closes the window.

[DMS plugin development quick start.](https://danklinux.com/docs/dankmaterialshell/plugin-development#quick-start)

## [Development environment](https://danklinux.com/docs/dankmaterialshell/plugin-development#development-environment)

For full IDE support, I need to clone the DankMaterialShell repo, move (or symlink) this repo into
it, and edit this repo inside the DMS repo.

```bash
# Clone repo
git clone https://github.com/AvengeMedia/DankMaterialShell.git

# Generate QML language server config
touch .qmlls.ini
qs -p .  # Press Ctrl+C after it starts

# Symlink this repo into the DMS repo
mkdir <DMS repo path>/quickshell/dms-plugins
ln -sf $(pwd) <DMS repo path>/quickshell/dms-plugins/focusedapp-remake

# Move into the DMS repo
cd <DMS repo path>/quickshell
```

The DMS .gitignore contains `quickshell/dms-plugins` so the files won't show on FzfLua/fd without
removing that.

To test the widget on your live environment, symlink it to the plugins path and reload it. Popups
may not update without restarting DMS.

```bash
# Symlink
ln -sf $(pwd) ~/.config/DankMaterialShell/plugins/focusedapp-remake

# Reload plugin
dms ipc call plugins reload FocusedApp-remake

# List all plugins
dms ipc call plugins list
```

You can also manually run DMS to see the console output. Although it doesn't output log messages,
only info (`console.info()`) and above.
