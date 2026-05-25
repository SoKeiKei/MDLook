import Foundation

enum PreviewHTMLTemplate {
    static func document(body: String) -> String {
        """
        <!doctype html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
        :root {
          color-scheme: light dark;
          --bg: #ffffff;
          --fg: #1f2328;
          --muted: #667085;
          --border: #d0d7de;
          --code-bg: #f6f8fa;
          --code-border: #e5e7eb;
          --quote: #4b5563;
          --quote-bg: rgba(246, 248, 250, 0.7);
          --quote-border: #0969da;
          --link: #0969da;
          --mark-highlight: rgba(255, 235, 59, 0.9);
          --mark-bg: #fff3a3;
          --callout-info: #0969da;
          --callout-note: #59636e;
          --callout-tip: #1a7f37;
          --callout-important: #8250df;
          --callout-warning: #b54708;
          --callout-caution: #cf222e;
        }
        @media (prefers-color-scheme: dark) {
          :root {
            --bg: #0f1115;
            --fg: #e6edf3;
            --muted: #9aa4b2;
            --border: #30363d;
            --code-bg: #171b22;
            --code-border: #30363d;
            --quote: #9ca3af;
            --quote-bg: rgba(23, 27, 34, 0.7);
            --quote-border: #7db7ff;
            --link: #7db7ff;
            --mark-highlight: rgba(255, 235, 59, 0.45);
            --mark-bg: #5f4b12;
            --callout-info: #7db7ff;
            --callout-note: #9aa4b2;
            --callout-tip: #7ee787;
            --callout-important: #d2a8ff;
            --callout-warning: #ffb86b;
            --callout-caution: #ff7b72;
          }
        }
        body {
          margin: 0;
          background: var(--bg);
          color: var(--fg);
          font: 16px/1.75 -apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", sans-serif;
          letter-spacing: 0.02em;
          -webkit-user-select: text;
          user-select: text;
        }
        main {
          box-sizing: border-box;
          max-width: 860px;
          margin: 0 auto;
          padding: 32px 36px 48px;
        }
        /* 限制正文阅读宽度，保持黄金排版比例 */
        h1, h2, h3, h4, h5, h6, p, ul, ol, blockquote, dl, .reading-meta {
          max-width: 720px;
          box-sizing: border-box;
        }
        h1, h2, h3, h4, h5, h6 {
          line-height: 1.25;
          margin: 1.45em 0 .55em;
          font-weight: 700;
        }
        h1:first-child, h2:first-child, h3:first-child { margin-top: 0; }
        h1 { font-size: 2rem; padding-bottom: .35em; border-bottom: 1px solid var(--border); }
        h2 { font-size: 1.5rem; padding-bottom: .25em; border-bottom: 1px solid var(--border); }
        h3 { font-size: 1.2rem; }
        p, ul, ol, blockquote, pre, table, hr, figure { margin: 0 0 1em; }
        ul, ol { padding-left: 1.45em; }
        li > ul, li > ol { margin: .25em 0 .25em; }
        dl { margin: 0 0 1em; }
        dt { font-weight: 700; margin-top: .75em; }
        dd { margin: .2em 0 .45em 1.25em; color: var(--fg); }
        a { color: var(--link); text-decoration: none; }
        a:hover { text-decoration: underline; }
        .link-external::after {
          content: "↗";
          font-size: .72em;
          margin-left: .18em;
          color: var(--muted);
        }
        .link-mail::before {
          content: "✉ ";
          color: var(--muted);
          font-size: .86em;
        }
        .link-unsafe {
          color: var(--muted);
          text-decoration: line-through;
          cursor: not-allowed;
        }
        del { color: var(--muted); }
        mark {
          background: linear-gradient(180deg, transparent 35%, var(--mark-highlight) 35%);
          color: inherit;
          padding: 0 4px;
          border-radius: 2px;
        }
        hr {
          border: 0;
          border-top: 1px solid var(--border);
          margin: 1.6em 0;
        }
        blockquote {
          color: var(--quote);
          border-left: 4px solid var(--quote-border);
          padding: 10px 16px;
          background: var(--quote-bg);
          border-radius: 0 6px 6px 0;
          font-style: italic;
        }
        blockquote > :last-child { margin-bottom: 0; }
        .callout {
          color: var(--fg);
          background: color-mix(in srgb, var(--code-bg) 72%, transparent);
          border: 1px solid var(--border);
          border-left-width: 4px;
          border-radius: 8px;
          padding: 12px 14px;
          max-width: 720px;
        }
        .callout-info { border-left-color: var(--callout-info); }
        .callout-note { border-left-color: var(--callout-note); }
        .callout-tip { border-left-color: var(--callout-tip); }
        .callout-important { border-left-color: var(--callout-important); }
        .callout-warning { border-left-color: var(--callout-warning); }
        .callout-caution { border-left-color: var(--callout-caution); }
        .callout strong {
          display: inline-block;
          margin-bottom: .15em;
        }
        code {
          font-family: "SF Mono", Menlo, Consolas, monospace;
          font-size: .92em;
          background: var(--code-bg);
          border: 1px solid var(--code-border);
          border-radius: 4px;
          padding: .12em .3em;
        }
        pre {
          overflow: auto;
          background: var(--code-bg);
          border: 1px solid var(--border);
          border-radius: 8px;
          padding: 14px 16px;
        }
        .code-block {
          border: 1px solid var(--border);
          border-radius: 8px;
          overflow: hidden;
          background: var(--code-bg);
        }
        .code-block figcaption {
          color: var(--muted);
          border-bottom: 1px solid var(--border);
          font: 12px/1.4 "SF Mono", Menlo, Consolas, monospace;
          padding: 6px 12px;
        }
        .code-note {
          color: var(--muted);
          border-bottom: 1px solid var(--border);
          font-size: 13px;
          padding: 8px 12px;
        }
        .code-block-mermaid {
          background:
            linear-gradient(90deg, color-mix(in srgb, var(--link) 8%, transparent), transparent 46%),
            var(--code-bg);
        }
        .code-block pre {
          border: 0;
          border-radius: 0;
          margin: 0;
        }
        .math-source {
          font-family: "SF Mono", Menlo, Consolas, monospace;
          color: var(--fg);
          background: color-mix(in srgb, var(--mark-bg) 42%, transparent);
          border: 1px solid var(--code-border);
          border-radius: 4px;
          padding: .08em .28em;
        }
        .math-block {
          border: 1px solid var(--border);
          border-radius: 8px;
          overflow: hidden;
          background: color-mix(in srgb, var(--mark-bg) 24%, var(--code-bg));
        }
        .math-block figcaption {
          color: var(--muted);
          border-bottom: 1px solid var(--border);
          font-size: 13px;
          padding: 8px 12px;
        }
        .math-block pre {
          border: 0;
          border-radius: 0;
          margin: 0;
        }
        .front-matter {
          color: var(--muted);
          border: 1px solid var(--border);
          border-radius: 8px;
          margin: 0 0 1em;
          background: color-mix(in srgb, var(--code-bg) 70%, transparent);
          max-width: 720px;
        }
        .front-matter summary {
          cursor: default;
          padding: 8px 12px;
          font-size: 13px;
        }
        .front-matter pre {
          border: 0;
          border-top: 1px solid var(--border);
          border-radius: 0;
          margin: 0;
        }
        pre code {
          background: transparent;
          border: 0;
          padding: 0;
          white-space: pre;
        }
        .tok-keyword { color: #cf222e; font-weight: 600; }
        .tok-string { color: #0a7b42; }
        .tok-comment { color: var(--muted); font-style: italic; }
        .tok-key { color: #8250df; }
        .tok-number, .tok-literal { color: #0550ae; }
        @media (prefers-color-scheme: dark) {
          .tok-keyword { color: #ff7b72; }
          .tok-string { color: #7ee787; }
          .tok-key { color: #d2a8ff; }
          .tok-number, .tok-literal { color: #79c0ff; }
        }
        table {
          border-collapse: collapse;
          width: 100%;
          display: block;
          overflow-x: auto;
        }
        th, td {
          border: 1px solid var(--border);
          padding: 6px 10px;
          text-align: left;
        }
        th { background: var(--code-bg); }
        tr:nth-child(even) td { background: color-mix(in srgb, var(--code-bg) 38%, transparent); }
        img {
          max-width: 100%;
          height: auto;
          border-radius: 6px;
        }
        .image-figure {
          display: block;
          border: 1px solid var(--border);
          border-radius: 8px;
          overflow: hidden;
          background: color-mix(in srgb, var(--code-bg) 46%, transparent);
        }
        .markdown-image {
          display: block;
          width: auto;
          max-width: 100%;
          margin: 0 auto;
          background: var(--code-bg);
        }
        .image-figure figcaption {
          color: var(--muted);
          font-style: italic;
          font-size: 13px;
          text-align: center;
          padding: 10px 16px;
        }
        .image-remote figcaption::before {
          content: "remote · ";
        }
        .task-list-item { list-style: none; margin-left: -1.4em; }
        .task-list-item label {
          display: inline-flex;
          align-items: baseline;
          gap: .45em;
        }
        .task-list-item input { margin: 0; }
        .image-placeholder {
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          gap: 8px;
          min-height: 90px;
          border: 1px dashed var(--border);
          border-radius: 6px;
          color: var(--muted);
          background: color-mix(in srgb, var(--code-bg) 50%, transparent);
          padding: 18px;
          margin: 6px;
          font-size: 13px;
          text-align: center;
        }
        .placeholder-icon {
          color: var(--muted);
          opacity: 0.65;
          flex-shrink: 0;
        }
        .placeholder-text {
          font-family: "SF Mono", Menlo, Consolas, monospace;
          word-break: break-all;
        }
        .footnote-ref {
          font-size: .78em;
          line-height: 0;
        }
        .footnotes {
          color: var(--muted);
          font-size: .92em;
          margin-top: 2em;
        }
        .footnotes ol {
          padding-left: 1.3em;
        }
        .footnotes li:target {
          color: var(--fg);
        }
        .footnote-backref {
          font-size: .9em;
          margin-left: .25em;
        }
        .error-page {
          color: var(--muted);
          border: 1px solid var(--border);
          border-radius: 8px;
          padding: 22px 24px;
          margin-top: 18px;
          background: color-mix(in srgb, var(--code-bg) 50%, transparent);
        }
        .error-page h1 {
          color: var(--fg);
          border-bottom: 0;
          font-size: 1.45rem;
          margin: .1em 0 .45em;
          padding: 0;
        }
        .error-page p {
          margin-bottom: .65em;
        }
        .error-kicker {
          color: var(--muted);
          font-size: 12px;
          font-weight: 700;
          letter-spacing: .04em;
          text-transform: uppercase;
        }
        .error-guidance {
          color: var(--fg);
        }
        .source-mode-label {
          color: var(--muted);
          margin-bottom: 12px;
        }
        .source-mode {
          white-space: pre;
        }
        .reading-meta {
          display: flex;
          flex-wrap: wrap;
          gap: 16px;
          color: var(--muted);
          font-size: 13px;
          margin-bottom: 24px;
          padding-bottom: 12px;
          border-bottom: 1px dashed var(--border);
        }
        .meta-item {
          display: inline-flex;
          align-items: center;
          gap: 6px;
        }
        .meta-icon {
          stroke: var(--muted);
          opacity: 0.85;
          flex-shrink: 0;
        }
        </style>
        </head>
        <body><main>
        \(body)
        </main></body>
        </html>
        """
    }

    static func sourceDocument(markdown: String, fileName: String) -> String {
        document(
            body: """
            <p class="source-mode-label">Rendered preview is disabled. Showing Markdown source for \(HTMLEscaping.text(fileName)).</p>
            <pre class="source-mode"><code>\(HTMLEscaping.text(markdown))</code></pre>
            """
        )
    }
}
