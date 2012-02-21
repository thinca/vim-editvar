" Edits vim variable in buffer.
" Version: 1.1
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let g:editvar#opener = get(g:, 'g:editvar#opener', 'new')
let g:editvar#string = get(g:, 'g:editvar#string', 1)

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
  return a:var =~# '^@.$' || a:var[1] ==# ':' ? a:var : 'g:' . a:var
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

  let name = matchstr(varname, '^\%(@.\|[[:alnum:]_:#.]\+\)$')
  if name ==# ''
    throw 'editvar: Invalid variable name: ' . varname
  endif

  if a:method ==# 'read'
    if bufnr
      let value = getbufvar(bufnr, '')
      for n in split(name[2 :], '\.')
        if !has_key(value, n)
          unlet! value
          break
        endif
        let l:['value'] = value[n]
      endfor
    else
      try
        let value = eval(name)
      catch /^Vim(let):E121:/
      endtry
    endif
    setlocal buftype=acwrite
    let b:editvar_string = 0
    if exists('value')
      if g:editvar#string && type(value) == type('')
        let b:editvar_string = g:editvar#string
        let str = value
        if str =~# "\n$"
          let str .= "\n"
        endif
        let b:editvar_sep = "\n"
      elseif exists('*PP')
        let pp_string = g:prettyprint_string
        let g:prettyprint_string = ['split', 'raw']
        try
          let str = PP(value)
        finally
          let g:prettyprint_string = pp_string
        endtry
      else
        let str = string(value)
        let b:editvar_sep = "\n"
      endif
      silent put =str
      silent 1 delete _
    endif
    if !b:editvar_string
      setlocal filetype=vim
    endif

  elseif a:method ==# 'write'
    let valstr = join(getline(1, '$'), get(b:, 'editvar_sep', ''))
    if b:editvar_string
      let value = valstr
    elseif valstr =~# '\S'
      sandbox let value = eval(valstr)
    endif
    if bufnr
      call s:write_var(getbufvar(bufnr, ''), name[2 :], l:)
    elseif name =~# '^@.$'
      execute 'let' name '= value'
    else
      call s:write_var(g:, name[2 :], l:)
    endif
  endif
  setlocal nomodified
endfunction

function! s:write_var(dict, name, l)
  let dict = a:dict
  let names = split(a:name, '\.')
  for n in names[: -2]
    if !has_key(dict, n) || type(dict[n]) != type({})
      let dict[n] = {}
    endif
    let dict = dict[n]
  endfor
  let key = empty(names) ? '' : names[-1]
  if has_key(a:l, 'value')
    if key ==# ''
      call extend(dict, a:l.value)
    else
      let dict[key] = a:l.value
    endif
  elseif has_key(dict, key)
    call remove(dict, key)
  endif
endfunction

let &cpo = s:save_cpo
