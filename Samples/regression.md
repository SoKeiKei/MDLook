# Renderer Regression Sample

Use this file after renderer changes. It is intentionally compact and covers the cases most likely to regress in Quick Look.

## Nested Lists

- parent
  - child with `inline code`
  - ~~removed~~ text
- second parent

1. first
   1. nested ordered
   2. nested second
2. next

## Mixed Text

中文 English mixed text with **bold**, *italic*, `code`, and ~~deleted text~~ should keep spacing readable.

## Safety

This link should render but should not keep the dangerous destination:

[unsafe](javascript:alert(1))

Raw HTML should be removed:

<script>alert("nope")</script>
