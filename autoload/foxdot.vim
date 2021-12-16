if exists("g:did_autoload_foxdot")
  finish
endif
let g:did_autoload_foxdot = 1

if !exists("g:python_executable_path")
  throw "Please set g:python_executable_path"
endif
if !exists("g:sclang_executable_path")
  throw "Please set g:sclang_executable_path"
endif

let s:foxdot_base_path = fnamemodify(expand('<sfile>:h') . '/..', ':p')
let s:foxdot_server_path = fnamemodify(s:foxdot_base_path . '/bin/foxdot.scd', ':p')
let s:foxdot_cli_path = fnamemodify(s:foxdot_base_path . '/bin/foxdot_cli.py', ':p')

function! s:startSuperCollider()
  echon "Starting SuperCollider..."
  let l:sclang_dir = fnamemodify(g:sclang_executable_path, ':h')
  let l:exe = fnamemodify(g:sclang_executable_path, ':t')
  let l:cwd = getcwd()
  silent execute 'lcd '.l:sclang_dir
  let l:opts = {'err_cb': "foxdot#errHandler"}
  let s:sclang_job = jobstart('"'.l:exe.'" -D "'.s:foxdot_server_path.'"', l:opts)
  silent execute 'lcd '.l:cwd
  sleep 3
  echon "done!\n"
endfunction

function! foxdot#outHandler(ch, msg)
  exe bufwinnr("FoxDotLog") . "wincmd w"
  exe "norm G"
  exe winnr("#"). "wincmd w"
  " echo a:msg
endfunction

function! foxdot#errHandler(ch, msg)
  echoerr a:msg
endfunction

function! s:startFoxDot()
  echon "Starting FoxDot..."
  let l:opts = {}
  let l:opts.pty = 1
  let l:opts.out_io = 'buffer'
  let l:opts.out_name = 'FoxDotLog'
  let l:opts.out_cb = "foxdot#outHandler"
  let l:opts.err_cb = "foxdot#errHandler"
  let s:foxdot_job = jobstart('"'.g:python_executable_path.'" "'.s:foxdot_cli_path.'"', l:opts)
  set autoread
  set splitbelow
  split | buffer 'FoxDotLog'
  " set nomodifiable

  let s:foxdot = job_getchannel(s:foxdot_job)
  echon "done!\n"
endfunction

function! s:setupCommands()
  command! FoxDotReboot call foxdot#reboot()
  command! -range FoxDotEval call foxdot#run(<line1>, <line2>)
  "command! -range FoxDotEval <line1>,<line2>call foxdot#run()
  "vnoremap cp :FoxDotEval<CR>
  "nmap <C-CR> vipcp
  nmap <C-CR> vip:FoxDotEval<CR>
  imap <C-CR> <Esc><C-CR>i
endfunction

function! foxdot#run(firstline1, lastline1)
  let l:str = ''
  " for l:lnum in range(a:line1, a:line2)
  for l:lnum in range(a:firstline1, a:lastline1)
    " let l:line = substitute(getline(l:lnum), '^[[:space:]]*', '', '')
    let l:line = getline(l:lnum)
    ""let l:str = l:str . l:line . "\n"
    call ch_sendraw(s:foxdot, '.'. l:line . "\n")
    "if match(l:line, '^\.') != -1
    "  let l:str = l:str . l:line
    "else
    "  let l:str = l:str . " " . l:line
    "endif
  endfor
  " call ch_evalraw(s:foxdot, l:str . "\n")
  echo l:str
  call ch_sendraw(s:foxdot, '[STACK-SEND]' . "\n")
endfunction

function! foxdot#start()
  " call s:startSuperCollider()
  call s:startFoxDot()
  call s:setupCommands()
endfunction

function! foxdot#stop()
  call jobstop(s:foxdot_job)
  " call jobstop(s:sclang_job)
endfunction

function! foxdot#reboot()
  call foxdot#stop()
  call foxdot#start()
endfunction
