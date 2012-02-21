" Edits vim variable in buffer.
" Version: 1.1
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let g:editvar#opener = get(g:, 'g:editvar#opener', 'new')
let g:editvar#string = get(g:, 'g:editvar#string', 1)

function! editvar#open(varname)
  let [args, bufnr] = s:normalize(a:varname, bufnr('%'))
  if bufnr
    let args = bufnr . '/' . args
  endif
  execute g:editvar#opener '`="editvar://" . args`'
endfunction

function! editvar#read(bufname)
  call s:do_cmd(a:bufname, 'read')
endfunction

function! editvar#write(bufname)
  call s:do_cmd(a:bufname, 'write')
endfunction

function! s:normalize(var, defbufnr)
  let bufnr = 0
  let varname = a:var
  if varname =~# '^\d\+/'
    let bufnr = matchstr(varname, '^\d\+') - 0
    let varname = matchstr(varname, '^\d\+/\zs.*')
  endif
  if varname !~# '^@.$' && varname[1] !=# ':'
    let varname = (bufnr ? 'b:' : 'g:') . varname
  endif
  if varname[: 1] ==# 'b:' && bufnr == 0
    let bufnr = a:defbufnr
  endif
  return [varname, bufnr]
endfunction

function! s:do_cmd(bufname, method) abort
  let varname = matchstr(a:bufname, 'editvar://\zs.*')
  let bufnr = get(b:, 'editvar_bufnr', bufnr('#'))
  let [varname, bufnr] = s:normalize(varname, bufnr)

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
