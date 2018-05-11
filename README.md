# Beats

Beats is a simple ncurses based drum machine that serves as a demo for the [SchedEx](https://github.com/SchedEx/SchedEx)
library.

Beats is mostly a toy. Caveat Emptor etc etc.

## Usage

Beats makes use of the curses library to render a retro style console interface. Though it technically works with IEx, 
there are some rendering glitches that make it preferred to run a built release. 

To run beats: 

```
$ mix deps.get
$ mix release ; _build/dev/rel/beats/bin/beats foreground ; stty sane
```

beats watches the content of the `scores` folder and loads any saved score files at the end of the current measure. In 
addition to this interaction, the beats console application has the fopllowing key based commands:

* `1`-`0`: Play the corresponding beat from the current score
* `u`: Speed the BPM up
* `d`: Slow the BPM down
* `w`: Reduce the 16th swing
* `e`: Increase the 16th swing
* `<space>`: Toggle play / pause of the current score
* `s`: Toggle stats display between various modes
* `l`: Toggle live reldraw of the grid
* `r`: Rebuild the display
* `q`: Quit

# License

MIT

