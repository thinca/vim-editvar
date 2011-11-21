" Edits vim variable in buffer.
" Version: 1.0
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let g:editvar#opener = get(g:, 'g:editvar#opener', 'new')

function! editvar#open(varname)
  let args = s:g(a:varname)
  if a:varname[: 1] ==# 'b:'
    let bufnr = matchstr(a:varname, '/\zs\d\+$') - 0
    if bufnr is 0
      let bufnr = bufnr('%')
    endif
    let args .= '/' . bufnr
  endif
  execute g:editvar#opener '`="editvar://" . args`'
endfunction

function! editvar#read(bufname)
  call s:do_cmd(a:bufname, 'read')
endfunction

function! editvar#write(bufname)
  call s:do_cmd(a:bufname, 'write')
endfunction

function! s:g(var)
  return a:var[1] ==# ':' ? a:var : 'g:' . a:var
endfunction

function! s:do_cmd(bufname, method) abort
  let varname = s:g(matchstr(a:bufname, 'editvar://\zs.*'))

  if varname[: 1] ==# 'b:'
    let bufnr = matchstr(varname, '/\zs\d\+$') - 0
    if bufnr is 0
      let bufnr = get(b:, 'editvar_bufnr', bufnr('#'))
      let b:editvar_bufnr = bufnr
    else
      let varname = matchstr(varname, '^.*\ze/\d\+$')
    endif
  endif

  let name = matchstr(varname, '^[[:alnum:]_:#]\+$')
  if name ==# ''
    throw 'editvar: Invalid variable name: ' . varname
  endif

  if a:method ==# 'read'
    if exists('bufnr')
      let value = getbufvar(bufnr, name[2 :])
    else
      let value = exists(name) ? {name} : ''
    endif
    let str = exists('*PP') ? PP(value) : string(value)
    setlocal buftype=acwrite filetype=vim
    silent put =str
    silent 1 delete _

  elseif a:method ==# 'write'
    let value = eval(join(getline(1, '$'), ''))
    if exists('bufnr')
      " Don't use setbufvar() to avoid E706
      let b = getbufvar(bufnr, '')
      let b[name[2 : ]] = value
    else
      unlet! {name}
      let {name} = value
    endif
  endif
  setlocal nomodified
endfunction

let &cpo = s:save_cpo
