" ##############################################################################
"
"                           GENERAL CONFIGURATION
"
" ##############################################################################

" Allow per-directory vimrc files
set exrc

" Prevent unsafe commands in these local vimrc files
set secure


" Set leader to comma
let mapleader = ","

" Add a final newline at the end of file when saving
set fixendofline

" Trailing whitespace is trimmed on save by ALE (see g:ale_fixers '*')

" show existing tab with 2 spaces width
set tabstop=2

" when indenting with '>', use 2 spaces width
set shiftwidth=2

" On pressing tab, insert 2 spaces
set expandtab

" Open a terminal in a new window in the same directory as the current file
map <F6> :let $VIM_DIR=expand('%:p:h')<CR>:terminal<CR>cd $VIM_DIR<CR>

" Show a delimiter for the column at 120 characters
set colorcolumn=120

" Show line numbers
set number

" Highlight the current line (easier to spot the cursor)
set cursorline

" Bigger pattern-match memory limit (avoids 'maxmempattern exceeded')
set maxmempattern=2000000


" ##############################################################################
"
"                           PLUGIN CONFIGURATION
"
" ##############################################################################

syntax on

" Enables filetype-specific plugins.
filetype plugin indent on

" gruvbox (256-color, ok in Terminal.app). silent! in case it's not installed yet
set background=dark
silent! colorscheme gruvbox

" Auto-select the regexp engine (0 = auto, not "new"; new engine is re=2)
set re=0


" ==============================================================================
"                              LSP SERVER INSTALLATION
" ==============================================================================

" Function to run when an LSP server is attached to the current buffer
function! s:on_lsp_buffer_enabled() abort
    " Enable LSP-powered completion for this buffer
    setlocal omnifunc=lsp#complete

    " Always show the sign column (gutter) so diagnostics don't shift text
    setlocal signcolumn=yes

    " Use LSP as the tag provider if Vim supports 'tagfunc'
    if exists('+tagfunc') | setlocal tagfunc=lsp#tagfunc | endif

    " ---------- LSP navigation mappings ----------
    " NOTE: no trailing comment after :map, the '"' becomes part of the mapping
    " Go to definition
    nmap <buffer> gd <plug>(lsp-definition)
    " Search symbols in this file
    nmap <buffer> gs <plug>(lsp-document-symbol-search)
    " Search symbols in workspace
    nmap <buffer> gS <plug>(lsp-workspace-symbol-search)
    " Find references
    nmap <buffer> gr <plug>(lsp-references)
    " Go to implementation
    nmap <buffer> gi <plug>(lsp-implementation)
    " Go to type definition
    nmap <buffer> gt <plug>(lsp-type-definition)

    " ---------- LSP actions ----------
    " Rename symbol
    nmap <buffer> <leader>rn <plug>(lsp-rename)
    " Jump to previous diagnostic
    nmap <buffer> [g <plug>(lsp-previous-diagnostic)
    " Jump to next diagnostic
    nmap <buffer> ]g <plug>(lsp-next-diagnostic)
    " Open the diagnostics list
    nmap <buffer> <leader>e <plug>(lsp-document-diagnostics)
    " Show hover documentation
    nmap <buffer> K <plug>(lsp-hover)

    " ---------- Scrolling in hover/docs popups ----------
    " Scroll down in popup
    nnoremap <buffer> <expr> <c-f> lsp#scroll(+4)
    " Scroll up in popup
    nnoremap <buffer> <expr> <c-d> lsp#scroll(-4)

    " ---------- Formatting ----------
    " Format Rust/Go via LSP before saving. Buffer-local so it only attaches to
    " files that have an LSP (TS is handled by ALE). Add filetypes here if needed.
    if &filetype ==# 'rust' || &filetype ==# 'go'
        autocmd! BufWritePre <buffer> call execute('LspDocumentFormatSync')
    endif

    " More commands can be added here as needed (check vim-lsp docs)
endfunction

" Autocommand group to run LSP setup only when relevant
augroup lsp_install
    au!
    " When LSP is enabled for a buffer, call our setup function
    autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
augroup END

" Format timeout (ms)
let g:lsp_format_sync_timeout = 1000

" ============ LSP configuration by file type ===========
"
" TYPESCRIPT
let g:lsp_settings_filetype_javascript = ['typescript-language-server']
let g:lsp_settings_filetype_javascriptreact = ['typescript-language-server']
let g:lsp_settings_filetype_typescript = ['typescript-language-server']

