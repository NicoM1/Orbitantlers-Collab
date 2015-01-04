#GAME-MODE
| ACTION/KEY          | RESULT              |
|:--------------------|---------------------|
| `Tab`               | Enter: **EDIT-MODE**|
#EDIT-MODE
| ACTION/KEY          | RESULT                |
|:--------------------|-----------------------|
| `Tab`               | Enter: **GAME-MODE**  |
| `v`                 | Enter: **VISUAL-MODE**|
| `LMB`               | Select Collider       |
| Drag Selected Col.  | Move Collider         |
| Drag Btm. Right     | Scale Collider        |
| Hold `q` + `LMB`    | Select/Des. Multiple  |
| `LMB` Outside       | Deselect All          |
| `x`                 | Delete Selected       |
#VISUAL-MODE
**(every action must be done while holding down a white circle.)**
(other than changing modes or brushes.)

| ACTION/KEY          | RESULT              |
|:--------------------|---------------------|
| `Tab`               | Enter: **GAME-MODE**|
| `v`                 | Enter: **EDIT-MODE**|
| Drag Circle         | Move Visual         |
| `, (<)`             | Decrease Depth      |
| `. (<)`             | Increase Depth      |
| `UP`                | Cycle Brush         |
| `DOWN`              | Cycle Brush         |
| `x`                 | Delete Pressed Vis. |
| `[`                 | Flip Horizontally   |
| `]`                 | Flip Vertically     |
| `o`                 | Rotate Left         |
| `p`                 | Rotate Right        |

#SAVE/LOAD

##DESKTOP:
`s` to save to: `bin/target/assets/files/output.lvl`
**back this up, files overwrite and are not numbered currently!**
Loading is only done at startup, where the output.lvl file is used (will get overwritten on rebuild I believe, copy levels to working directory!!!!!!!)

##WEV:
`s` to save (prompts to copy)
`l` to load (prompts to paste)
