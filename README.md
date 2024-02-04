# nvim-sak

A simple-ish wrapper around sed to approximate select mode from
helix/kakoune


I wanted something like what kakoune has for multi cursor. It's neat. 
I want to mostly do text entry with this. Other plugins that provide multi cursor that I have tried
are either slow or are too much mental overhead to use properly. It's not that
they are bad though. This feels vim-like to me that I don't even need to think
about it.

It goes like this: in motion -> highlight pattern -> replace/accumulate/paste/rotate

## How it works

This plugin is a interactive wrapper around sed, with some limitations.
Currently provides 5 functions:
``` vim
<Plug>NvimSakHihglightInMotion 
<Plug>NvimSakInteractiveReplace 
<Plug>NvimSakAccumulate
<Plug>NvimSakInterleave
<Plug>NvimSakRotate
```
Main ones being
``` vim
<Plug>NvimSakHihglightInMotion
<Plug>NvimSakInteractiveReplace
```
They couple nicely with each other but they are not necessarily needed to be
used together. It uses visual marks and the contents of the search register.
NvimSakHihglightInMotion is just an easy way to set a region and to set a
pattern. While replace works with visual marks, and they can be set by anything.
Same for the pattern.

While it would probably just be easier just to make a mapping like ```
:'<,'>s///g``` and it would get you most of the way there, it's not as nicely
behaved. For example ```'<``` takes the **line** of the mark, and in parrtial 
line visual selection, whatever you do may have unwanted
effects. ``` `< ``` is the mark that has has both line and column, but doesn't really work with sed, for some reason.

 - <Plug>NvimSakHihglightInMotion
   
   When given a motion after, it creates an interactive prompt. The entered text
   gets highlighted as you write, it can also be a pattern. I have added a
   completion menu for some common patterns, and it also includes the current
   contents of the / register with ```\<``` and ```\>``` around it. A single tab
   would just add a ```\w\+``` to the pattern. On enter the pattern is put into
   the register and will highlight whatever matches it in the current visual
   selection(which would be the endings of the motion. ex: ```i"```,```ib```, ```a{``` ).

   This doesnt really play nice with ```ignorecase``` and ```smartcase```.  But
   if ```ignorecase``` is present the apropriate pattern is added to the front
   of the string. Add ```\C``` to the front. That is present to the list of
   completions so it's easy to do.

 - <Plug>NvimSakInteractiveReplace
   
   It provides a prompt wuth a default value of '\0'. That would leave the text
   unchanged. Delete it and t will delete all occurrences of whatever is in the
   search register from whatever is surrounded by the visual marks. It functions
   like a sed command. It is also interactive.On enter confirms the operation.
   On ```<Esc>``` it cancels the operation. If you delete the '\0' and incited the
   pattern starts with @ it will be interpreted as a ```:'<'>g/{pattern}/:norm
   {your_input_here}``` this is situationally useful.

 - <Plug>NvimSakAccumulate
   
   Works with the same assumptions as VsmInteractiveReplace - visually selected
   place and pattern in ```/```. It collects every occurrence of the pattern in the
   ```+``` register, each on a new line. Not as useful if using just a plain text
   pattern, but if using a regex-pattern is more it's usecase. 

 - <Plug>NvimSakInterleave
   
   Works with the same assumptions as VsmInteractiveReplace - visually selected
   place and pattern in ```/```. It is the inverse (kind of) of NvimSakAccumulate.
   For every occurrence of pattern in the visual selection it a line from the ```+```
   register. If the lines end, it goes through them again until all matches are
   exhausted. With one line in the ```+``` register it's just replace paste, with
   more it can be quite useful. Ex: take all the patterns from a selection edit
   them on the side, then return them to their places.

 - <Plug>NvimSakRotate
   
   Works with the same assumptions as VsmInteractiveReplace - visually selected
   place and pattern in /. Rotates the order of each pattern in a visual selection.
   Ex: (this, other,else) -> (else, this,other), or just general chaos.

- Tbd
  
  There are some other useful ones, that I haven't had the time to implement or
  haven't thought of .

## Demo
 - NvimSakHihglightInMotion + NvimSakInteractiveReplace 
![](demos/demo_highandrepl.webm)
 - NvimSakAccumulate + NvimSakInterleave 
![](demos/demo_accinterlave.webm)
 - NvimSakRotate pt1
![](demos/demo_swap1.webm)
 - NvimSakRotate pt2
![](demos/demo_swap2.webm)

## Some caveats
While achieving my goals for editing they are still powered by sed, so all of
its limitations follow, and how it behaves could depend on your configuration.

Also it is inefficient in it's implementation, the indented use case is small
files and small changes. Otherwise I think it will cause too many updates. Still
haven't had any problems. For anything big, better straight use sed. This thing
is kind of for the middle ground. Edit too little worth a sed but too big to be
one edit.

By default it uses mark `z` and register `z` during normal operation.

## Some of my example uses
### NvimSakHihglightInMotion
- highlight ls the occurrences of a pattern in a textobject, and also jump
  between them afterwards. This can be function, block, sentence, end of the line, etc.

### NvimSakAccumulate
- This collects all the matches in the selection and puts them separated by a
  new line in the '+' register
- Not as useful if using just a plain text pattern, but if using a regex is
  quite useful

### NvimSakInteractiveReplace
- Split a line on a certain symbol/s. This is kinda tricky to do with sed
  sometimes, especially if on the same line and with visual mode patterns.
- Add/remove/prepend/append to pattern.
- Refactoring a variable.
- Execute a :g norm command on lines with the match. - If the replace pattern
  begins with @, it will be interpreted as the arguments to a :g norm command

## Setup
There isn't much for setup. Install with plugin manager of choice.

``` vim
Plug 'rdpopov/nvim-sak'
```

And these are the keymaps I use.

Lua:

``` lua
keymap('n','s', '<Plug>NvimSakHihglightInMotion',{noremap = true, silent = true, desc="Highlight in current motion"})
keymap('n','<Leader>r', '<Plug>NvimSakInteractiveReplace',{noremap = true, silent = true, desc="Replace in visuial selection"})
keymap('n','<Leader>c', '<Plug>NvimSakAccumulate',{noremap = true, desc="Accumilate strings matching the pattern in visal selection"})
keymap('n','<Leader>i', '<Plug>NvimSakInterleave',{noremap = true, desc="Repace pattern in selection with strings from + registe"})
keymap('n','<Leader>s', '<Plug>NvimSakRotate',{noremap = true, desc="Rotatates the places of the selected pattern in visual selection"})
```

Other useful remaps that combo very well with this plugin:

``` lua
keymap('n',',/', ':nohlsearch<CR>',{noremap = true, silent = true ,desc="Turn temporarily searching highlight off"})
keymap('x','<leader><leader>', ":normal ",{noremap = true, desc="Execute normal mode command over visual selecetion"})
keymap('n','Q', '@q',{noremap = true, silent = true,desc = "Shorthand for executing register q"})
```

## Why this is a thing?
Tried kak and helix, liked this mode. And I would consider switching to them
just for this, it's quite handy. But everything else is different. Helix has no
plugins/scripting, though the base package is good. Kakoune can be scripted with
bash, and hwo it interfaces with basic tools is nice, but otherwise also
esoteric. This kinda gives me the main thing that I liked them for. It doesn't
doesn't have the transformations that can be done with kakoune, I might add some
if they become useful.