" RUST
let g:lsp_settings_filetype_rust = ['rust-analyzer']
let g:lsp_settings = {
\ 'rust-analyzer': {
\   'initialization_options': {
\     'checkOnSave': v:true,
\     'diagnostics': v:true,
\   },
\ }
\}

" for monorepo... doesn't work well currently
let g:lsp_experimental_workspace_folders = 1


" ============ LSP diagnostics display ===========
" full error on virtual lines above the code, wrapped
let g:lsp_diagnostics_virtual_text_enabled = 1
let g:lsp_diagnostics_virtual_text_align = 'above'
let g:lsp_diagnostics_virtual_text_wrap = 'wrap'
let g:lsp_diagnostics_virtual_text_padding_left = 4
" and a float when the cursor is on the line
let g:lsp_diagnostics_float_cursor = 1
let g:lsp_diagnostics_echo_cursor = 0
set updatetime=500
" hover in a float, not a preview split
let g:lsp_hover_ui = 'float'
let g:lsp_float_max_width = 100
let g:lsp_preview_max_width = 100
let g:lsp_preview_max_height = 30
" wrap long messages in the location list
autocmd FileType qf setlocal wrap


" ================================================================================
"                               LSP AUTOCOMPLETE
" ================================================================================
"
" see https://github.com/prabirshrestha/asyncomplete.vim for mor configuration
"

" Disable automatic popup of completion menu.
let g:asyncomplete_auto_popup = 0

" Function to check if the character before the cursor is whitespace or start of line.
" Used to decide if <TAB> should insert a tab or trigger completion navigation.
function! s:check_back_space() abort
    let col = col('.') - 1
    return !col || getline('.')[col - 1]  =~ '\s'
endfunction

" Map <TAB> in insert mode with expression mapping
" If popup menu visible, select next item
" Else if before cursor is space/start of line, insert a tab
" Otherwise, trigger asynchronous completion refresh
inoremap <silent><expr> <TAB>
  \ pumvisible() ? "\<C-n>" :
  \ <SID>check_back_space() ? "\<TAB>" :
  \ asyncomplete#force_refresh()

" Map <S-TAB> (Shift+Tab) in insert mode with expression mapping
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

" allow modifying the completeopt variable, or it will
" be overridden all the time
let g:asyncomplete_auto_completeopt = 0

set completeopt=menuone,noinsert,noselect,preview

" To auto close preview window when completion is done.
autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif


" ================================================================================
"                                     FZF
" ================================================================================
"
"
" =============================== Installation ===================================
"
"
" Dependencies and Optional Tools:
" - fzf 0.54.0 or above              : Required base version.
" - bat                              : For syntax-highlighted preview support.
" - delta                            : If available, used by GF?, Commits, and BCommits to format git diff output.
" - ag (The Silver Searcher)         : Required for the Ag command.
" - rg (ripgrep)                     : Required for the Rg command.
" - Perl                             : Needed for Tags and Helptags commands.
" - readtags (Universal Ctags)       : Required for Tags PREFIX functionality.
"
" See https://github.com/junegunn/fzf.vim?tab=readme-ov-file#dependencies for
" more information

" We installed fzf using homebrew. In Mac chip, this is the path
" We could have installed the fzf repo directly in VIM. But fzf can be useful
" in terminal as well!
" See https://github.com/junegunn/fzf.vim/issues/1102 for details

" Use fzf in Vim (Mac)
if isdirectory('/usr/local/opt/fzf') " Homebrew
  set rtp+=/usr/local/opt/fzf
elseif isdirectory('/opt/homebrew/opt/fzf') " Homebrew on Apple Silicon
  set rtp+=/opt/homebrew/opt/fzf
end


" =============================== Configuration ===================================

" Initialize configuration dictionary
let g:fzf_vim = {}

" [Buffers] Jump to the existing window if possible (default: 0)
let g:fzf_vim.buffers_jump = 1

" [Ag|Rg|RG] Display path on a separate line for narrow screens (default: 0)
" * Requires Perl and fzf 0.56.0 or later
" Set ONLY one value (before all 3 ran, so 2 always won):
"   0 = PATH:LINE:COL:LINE
"   1 = PATH:LINE:COL: / LINE on next line
"   2 = same as 1 + empty line between items (--gap)
let g:fzf_vim.grep_multi_line = 1

" [[B]Commits] Customize the options used by 'git log':
let g:fzf_vim.commits_log_options = '--graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr"'

" [Tags] Command to generate tags file
let g:fzf_vim.tags_command = 'ctags -R'

