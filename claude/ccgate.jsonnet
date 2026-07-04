{
  provider: {
    name: 'openai',
    model: 'gpt-4o',
  },

  allow: [
    'Read-Only Operations: Read, Glob, Grep and other read-only tools are ALWAYS allowed regardless of file path.',
    'Local Development: Build, test, lint, format commands in the current repository.',
    'Git Operations: Any git command including push, pull, fetch, commit, checkout, merge on any branch.',
    'Package Manager Install: npm install, go mod tidy, pip install, etc. in the current repository.',
    'Dotfile Editing: Writing or editing shell config files (~/.zshrc, ~/.bashrc, ~/.config/**) and terminal config files for environment setup.',
    'Homebrew & mise: brew install/upgrade/bundle and mise install/use for setting up the development toolchain on this machine.',
    'Public Documentation Fetch: WebFetch and WebSearch for public documentation, technical articles, open-source project pages, blog posts, and reference materials. Block any URL that looks like a private/internal service, intranet, authenticated app, or credentialed API.',
    'Agent Skill Scripts: Executing scripts under ~/.agents/skills/*/scripts/ (e.g. agmsg send/inbox/team/join/history/whoami/delivery) for cross-agent messaging and skill operation.',
    'Parent & Sibling Directories: Reading and editing files in directories adjacent to or above the active repository (parent/sibling paths), e.g. a monorepo root or a neighboring project, excluding destructive operations.',
    'Browser Automation (Claude in Chrome): mcp__claude-in-chrome__* tools (navigate, click, type, read_page, find, etc.) operating their own logged-in Chrome session on their own Slack app configuration pages at api.slack.com and app.slack.com for personal bot setup are explicitly allowed. This overrides the authenticated-app / credentialed-API caution in the Public Documentation Fetch rule for these first-party, user-owned sites.',
  ],

  deny: [],
}
