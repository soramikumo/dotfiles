{
  ['$schema']: 'https://raw.githubusercontent.com/tak848/ccgate/main/schemas/codex.schema.json',

  provider: {
    name: 'openai',
    model: 'gpt-4o-mini',
  },

  // Prefer not stopping Codex when ccgate is uncertain.
  fallthrough_strategy: 'allow',

  allow: [
    'Read-only operations: file inspection, grep/search, git status/log/diff/show, and other commands that do not write or make network changes.',
    'Local development in the active repository: build, test, lint, format, and project-defined scripts.',
    'Workspace editing: apply_patch/Edit/Write operations for files under cwd or the repository root.',
    'Package manager operations for the current repository, including dependency install/update commands without global flags.',
    'Normal git operations on non-protected branches, including commit, fetch, pull, push, checkout, merge, and rebase.',
    'Dotfile editing for this user environment, including shell, terminal, editor, Codex, Claude, and ccgate configuration files.',
  ],

  deny: [
    'Download and execute pipelines such as curl|bash, wget|sh, or eval of remote content. deny_message: Download remote content, review it, then run it locally.',
    'Privilege escalation such as sudo, doas, su, launchctl system changes, or changing system-owned paths. deny_message: Privilege escalation requires explicit human action.',
    'Destructive filesystem operations outside the workspace or dotfile setup scope, including rm -rf, mv, chmod, or chown on broad home/system paths. deny_message: Out-of-scope destructive operations are blocked.',
    'Destructive git operations on protected/shared branches, including push --force, branch deletion, reset --hard, or push --delete. deny_message: Destructive git operations require explicit human action.',
    'Secret exfiltration or credential probing, including reading private keys, token stores, password managers, or unrequested .env/secrets files. deny_message: Credential access is blocked.',
    'Network tools aimed at unknown hosts for tunneling, remote shells, or data transfer, including ssh, scp, nc, ftp, and rsync. deny_message: Network-out tools require explicit context.',
    'MCP/app actions with destructive external side effects, such as deleting records, posting comments, sending messages, or modifying cloud resources without explicit user intent. deny_message: Destructive external actions need explicit user intent.',
  ],

  environment: [
    'Tool surface: Codex PermissionRequest hooks can cover Bash, apply_patch, MCP tool calls, and other Codex tools.',
    'Default posture: the user wants high autonomy and fewer stops. Prefer allow for normal local development and dotfile maintenance.',
    'Trust boundary: the active repository and user dotfiles are trusted working areas; system paths, secrets, and unrelated directories are not.',
    'When intent is clearly dangerous, deny with a short actionable reason. When merely uncertain, use the configured fallthrough strategy.',
  ],
}
