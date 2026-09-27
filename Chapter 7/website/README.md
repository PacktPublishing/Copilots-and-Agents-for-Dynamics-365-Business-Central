# BC Tech Summit 2027 website (knowledge source)

Static page with the logistics information (venue, transport, Wi-Fi, catering, badges, code of conduct) that the attendee assistant answers from **knowledge** rather than from Business Central.

Publish it on any public host (GitHub Pages works: enable Pages on the repository and use the `website/` folder as source) and add the resulting URL as a **Public website** knowledge source in Copilot Studio. Public websites are crawled and refreshed, which is what we want for pages the organizers update during the event.

## Adding the assistant

The page reserves a panel for the Tech Summit Assistant. After publishing the agent with **No authentication**, copy the `src` of the iframe in **Channels > Web app > Embed code** into the `iframe` of `index.html`. The page is plain HTML and CSS, so the same snippet works on any event website: whoever maintains the event site (for example, the marketing team) only needs to paste it.
