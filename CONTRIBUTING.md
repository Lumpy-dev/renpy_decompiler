# Contributing to the project

## Requirements
You must:
- Respect the [Code of Conduct](CODE_OF_CONDUCT.md)

## How to contribute
You can:
- Report issues in the "Issues" tab
- Write code to address issues and submit pull requests
- Suggest enhancements and talk about the project (i.e. in the discussion tab)

### How to get started
First you need to fork the repository **if you want to contribute code**.
Then you can clone the repository to your local machine:
```bash
git clone https://github.com/Lumpy-dev/renpy_decompiler.git
```
If you want to clone your fork, run:
```bash
git clone https://github.com/<username>/renpy_decompiler.git
```

We use IntelliJ IDEA to develop the project, we already have run configurations for the project for this IDE.
You can use VSCode or other IDEs, but you'll have to create your own run configurations.

On IntelliJ, select the adequate run configuration and run it. (i.e. Use "Run GUI" to run the GUI)

There are three modules in the project:
- `renpy_decompiler_gui`: A Flutter app that provides a GUI for all the backend
- `renpy_decompiler_backend`: A simple Dart package and a Command Line Application to decompile Ren'Py files
- `pickle_decompiler`: A Dart port of the Python pickle decompiler