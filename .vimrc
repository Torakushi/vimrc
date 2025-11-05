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
autocmd BufWritePre * if &fixendofline | endif

" Trim trailing whitespace on save
autocmd BufWritePre * %s/\s\+$//e

" show existing tab with 2 spaces width
set tabstop=2

" when indenting with '>', use 2 spaces width
set shiftwidth=2

" On pressing tab, insert 2 spaces
set expandtab

" Open a terminal in a new window in the same directory as the current file
map <F6> :let $VIM_DIR=expand('%:p:h')<CR>:terminal<CR>cd $VIM_DIR<CR>

" Show a delimiter for the column at 80 characters
:set colorcolumn=120

" Show line numbers
set number


" Vim diff colors
hi DiffAdd      ctermfg=NONE          ctermbg=Green
hi DiffChange   ctermfg=NONE          ctermbg=NONE
hi DiffDelete   ctermfg=LightBlue     ctermbg=Red
hi DiffText     ctermfg=Yellow        ctermbg=Red


" ##############################################################################
"
"                           PLUGIN CONFIGURATION
"
" ##############################################################################

syntax on

" Enables filetype-specific plugins.
filetype plugin indent on

" Use new regular expression engine
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
    nmap <buffer> gd <plug>(lsp-definition)              " Go to definition
    nmap <buffer> gs <plug>(lsp-document-symbol-search)  " Search symbols in this file
    nmap <buffer> gS <plug>(lsp-workspace-symbol-search) " Search symbols in workspace
    nmap <buffer> gr <plug>(lsp-references)              " Find references
    nmap <buffer> gi <plug>(lsp-implementation)          " Go to implementation
    nmap <buffer> gt <plug>(lsp-type-definition)         " Go to type definition

    " ---------- LSP actions ----------
    nmap <buffer> <leader>rn <plug>(lsp-rename)          " Rename symbol
    nmap <buffer> [g <plug>(lsp-previous-diagnostic)     " Jump to previous diagnostic
    nmap <buffer> ]g <plug>(lsp-next-diagnostic)         " Jump to next diagnostic
    nmap <buffer> K <plug>(lsp-hover)                    " Show hover documentation

    " ---------- Scrolling in hover/docs popups ----------
    nnoremap <buffer> <expr><c-f> lsp#scroll(+4)          " Scroll down in popup
    nnoremap <buffer> <expr><c-d> lsp#scroll(-4)          " Scroll up in popup

    " ---------- Formatting ----------
    let g:lsp_format_sync_timeout = 1000                  " Format timeout (ms)
    autocmd! BufWritePre *.rs,*.go call execute('LspDocumentFormatSync')
    " NOTE: Above formats Rust and Go before saving. Add *.py if needed.

    " More commands can be added here as needed (check vim-lsp docs)
endfunction

" Autocommand group to run LSP setup only when relevant
augroup lsp_install
    au!
    " When LSP is enabled for a buffer, call our setup function
    autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
augroup END

" ============ LSP configuration by file type ===========
"
" TYPESCRIPT
let g:lsp_settings_filetype_javascript = ['typescript-language-server']
let g:lsp_settings_filetype_javascriptreact = ['typescript-language-server']
let g:lsp_settings_filetype_typescript = ['typescript-language-server']

" RUST
let g:lsp_settings_filetype_rust = ['rust-analyzer', 'bacon-ls']
let g:lsp_settings = {
\ 'rust-analyzer': {
\   'initialization_options': {
\     'checkOnSave': v:false,
\     'diagnostics': v:false,
\   },
\ }
\}

" for monorepo... doesn't work well currently
let g:lsp_experimental_workspace_folders = 1


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
let g:fzf_vim.grep_multi_line = 0
   " PATH:LINE:COL:LINE
let g:fzf_vim.grep_multi_line = 1
   " PATH:LINE:COL:
   " LINE
let g:fzf_vim.grep_multi_line = 2
   " PATH:LINE:COL:
   " LINE
   " (empty line between items using --gap option)

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

" ================================================================================
"                                    COPILOT
" ================================================================================


" Change Tab to Ctrl-J to accept Copilot suggestions
imap <silent><script><expr> <C-J> copilot#Accept("\<CR>")
let g:copilot_no_tab_map = v:true


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
