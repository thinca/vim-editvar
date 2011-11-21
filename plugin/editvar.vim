" Edits vim variable in buffer.
" Version: 1.1
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

if exists('g:loaded_editvar')
  finish
endif
let g:loaded_editvar = 1

let s:save_cpo = &cpo
set cpo&vim

augroup plugin-editvar
  autocmd!
  autocmd BufReadCmd  editvar://* call editvar#read(expand('<amatch>'))
  autocmd BufWriteCmd editvar://* call editvar#write(expand('<amatch>'))
augroup END

command! -bar -nargs=1 -complete=var Editvar call editvar#open(<q-args>)

let &cpo = s:save_cpo
unlet s:save_cpo