" [Commands] --expect expression for directly executing the command
let g:fzf_vim.commands_expect = 'alt-enter,ctrl-x'


" ================================ Shortcuts ===================================

" For these shortcut, we don't want to overwrite the NERDTREE Buffers. We
" switch to another window if NERDTree is open.
nnoremap <silent> <expr> <leader>f  (expand('%') =~ 'NERD_tree' ? "\<C-w>\<C-w>" : '') . ":Files<CR>"
nnoremap <silent> <expr> <leader>gF (expand('%') =~ 'NERD_tree' ? "\<C-w>\<C-w>" : '') . ":GFiles<CR>"
nnoremap <silent> <expr> <leader>b  (expand('%') =~ 'NERD_tree' ? "\<C-w>\<C-w>" : '') . ":Buffers<CR>"

" delete buffer but keep the window (go to previous, drop the alternate)
nnoremap <silent> <leader>d :bp <bar> bd #<CR>

" ================================================================================
"                                  LIGHTLINE
" ================================================================================

set laststatus=2
set noshowmode

" show [git]/[working] in the statusline, only when diffing
function! DiffSide() abort
  if !&diff | return '' | endif
  return bufname('%') =~# 'fugitive:\|/\.git/' ? '[git]' : '[working]'
endfunction

let g:lightline = {
\ 'colorscheme': 'gruvbox',
\ 'active': {
\   'left': [ ['mode', 'paste'], ['readonly', 'relativepath', 'modified'], ['diffside'] ]
\ },
\ 'component_function': {
\   'diffside': 'DiffSide'
\ }
\}


" ================================================================================
"                                  WHICH-KEY
" ================================================================================

" popup of <leader> maps after a pause
set timeoutlen=500
nnoremap <silent> <leader> :<c-u>WhichKey ','<CR>
vnoremap <silent> <leader> :<c-u>WhichKeyVisual ','<CR>


" ================================================================================
"                                    TABBY
" ================================================================================
" Lazy AI completion. `tabby-on` in a terminal to start the server, :TabbyOn in vim.
" <C-\> triggers, <C-l> accepts.
let g:tabby_trigger_mode = 'manual'
let g:tabby_keybinding_accept = '<C-l>'
let g:tabby_keybinding_trigger_or_dismiss = '<C-\>'
" set this if vim can't find node
"let g:tabby_node_binary = expand('~/.nvm/versions/node/v24.13.1/bin/node')
command! TabbyOn packadd vim-tabby

" copilot gone, disable it in case the dir is still around
let g:copilot_filetypes = { '*': v:false }


" ================================================================================
"                                   NERDTREE
" ================================================================================

" Exit Vim if NERDTree is the only window remaining in the only tab.
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | call feedkeys(":quit\<CR>:\<BS>") | endif

" Close the tab if NERDTree is the only window remaining in it.
autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | call feedkeys(":quit\<CR>:\<BS>") | endif

" If another buffer tries to replace NERDTree, put it in the other window, and bring back NERDTree.
autocmd BufEnter * if winnr() == winnr('h') && bufname('#') =~ 'NERD_tree_\d\+' && bufname('%') !~ 'NERD_tree_\d\+' && winnr('$') > 1 |
    \ let buf=bufnr() | buffer# | execute "normal! \<C-W>w" | execute 'buffer'.buf | endif

nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap <C-e> :NERDTreeFind<CR>


" ================================================================================
"                                  ALE
" ================================================================================

" Disable ALE's LSP support, we use vim-lsp instead
let g:ale_disable_lsp = 1

" no ALE linting for rust, vim-lsp handles it
let g:ale_linters = { 'rust': [] }


let g:ale_fixers = {
\   '*': ['remove_trailing_lines', 'trim_whitespace'],
\   'typescript': ['prettier', 'eslint'],
\}

" fix on save
let g:ale_fix_on_save = 1


" ================================================================================
"                                   VIM-TEST
" ================================================================================

" Since this config is project specific, we will put it in a local vimrc
" We keep it here for reference, but it will not be loaded by default.
"
" specific runner for javascript
" let g:test#javascript#runner = 'jest'
"
" executable to run the tests for jest
" let test#javascript#jest#executable = 'npx jest'


" ================================================================================
"                                   ROOTER
" ================================================================================
" For dfns_test, we cannot really use vim-test since it's a monorepo...
" Rooter is a plugin that automatically changes the working directory to the
" project root when opening a file. It uses patterns to identify the root.
" Since it's only for the dfns monorepo, we will set the specific vim-test
" configuration is a local vimrc
let g:rooter_manual_only = 1
