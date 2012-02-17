" Edits vim variable in buffer.
" Version: 1.1
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

  let bufnr = 0  " use global var when bufnr = 0.
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
    if bufnr
      let b = getbufvar(bufnr, '')
      let bname = name[2 :]
      if has_key(b, bname)
        let value = b[bname]
      endif
    else
      try
        let value = {name}
      catch /^Vim(let):E121:/
      endtry
    endif
    setlocal buftype=acwrite filetype=vim
    if exists('value')
      let str = exists('*PP') ? PP(value) : string(value)
      silent put =str
      silent 1 delete _
    endif

  elseif a:method ==# 'write'
    let valstr = join(getline(1, '$'), '')
    if valstr =~# '\S'
      sandbox let value = eval(valstr)
    endif
    if bufnr
      " Don't use setbufvar() to avoid E706
      let bname = name[2 :]
      let b = getbufvar(bufnr, '')
      if exists('value')
        let b[bname] = value
      elseif has_key(b, bname)
        call remove(b, bname)
      endif
    else
      unlet! {name}
      if exists('value')
        let {name} = value
      endif
    endif
  endif
  setlocal nomodified
endfunction

let &cpo = s:save_cpo
