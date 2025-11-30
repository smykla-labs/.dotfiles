# Vim configuration
#
# Migrated from chezmoi Vundle-based setup to home-manager.
# Uses Nix plugin management instead of Vundle.
{ config, lib, pkgs, ... }:

{
  programs.vim = {
    enable = true;
    defaultEditor = true;

    plugins = with pkgs.vimPlugins; [
      # Status line
      vim-airline

      # Linting
      ale

      # Language support
      ansible-vim
      vim-go

      # Navigation/editing
      vim-argwrap
      vim-easymotion
      vim-easy-align
      nerdtree
      nerdcommenter
      tagbar

      # Search
      incsearch-vim

      # Visual
      awesome-vim-colorschemes
      rainbow
      vim-indent-guides

      # Utilities
      tabular
      vim-bracketed-paste
      # vim-HiLinkTrace not available in nixpkgs
    ];

    settings = {
      number = true;
      relativenumber = true;
      expandtab = true;
      tabstop = 4;
      shiftwidth = 4;
      background = "dark";
    };

    extraConfig = ''
      " Weird error message appeared without that
      " (https://github.com/vim/vim/issues/3117)
      if has('python3')
        silent! python3 1
      endif

      " Remap leader to comma
      let mapleader=","
      let maplocalleader=","

      " Terminal colors
      set t_Co=256

      " Colorscheme
      colorscheme molokai

      " Tab settings
      set softtabstop=4

      " Search highlighting
      set hlsearch

      " Column indicator
      set colorcolumn=80
      set textwidth=80

      " Shift-Tab to unindent
      nnoremap <S-Tab> <<
      inoremap <S-Tab> <C-d>

      " Backspace behavior
      set backspace=indent,eol,start

      " Clear highlight with //
      nmap // :noh<cr>
      vmap // :noh<cr>

      " Folding
      set foldenable
      set foldmethod=marker

      au FileType sh let g:sh_fold_enabled=5
      au FileType sh let g:is_bash=1
      au FileType sh set foldmethod=syntax

      " Syntax highlighting
      syntax enable

      " Jump to last position when reopening file
      if has("autocmd")
        au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
          \| exe "normal! g'\"" | endif
      endif

      " Don't jump in commit messages
      au FileType gitcommit au! BufEnter COMMIT_EDITMSG call setpos('.', [0, 1, 1, 0])

      " Remember folds
      augroup remember_folds
          autocmd!
          autocmd BufWinLeave * mkview
          autocmd BufWinEnter * silent! loadview
      augroup END

      " Quick edit/reload vimrc
      nnoremap <Leader>ve :e $MYVIMRC<CR>
      nnoremap <Leader>vr :source $MYVIMRC<CR>

      "
      " Plugin configurations
      "

      " Airline - powerline symbols
      if !exists('g:airline_symbols')
          let g:airline_symbols = {}
      endif
      let g:airline_left_sep = '''
      let g:airline_left_alt_sep = '''
      let g:airline_right_sep = '''
      let g:airline_right_alt_sep = '''
      let g:airline_symbols.branch = '''
      let g:airline_symbols.readonly = '''
      let g:airline_symbols.linenr = '☰'
      let g:airline_symbols.crypt = '🔒'
      let g:airline_symbols.maxlinenr = '㏑'
      let g:airline_symbols.paste = '∥'
      let g:airline_symbols.spell = 'Ꞩ'
      let g:airline_symbols.notexists = 'Ɇ'
      let g:airline_symbols.whitespace = 'Ξ'
      let g:airline_section_z = airline#section#create(["\uE0A1" . '%{line(".")}' . "\uE0A3" . '%{col(".")}'])

      " ALE - linting navigation
      nmap <silent> <C-k> <Plug>(ale_previous_wrap)
      nmap <silent> <C-j> <Plug>(ale_next_wrap)

      " ArgWrap
      nnoremap <Leader>a 0 f( l :ArgWrap<CR> ])
      let g:argwrap_tail_comma = 1

      " Colorscheme switcher
      if v:version >= 700 && !exists('loaded_switchcolor') && !&cp
        let loaded_switchcolor = 1
        let paths = split(globpath(&runtimepath, 'colors/*.vim'), "\n")
        let s:swcolors = map(paths, 'fnamemodify(v:val, ":t:r")')
        let s:swskip = ['256-jungle', '3dglasses', 'calmar256-light', 'coots-beauty-256', 'grb256']
        let s:swback = 0
        let s:swindex = 0

        function! SwitchColor(swinc)
          if (s:swback == 1)
            let s:swback = 0
            let s:swindex += a:swinc
            let i = s:swindex % len(s:swcolors)
            if (index(s:swskip, s:swcolors[i]) == -1)
              execute "colorscheme " . s:swcolors[i]
            else
              return SwitchColor(a:swinc)
            endif
          else
            let s:swback = 1
            if (&background == "light")
              execute "set background=dark"
            else
              execute "set background=light"
            endif
            if (!exists('g:colors_name'))
              return SwitchColor(a:swinc)
            endif
          endif
          redraw
          execute "colorscheme"
        endfunction
      endif

      " EasyAlign
      xmap ga <Plug>(EasyAlign)
      nmap ga <Plug>(EasyAlign)

      " EasyMotion
      map  <Leader>f <Plug>(easymotion-bd-f)
      nmap <Leader>f <Plug>(easymotion-overwin-f)
      nmap s <Plug>(easymotion-overwin-f2)
      map <Leader>L <Plug>(easymotion-bd-jk)
      nmap <Leader>L <Plug>(easymotion-overwin-line)
      map  <Leader>w <Plug>(easymotion-bd-w)
      nmap <Leader>w <Plug>(easymotion-overwin-w)

      " EasyMotion + incsearch
      map / <Plug>(incsearch-easymotion-/)
      map ? <Plug>(incsearch-easymotion-?)
      map g/ <Plug>(incsearch-easymotion-stay)

      " vim-go
      let g:go_highlight_functions = 1
      let g:go_highlight_methods = 1
      let g:go_highlight_structs = 1
      let g:go_highlight_operators = 1
      let g:go_highlight_build_constraints = 1
      map <Leader>l :cnext<CR>
      map <Leader>k :cprevious<CR>
      map <Leader>c :cclose<CR>
      let g:go_fmt_autosave = 0
      let g:go_metalinter_autosave = 1
      let g:go_doc_url = 'https://godoc.org'

      " NERDCommenter
      let g:NERDSpaceDelims = 1

      " NERDTree
      map <C-n> :NERDTreeToggle<CR>

      " Rainbow parentheses
      let g:rainbow_active = 1

      " Tabular
      nmap <Leader>t :Tab /\S\+$/l1<CR>
      vmap <Leader>t :Tab /\S\+$/l1<CR>

      " Tagbar
      nmap <F8> :TagbarToggle<CR>
      let g:tagbar_type_go = {
          \ 'ctagstype' : 'go',
          \ 'kinds'     : [
              \ 'p:package',
              \ 'i:imports:1',
              \ 'c:constants',
              \ 'v:variables',
              \ 't:types',
              \ 'n:interfaces',
              \ 'w:fields',
              \ 'e:embedded',
              \ 'm:methods',
              \ 'r:constructor',
              \ 'f:functions'
          \ ],
          \ 'sro' : '.',
          \ 'kind2scope' : {
              \ 't' : 'ctype',
              \ 'n' : 'ntype'
          \ },
          \ 'scope2kind' : {
              \ 'ctype' : 't',
              \ 'ntype' : 'n'
          \ },
          \ 'ctagsbin'  : 'gotags',
          \ 'ctagsargs' : '-sort -silent'
      \ }
    '';
  };
}
