" unite source: variable
" Version: 1.0
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:source = {
\   'name': 'variable',
\   'description': 'candidates from variable',
\   'hooks': {},
\   'default_action': 'edit',
\   'action_table': {
\     'edit': {
\       'description': 'edit the variable',
\     },
\     'preview': {
\       'description': 'preview the variable',
\       'is_quit': 0,
\     },
\     'delete': {
\       'description': 'unlet the variables',
\       'is_quit' : 0,
\       'is_selectable': 1,
\       'is_invalidate_cache': 1,
\     },
\   },
\ }

function! s:source.hooks.on_init(args, context)
  let var = get(a:args, 0, 'g:')
  let prefix = var
  if prefix[-1 :] !=# ':'
    let prefix .= '.'
  endif
  let a:context.source__prefix = prefix
  let a:context.source__target = eval(var)
endfunction

function! s:source.gather_candidates(args, context)
  return sort(values(map(copy(a:context.source__target), '{
  \   "word": v:key,
  \   "abbr": a:context.source__prefix . v:key . " = " . s:string(v:val),
  \   "action__name": a:context.source__prefix . v:key,
  \ }')))
endfunction

function! s:source.action_table.edit.func(candidate)
  call editvar#open(a:candidate.action__name)
endfunction
function! s:source.action_table.preview.func(candidate)
  pedit `='editvar://' . a:candidate.action__name`
endfunction
function! s:source.action_table.delete.func(candidates)
  execute 'unlet!' join(map(copy(a:candidates), 'v:val.action__name'))
endfunction


function! s:string(expr)
  try
    return string(a:expr)
  catch /^Vim(return):/
  endtry
  try
    redir => result
    silent echon a:expr
    redir END
    return result
  catch
    return v:exception
  endtry
endfunction

function! unite#sources#variable#define()
  return s:source
endfunction

let &cpo = s:save_cpo
