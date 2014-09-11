set tabstop=2
set shiftwidth=2
set expandtab

" load a buffer when the file changes
set autoread

autocmd FileType php
  \ setlocal shiftwidth=4 |
  \ setlocal tabstop=4

set number

set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim

au BufNewFile,BufRead *.test,*.install set filetype=php
au BufNewFile,BufRead *.twig set filetype=html
au BufNewFile,BufRead *.hbs set filetype=html


call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'

" The following are examples of different formats supported.
" Keep Plugin commands between vundle#begin/end.
" plugin on GitHub repo
"Plugin 'tpope/vim-fugitive'
" plugin from http://vim-scripts.org/vim/scripts.html
" Git plugin not hosted on GitHub
"Plugin 'git://git.wincent.com/command-t.git'
" git repos on your local machine (i.e. when working on your own plugin)
"Plugin 'file:///home/gmarik/path/to/plugin'
" The sparkup vim script is in a subdirectory of this repo called vim.
" Pass the path to set the runtimepath properly.
"Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
" Avoid a name conflict with L9
"Plugin 'user/L9', {'name': 'newL9'}

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line
"
"
Bundle 'L9'
Bundle 'FuzzyFinder'
Bundle 'EasyGrep'
Bundle "CSApprox"
Bundle 'scrooloose/nerdtree'
" tabs for autocompleting
Bundle "supertab"

map <C-s-p> :FufCoverageFile<CR>
map <C-n> :NERDTreeToggle<CR>

" disable cursor keys in normal mode
map <Left>  :echo "no!"<cr>
map <Right> :echo "no!"<cr>
map <Up>    :echo "no!"<cr>
map <Down>  :echo "no!"<cr>

" disable cursor keys in insert mode
imap <Left> <NOP>
imap <Right> <NOP>
imap <Up> <NOP>
imap <Down> <NOP>

map <C-h> :tabprevious<CR>
map <C-l> :tabnext<CR>
nnoremap <silent> <A-Left> :execute 'silent! tabmove ' . (tabpagenr()-2)<CR>
nnoremap <silent> <A-Right> :execute 'silent! tabmove ' . tabpagenr()<CR>

set t_Co=256
colorscheme desert 

let @t = "O/**@test/vkk=jjj@f"
let @f = "Opublic function (){}?(i"
let @c = "Oclass {}? a"
