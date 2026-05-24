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
          --quote: #6b7280;
          --link: #0969da;
        }
        @media (prefers-color-scheme: dark) {
          :root {
            --bg: #0f1115;
            --fg: #e6edf3;
            --muted: #9aa4b2;
            --border: #30363d;
            --code-bg: #171b22;
            --quote: #a0a8b7;
            --link: #7db7ff;
          }
        }
        body {
          margin: 0;
          background: var(--bg);
          color: var(--fg);
          font: 15px/1.65 -apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", sans-serif;
        }
        main {
          box-sizing: border-box;
          max-width: 860px;
          margin: 0 auto;
          padding: 32px 36px 48px;
        }
        h1, h2, h3, h4, h5, h6 {
          line-height: 1.25;
          margin: 1.45em 0 .55em;
          font-weight: 700;
        }
        h1 { font-size: 2rem; padding-bottom: .35em; border-bottom: 1px solid var(--border); }
        h2 { font-size: 1.5rem; padding-bottom: .25em; border-bottom: 1px solid var(--border); }
        h3 { font-size: 1.2rem; }
        p, ul, ol, blockquote, pre, table { margin: 0 0 1em; }
        a { color: var(--link); text-decoration: none; }
        a:hover { text-decoration: underline; }
        blockquote {
          color: var(--quote);
          border-left: 4px solid var(--border);
          padding: .1em 0 .1em 1em;
        }
        code {
          font-family: "SF Mono", Menlo, Consolas, monospace;
          font-size: .92em;
          background: var(--code-bg);
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
        pre code { background: transparent; padding: 0; }
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
        img {
          max-width: 100%;
          height: auto;
          border-radius: 6px;
        }
        .task-list-item { list-style: none; margin-left: -1.4em; }
        .task-list-item input { margin-right: .45em; }
        .image-placeholder {
          border: 1px dashed var(--border);
          border-radius: 6px;
          color: var(--muted);
          padding: 10px 12px;
          margin: .35em 0 1em;
        }
        .error {
          color: var(--muted);
          border: 1px solid var(--border);
          border-radius: 8px;
          padding: 18px;
          margin-top: 18px;
        }
        </style>
        </head>
        <body><main>
        \(body)
        </main></body>
        </html>
        """
    }
}

