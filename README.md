# randbg

my shell script for random backrounds<br>
requires: `feh`, `/bin/sh`<br>

## usage
```
-help              - print this screen
-file path_to_file - use a given file instead of randomly picking from a directory
-dir path_to_dir   - use a given directory instead of the value of BG_DIR
whatever_argument  - use the argument as a wildcard, the wildcard will be *whatever_argument* and the last such argument will be used as the wildcard
```

### old version
```
randbg
randbg wildcard (implicit * at the edges i.e. aa = *aa*)
randbg -file relative_path_to_some_file
randbg -dir relative_path_to_some_folder_to_search
randbg -dir relative_path_to_some_folder_to_search wildcard
```

the script searches for all files in a specified directory, `BG_DIR` or `-dir foo`, then calls
`feh` to set the background

the script also checks if the file ends in png/jpg/gif/svg. i mainly use png but jpg and gif are
also pretty common, and i added svg in case youre that guy

## license

read `LICENSE`, but in short:
if you run this script the you agree that i am not responsible for anything it does (you can read,
you can use shells, you can read shell scripts) and you can do whatever with the script as anyone
could have written this but credit is appreciated
