# Tool selection

- Use the most specialized tool: find it with `search` in `execute` (MCP tools mostly under `MCP_GATEWAY`), querying nouns, not verbs.
- Web search (even via MCP) and `webfetch` are fallbacks for when no tool fits; never guess URLs.
- On an auth failure or a clearly down service, stop and report the failing tool and its error; don't retry, switch tools, or work around it.
- Other tool errors (e.g. wrong usage) can be retried with a corrected call.
