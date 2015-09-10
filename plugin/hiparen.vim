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

set cursorline!
highlight HiParen ctermbg=234

function! s:ClearHighlightParen()
    syntax clear HiParen
endfunction

function! s:HighlightParen(sl,sc,el,ec)
    exe 'syntax region HiParen start=/\%'.a:sl.'l\%'.a:sc.'c./ end=/\%'.a:el.'l\%'.a:ec.'c./'
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
    echo string(openit).' - '.string(closeit)
    call s:ClearHighlightParen()
    if openit != [] && closeit != []
        call s:HighlightParen(openit[0],openit[1],closeit[0],closeit[1])
    endif
endfunction

augroup HiParen
    autocmd CursorMoved *.lisp call <SID>HiParen()
    autocmd CursorMoved *.lsp call <SID>HiParen()
    autocmd CursorMoved *.clj call <SID>HiParen()
    autocmd CursorMovedI *.lisp call <SID>HiParen()
    autocmd CursorMovedI *.lsp call <SID>HiParen()
    autocmd CursorMovedI *.clj call <SID>HiParen()
augroup end

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: set sw=4 sts=4 et fdm=marker:
