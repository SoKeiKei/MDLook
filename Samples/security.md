# Security Sample

Raw HTML and scripts should not execute.

<script>alert("This should never run")</script>

<img src=x onerror=alert(1)>

Remote images should not load:

![Remote](https://example.com/tracker.png)

Links remain visible as links:

[Example](https://example.com)

