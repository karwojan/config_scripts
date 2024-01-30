execute "py3file " . expand("<sfile>:p:r") . ".py"
command -range -nargs=1 AIAdd python3 prompt("python", "<args>", <range>, False)
command -range -nargs=1 AIReplace python3 prompt("python", "<args>", <range>, True)
