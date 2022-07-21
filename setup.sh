mkdir -p ~/.vim/ftplugin
mkdir -p ~/.vim/autoload
mkdir -p ~/.config/i3
mkdir -p ~/.config/i3status

curl -fLo ~/.vim/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
ln -s `pwd`/i3_config ~/.config/i3/config
ln -s `pwd`/i3status_config ~/.config/i3status/config
ln -s `pwd`/Xresources ~/.Xresources 
cd ./vim
find ./ -type f -exec ln -s `pwd`/{} ~/.vim/{}  \;
