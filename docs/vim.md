# Vim

## Installing ctags

Ctags is a tool that makes easier to navigate through the code.

### Installation:

```
sudo apt-get install exuberant-ctags
```

### Usage

First we need to index the source code. Execute the following instruction from your project's directory.

```
ctags -R .
```

Once the index is created, vim loads the tag information automatically. Use the following combinations to move around:

* `C-]`: Go to definition.
* `C-t`: Go back from definition.
* `C-\`: Open definition in a new tab.
