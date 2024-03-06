# Audio File Randomizer

Randomizes audio files in a given directory.

This script uses Ruby and `ffmpeg` to generate new, renamed audio files. It
also creates a text file that reveals how the files were renamed.

## How to use

1. Create a new directory and put your files in it. Any folders in this
   directory will be ignored, and any files in it will be treated as audio
   files.
2. Call the script, passing the directory as an argument.
```
$ ./randomize.rb "$HOME/Desktop/audio_files"
```
3. The script output will be placed in a subfolder. Rerunning the script will
   create a new subfolder to avoid clobbering previous output.

### Added silence

If, like me, you're using this script to create audio files which will be used
in a blind shoot-out, you'll want to ensure the duration of each file doesn't
defeat your randomization efforts. By default, new files will have a random
amount of silence between 5-10 seconds added to the beginning.

To alter this behavior, pass a second argument to the script in this format:
`<min seconds of silence> <max seconds of silence>`. Make sure to quote this.

For example, to randomly add between 30 and 60 seconds of silence:

```
$ ./randomize.rb "$HOME/Desktop/audio_files" "30 60"
```

To disable this behavior entirely, pass a second argument of `0`. For example:

```
$ ./randomize.rb "$HOME/Desktop/audio_files" "0"
```

### Customize output file name

By default, output files will be named `file_1.wav`, `file_2.wav`, etc. To
change the prefix, pass a third argument with your custom prefix string, such
as:

```
$ ./randomize.rb "$HOME/Desktop/audio_files" "5 10" "master"
```

The result will be files named `master_1.wav`, `master_2.wav`, and so on. Note
that this requires a second argument to be provided. To use the default behavior,
pass the string "5 10".
