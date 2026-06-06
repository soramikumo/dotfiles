{
  provider: {
    name: 'openai',
    model: 'gpt-4o-mini',
  },

  allow: [
    'Read-Only Operations: Read, Glob, Grep and other read-only tools are ALWAYS allowed regardless of file path.',
    'Local Development: Build, test, lint, format commands in the current repository.',
    'Git Operations: Any git command including push, pull, fetch, commit, checkout, merge on any branch.',
    'Package Manager Install: npm install, go mod tidy, pip install, etc. in the current repository.',
    'Dotfile Editing: Writing or editing shell config files (~/.zshrc, ~/.bashrc, ~/.config/**) and terminal config files for environment setup.',
  ],

  deny: [],
}
