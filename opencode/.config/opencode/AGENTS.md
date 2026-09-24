# Tool selection

ALWAYS use the most specialized tool for the task; web search via MCP is still web search (fallback only).
Find it via `search` in `execute` (most MCP tools live under `MCP_DOCKER`) before any web search/fetch; query task nouns, not verbs.
On tool error, switch tool category; don't retry a similar tool.
Fetch whole pages via `webfetch` only when the tools above were insufficient; never guess URLs.
