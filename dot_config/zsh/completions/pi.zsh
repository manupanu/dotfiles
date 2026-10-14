# Zsh completion for Pi CLI (built-in interface as of Pi 1.0.2).
# Sourced after compinit; no Pi process or network requests during completion.

_pi() {
  local context state state_descr line
  local -A opt_args
  local command="${words[2]}"
  local -a common
  common=(
    '(-h --help)'{-h,--help}'[Show help]'
    '(-a --approve)'{-a,--approve}'[Trust project-local configuration]'
    '(-na --no-approve)'{-na,--no-approve}'[Ignore project-local configuration]'
  )

  case "$command" in
    install|remove|uninstall|update|list|config|auth|mcp)
      if (( CURRENT > 2 )); then
        words=("${words[@]:1}")
        (( CURRENT-- ))
        case "$command" in
          install|remove|uninstall|config)
            _arguments "${common[@]}" \
              '(-l --local)'{-l,--local}'[Use project settings]' \
              '*:package source:_files'
            ;;
          update)
            _arguments "${common[@]}" \
              '--self[Update Pi]' '--extensions[Update all packages]' \
              '--extension[Update one package]:package source:_files' \
              '--models[Refresh model catalogs]' '--all[Update everything]' \
              '--force[Reinstall Pi]' '*:target:_files'
            ;;
          list) _arguments "${common[@]}" ;;
          auth)
            _arguments "${common[@]}" \
              '--provider[Provider name]:provider:' '--model[Model ID]:model:' \
              '--json[Output JSON]' '--credentials[Include resolved credentials]' \
              '--no-refresh[Do not refresh OAuth credentials]' \
              '--min-expiry[Minimum token lifetime]:duration:' \
              '1:auth command:(check print-api-key print-bearer-token)'
            ;;
          mcp)
            _arguments "${common[@]}" \
              '(-l --local)'{-l,--local}'[Use project configuration]' \
              '--json[Output JSON]' '--timeout[Login timeout]:seconds:' \
              '*--env[Environment variable]:KEY=VALUE:' '--cwd[Working directory]:directory:_files -/' \
              '--url[HTTP server URL]:URL:' '*--header[HTTP header]:header:' \
              '--bearer-token-env-var[Token environment variable]:variable:_parameters' \
              '--oauth-client-id[OAuth client ID]:ID:' '--oauth-client-secret[OAuth client secret]:secret:' \
              '--oauth-callback-port[OAuth callback port]:port:' '--oauth-client-name[OAuth client name]:name:' \
              '--exposure[Tool exposure mode]:mode:' '--description[Server description]:description:' \
              '1:MCP command:(add remove list login logout)' '*:server or argument:_files'
            ;;
        esac
        return
      fi
      ;;
  esac

  _arguments -C "${common[@]}" \
    '(-v --version)'{-v,--version}'[Show version]' \
    '(-p --print)'{-p,--print}'[Run once and print response]' \
    '--mode[Output interface]:mode:(text json rpc)' \
    '--provider[Model provider]:provider:' '--model[Model ID or pattern]:model:' \
    '--api-key[API key override]:key:' '--models[Model patterns]:patterns:' \
    '--thinking[Thinking level]:level:(off minimal low medium high xhigh max)' \
    '--list-models[List models]:search:' \
    '(-c --continue)'{-c,--continue}'[Continue latest session]' \
    '(-r --resume)'{-r,--resume}'[Open session selector]' \
    '--session[Open session]:session:_files' '--session-id[Session ID]:ID:' \
    '--fork[Fork session]:session:_files' '--session-dir[Session directory]:directory:_files -/' \
    '--no-session[Do not persist session]' '(-n --name)'{-n,--name}'[Session name]:name:' \
    '(-t --tools)'{-t,--tools}'[Tool allowlist]:tools:' \
    '(-xt --exclude-tools)'{-xt,--exclude-tools}'[Excluded tools]:tools:' \
    '(-nbt --no-builtin-tools)'{-nbt,--no-builtin-tools}'[Disable built-in tools]' \
    '(-nt --no-tools)'{-nt,--no-tools}'[Disable all tools]' \
    '*'{-e,--extension}'[Load extension]:extension:_files' \
    '(-ne --no-extensions)'{-ne,--no-extensions}'[Disable extension discovery]' \
    '*--skill[Load skill]:skill:_files' '(-ns --no-skills)'{-ns,--no-skills}'[Disable skill discovery]' \
    '*--prompt-template[Load prompt template]:template:_files' \
    '(-np --no-prompt-templates)'{-np,--no-prompt-templates}'[Disable template discovery]' \
    '*--theme[Load theme]:theme:_files' '--use-theme[Initial theme]:theme:' \
    '--no-themes[Disable theme discovery]' \
    '(-nc --no-context-files)'{-nc,--no-context-files}'[Disable context file discovery]' \
    '--system-prompt[Replace system prompt]:text or file:_files' \
    '*--append-system-prompt[Append system prompt]:text or file:_files' \
    '--tui-mode[Terminal UI mode]:mode:(fullscreen regular)' \
    '--verbose[Verbose startup]' '--offline[Disable automatic network activity]' \
    '--export[Export session to HTML]:session:_files' \
    '1:command or prompt:->command' '*:prompt or file:->files'

  case "$state" in
    command)
      local -a commands=(
        'install:Install a package' 'remove:Remove a package' 'uninstall:Remove a package'
        'update:Update Pi or packages' 'list:List installed packages' 'config:Configure packages'
        'auth:Check or print credentials' 'mcp:Manage MCP servers'
      )
      _describe 'Pi command' commands
      ;&
    files)
      if [[ "$PREFIX" == @* ]]; then
        compset -P '@'
        _files
      else
        _files
      fi
      ;;
  esac
}

compdef _pi pi
