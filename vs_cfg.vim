" ########
" tagbar
" ########
let g:tagbar_position = 'topleft vertical'
let g:tagbar_width = 30
let g:tagbar_autofocus = 1
let g:tagbar_show_linenumbers = 2
let g:tagbar_foldlevel = 1
let g:tagbar_sort = 0
"let g:tagbar_visibility_symbols = {
            "\ 'public'    : '+',
            "\ 'protected' : '#',
            "\ 'private'   : '-'
            "\ }

nnoremap <leader>t :TagbarToggle<CR>
nnoremap <leader>tp :TagbarTogglePause<CR>

" ########
" gtags
" ########
" I use GNU global instead cscope because global is faster.
" 第一个 GTAGSLABEL 告诉 gtags 默认 C/C++/Java 等六种原生支持的代码直接使用
" gtags 本地分析器，而其他语言使用 pygments 模块。
let $GTAGSLABEL = 'native-pygments'
let $GTAGSCONF = '/home/lemon/.globalrc'

let g:gutentags_enabled = 1
let g:gutentags_modules = ['ctags']

" gutentags 搜索工程目录的标志，当前文件路径向上递归直到碰到这些文件/目录名
let g:gutentags_project_root = ['.root']
" 所生成的数据文件的名称
let g:gutentags_ctags_tagfile = '.tags'
" 将自动生成的 ctags/gtags 文件全部放入 ~/.cache/tags 目录中，避免污染工程目录
let s:vim_tags = expand('~/.cache/tags')
let g:gutentags_cache_dir = s:vim_tags
" 配置 ctags 的参数
let g:gutentags_ctags_extra_args = [
      \ '--tag-relative=yes',
      \ '--fields=+ailmnS',
      \ ]
" 如果使用 universal ctags 需要增加下面一行
"let g:gutentags_ctags_extra_args += ['--output-format=e-ctags', '--extras=+q']
" gtags extra parameters, manually modify gutentags/gtags_cscope.vim:91
"let l:cmd += ['--incremental --skip-unreadable', '"'.l:db_path.'"']
" 禁用 gutentags 自动加载 gtags 数据库的行为
let g:gutentags_auto_add_gtags_cscope = 1
" 检测 ~/.cache/tags 不存在就新建
if !isdirectory(s:vim_tags)
    silent! call mkdir(s:vim_tags, 'p')
endif

let g:gutentags_ctags_exclude = [
            \ '*.git', '*.svg', '*.hg', '*/tests/*', 'build', 'dist', '*sites/*/files/*',
            \ 'bin', 'node_modules', 'bower_components', 'cache',
            \ 'compiled', 'docs', 'example', 'bundle',
            \ 'vendor', '*.md', '*-lock.json', '*.lock',
            \ '*bundle*.js', '*build*.js', '.*rc*', '*.json',
            \ '*.min.*', '*.map', '*.bak', '*.zip',
            \ '*.pyc', '*.class', '*.sln', '*.Master',
            \ '*.csproj', '*.tmp', '*.csproj.user', '*.cache',
            \ '*.pdb', 'tags*', 'cscope.*', '*.css',
            \ '*.less', '*.scss', '*.exe', '*.dll',
            \ '*.mp3', '*.ogg', '*.flac', '*.swp',
            \ '*.swo', '*.bmp', '*.gif', '*.ico',
            \ '*.jpg', '*.png', '*.rar', '*.zip',
            \ '*.tar', '*.tar.gz', '*.tar.xz', '*.tar.bz2',
            \ '*.pdf', '*.doc', '*.docx', '*.ppt',
            \ '*.pptx', '*.js', '*.jsx', '*/isi_webui/*',
            \  ]
" used for gtags exclusion
" :skip=webui/,test/,HTML/,HTML.pub/,build/,port/,*.css,*.cache,*.zip,*.svg,*.hg,*.git,*.pyc,*.js,*.jsx,tags,TAGS,ID,y.tab.c,y.tab.h,gtags.files,cscope.files,cscope.out,cscope.po.out,cscope.in.out,SCCS/,RCS/,CVS/,CVSROOT/,{arch}/,autom4te.cache/,*.mo,*.orig,*.rej,*.bak,*~,#*#,*.swp,*.tmp,*_flymake.*,*_flymake,*.o,*.a,*.so,*.lo,*.zip,*.gz,*.bz2,*.xz,*.lzh,*.Z,*.tgz,*.min.js,*min.css:

" let g:gutentags_gtags_executable = "gtags --skip-unreadable --skip-symlink"
" let g:gutentags_define_advanced_commands = 1
" let g:gutentags_exclude_project_root += ["/home/lemon/project/leveldb/third_party/"]
let g:gutentags_trace = 0


" ########
" vim-preview
" ########
" noremap <m-u> :PreviewScroll -5<cr>
" noremap <m-d> :PreviewScroll +5<cr>
" inoremap <m-u> <c-\><c-o>:PreviewScroll -5<cr>
" inoremap <m-d> <c-\><c-o>:PreviewScroll +5<cr>
autocmd FileType qf nnoremap <silent><buffer> p :PreviewQuickfix<cr>
autocmd FileType qf nnoremap <silent><buffer> P :PreviewClose<cr>
nmap <m-t> :PreviewTag <cr>
nmap <m-s> :PreviewSignature <cr>
nmap <m-c> :PreviewClose <cr>
" close quickfix window
