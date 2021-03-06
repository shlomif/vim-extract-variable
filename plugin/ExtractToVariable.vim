if exists("g:loaded_extract_variable") || &cp
  finish
endif
let g:loaded_extract_variable = 1

function! g:ExtractToVariable(visual_mode, needle, varname)
  " Check if 'filetype' is set
  if &filetype == ''
    echo "'filetype' is not set"
    return
  endif

  " Check if language is supported
  let l:supported_languages = ['elixir', 'go', 'javascript', 'make', 'r', 'typescript', 'python', 'ruby']
  let l:filetype = split(&filetype, '\.')[0]

  if index(l:supported_languages, l:filetype) == -1
    echo l:filetype . ' is not supported. Please open an issue at https://github.com/shlomif/vim-extract-variable/issues/new'
    return
  endif

  " Yank expression to z register
  let saved_y = @y
  let saved_z = @z
  if a:needle != ''
    let @z = a:needle
  else
    if a:visual_mode ==# 'v'
      execute "normal! `<v`>\"zy"
    else
      execute "normal! vib\"zy"
    endif
  endif

  " Ask for variable name
  if a:varname == ''
    let a:varname = input('Variable name? ')
  endif

  if a:varname != ''
    let replace_expr = a:varname
    if l:filetype ==# 'make'
      let replace_expr = "\$(" . replace_expr . ')'
    endif
    " execute "normal! `<v`>s".replace_expr."\<esc>"
    py3 << EOF
import vim

needle = vim.eval('@z')
repl = vim.eval('replace_expr')
def my_func(s):
    return str(s).replace(needle, repl)

EOF
    :'<,$py3do return my_func(line)

    if l:filetype ==# 'javascript' || l:filetype ==# 'typescript'
      execute "normal! Oconst ".a:varname." = ".@z."\<esc>"
    elseif l:filetype ==# 'make'
      execute "normal! O".a:varname." := ".@z."\<esc>"
    elseif l:filetype ==# 'go'
      execute "normal! O".a:varname." := ".@z."\<esc>"
    elseif l:filetype ==# 'elixir' || l:filetype ==# 'python' || l:filetype ==# 'ruby'
      execute "normal! O".a:varname." = ".@z."\<esc>"
    elseif l:filetype ==# 'r'
      execute "normal! O".a:varname." <- ".@z."\<esc>"
    endif
  else
    redraw
    echo 'Empty variable name, doing nothing'
  endif

  let @z = saved_z
  let @y = saved_y
endfunction

nnoremap <leader>ev :call <sid>ExtractToVariable('', '', '')<cr>
vnoremap <leader>ev :<c-u>call <sid>ExtractToVariable(visualmode(), '', '')<cr>
