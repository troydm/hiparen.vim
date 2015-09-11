" hiparen.vim - automatic paren highlighting for Lisp/Scheme/Clojure
" Maintainer: Dmitry "troydm" Geurkov <d.geurkov@gmail.com>
" Version: 0.1
" Description: hiparen.vim is a simple plugin to automaticly highlight
" parenthesis for Lisp type languages
" Last Change: 9 September, 2015
" License: Vim License (see :help license)
" Website: https://github.com/troydm/hiparen.vim
"
" See hiparen.vim for help.  This can be accessed by doing:
" :help hiparen.vim

let s:save_cpo = &cpo
set cpo&vim

highlight link HiParen MatchParen
highlight link HiParenClause CursorLine

function! s:ClearHighlightParen()
    syntax clear HiParen
    syntax clear HiParenClause
endfunction

function! s:HighlightParen(sl,sc,el,ec)
    exe 'syntax region HiParenClause start=/\%'.a:sl.'l\%'.a:sc.'c./rs=s+1 end=/\%'.a:el.'l\%'.a:ec.'c./re=e-1 contains=HiParen keepend'
    exe 'syntax match HiParen /\%'.a:sl.'l\%'.a:sc.'c./ contained'
    exe 'syntax match HiParen /\%'.a:el.'l\%'.a:ec.'c./ contained'
endfunction

function! s:GetOpenParenFor(c)
    if a:c == "}"
        return "{"
    elseif a:c == ")"
        return "("
    elseif a:c == "]"
        return "["
    else
        return ""
    endif
endfunction

function! s:GetCloseParenFor(c)
    if a:c == "{"
        return "}"
    elseif a:c == "("
        return ")"
    elseif a:c == "["
        return "]"
    else
        return ""
    endif
endfunction

function! s:IsOpenParen(c)
    return a:c == "{" || a:c == "(" || a:c == "["
endfunction

function! s:IsCloseParen(c)
    return a:c == "}" || a:c == ")" || a:c == "]"
endfunction

function! s:NewIterator(lines,line,col)
    try
        if len(a:lines) >= a:line
            return [a:line,a:col,a:lines[a:line-1][a:col-1]]
        endif
    catch
    endtry
    return [a:line,a:col,'eof']
endfunction

function! s:IteratorNext(lines,iterator)
    let l = a:iterator[0]
    let c = a:iterator[1]+1
    try
        while c > len(a:lines[l-1])
            let l += 1
            let c = 1
        endwhile
    catch
        return [l,c,'eof']
    endtry
    return [l,c,a:lines[l-1][c-1]]
endfunction

function! s:IteratorPrev(lines,iterator)
    let l = a:iterator[0]
    let c = a:iterator[1]-1
    try
        while c == 0
            let l -= 1
            let c = len(a:lines[l-1])
        endwhile
    catch
        return [l,c,'eof']
    endtry
    return [l,c,a:lines[l-1][c-1]]
endfunction

function! s:NotIteratorEOF(it)
    return a:it[2] != 'eof'
endfunction

function! s:HiParen()
    let c = getcurpos()
    let lines = getbufline(".",1,"$")
    let it = s:NewIterator(lines,c[1],c[2])
    let stack = ''
    let openit = []
    let closeit = []
    if s:IsOpenParen(it[2])
        let openit = it
        let it = s:IteratorNext(lines,it)
    endif
    while s:NotIteratorEOF(it)
        if s:IsOpenParen(it[2])
            let stack .= it[2]
        elseif s:IsCloseParen(it[2])
            if stack == ''
                let closeit = it
                break
            endif
            if s:GetOpenParenFor(it[2]) == stack[strlen(stack)-1]
                let stack = stack[:-2]
            endif
        endif
        let it = s:IteratorNext(lines,it)
    endwhile
    if closeit != [] && openit == []
        let it = s:IteratorPrev(lines,s:NewIterator(lines,c[1],c[2]))
        while s:NotIteratorEOF(it)
            if s:IsCloseParen(it[2])
                let stack .= it[2]
            elseif s:IsOpenParen(it[2])
                if stack == ''
                    let openit = it
                    break
                endif
                if s:GetCloseParenFor(it[2]) == stack[strlen(stack)-1]
                    let stack = stack[:-2]
                endif
            endif
            let it = s:IteratorPrev(lines,it)
        endwhile
    endif
    " echo string(openit).' - '.string(closeit)
    call s:ClearHighlightParen()
    if openit != [] && closeit != []
        call s:HighlightParen(openit[0],openit[1],closeit[0],closeit[1])
    endif
endfunction

function! s:IsParenEnabled()
    let b = getbufvar('.','parenenabled')
    if b == ''
        let b:parenenabled = 0
    endif
    return b:parenenabled
endfunction

function! s:EnableParen()
    let b:parenenabled=1
    let b:ft=&ft
    let b:cl=&cursorline
    set ft=
    set nocul
    augroup HiParen
        autocmd CursorMoved <buffer> call <SID>HiParen()
        autocmd CursorMovedI <buffer> call <SID>HiParen()
    augroup end
    call s:HiParen()
endfunction

function! s:DisableParen()
    call s:ClearHighlightParen()
    autocmd! HiParen CursorMoved <buffer> 
    autocmd! HiParen CursorMovedI <buffer> 
    exe 'set ft='.b:ft
    if b:cl
        set cursorline
    endif
    let b:parenenabled=0
endfunction

function! s:ToggleParen()
    if s:IsParenEnabled()
        call s:DisableParen()
    else
        call s:EnableParen()
    endif
endfunction

command! HiParenToggle call <SID>ToggleParen()
command! HiParenEnable call <SID>EnableParen()
command! HiParenDisable call <SID>DisableParen()

nnoremap <silent> <leader>q :HiParenToggle<CR>

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: set sw=4 sts=4 et fdm=marker:
