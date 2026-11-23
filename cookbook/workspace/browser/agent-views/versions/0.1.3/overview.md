
This component lets a user check, with their own eyes, exactly what an
agent is given from a page. It is a three-way icon control in the browser
pane's privacy toolbar that switches what a tab's content area shows:

- **Website** — the page as it is (the default);
- **Agent preview** — the agent's page drawn as a sealed, read-only
  document;
- **Agent source** — the same document as highlighted source text.

Both agent views show the output of the Agent Page Builder (the agent
gatekeeper, see that recipe) and nothing else: the HTML it renders from the
very page value whose snapshot tree and text the tools hand to the agent.
The preview cannot add anything of its own — page scripts are off, every
network load is blocked, and it never navigates past the document it was
given — so what it shows cannot differ from what the agent receives. The
views follow the page: they rebuild after a navigation, after a privacy
setting changes, after the privacy words change, and after the site's
"hide from agent" list changes, with bursts of changes coalesced into one
rebuild.

The mode is per tab and is not saved.

The Agent view control's segments carry text as well as symbols, Browser, Agent View and Agent Source, in a regular-size rounded control whose selected segment takes the accent colour, inside a bordered box padded off the privacy toolbar's groups.

