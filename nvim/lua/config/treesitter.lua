local _parser_to_filetype = {
  awk           = 'awk',
  bash          = { 'bash', 'sh' },
  bitbake       = 'bitbake',
  c             = 'c',
  cmake         = 'cmake',
  cpp           = 'cpp',
  cuda          = 'cuda',
  diff          = 'diff',
  dockerfile    = 'dockerfile',
  dot           = 'dot',
  doxygen       = 'doxygen',
  git_config    = 'gitconfig',
  git_rebase    = 'gitrebase',
  gitattributes = 'gitattributes',
  gitcommit     = 'gitcommit',
  gitignore     = 'gitignore',
  go            = 'go',
  groovy        = 'groovy',
  html          = 'html',
  html_tags     = 'html_tags',
  javascript    = 'javascript',
  json          = 'json',
  julia         = 'julia',
  lua           = 'lua',
  make          = 'make',
  markdown      = 'markdown',
  ninja         = 'ninja',
  python        = 'python',
  qmljs         = 'qmljs',
  ruby          = 'ruby',
  rust          = 'rust',
  ssh_config    = 'sshconfig',
  tmux          = 'tmux',
  typescript    = 'typescript',
  vim           = 'vim',
  yaml          = 'yaml',
  zsh           = 'zsh',
}

local _parsers = function()
  local parsers = {}
  for parser, _ in pairs(_parser_to_filetype) do
    table.insert(parsers, parser)
  end
  return parsers
end

local _filetypes = function()
  local filetypes = {}

  for _, ft in pairs(_parser_to_filetype) do
    if type(ft) == 'table' then
      for _, f in ipairs(ft) do
        if not vim.tbl_contains(filetypes, ft) then
          table.insert(filetypes, f)
        end
      end
    else
      if not vim.tbl_contains(filetypes, ft) then
        table.insert(filetypes, ft)
      end
    end
  end

  return filetypes
end

return {
  filetypes = _filetypes,
  parsers   = _parsers,
}
