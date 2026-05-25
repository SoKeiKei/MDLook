# Local Images

This image uses a local relative path and should render:

![Local sample](assets/sample.svg)

This image uses Chinese characters and a space in the filename:

![中文 sample](assets/示例 图片.svg)

This image is missing and should become a lightweight placeholder:

![Missing sample](assets/missing.png)

This remote image should be blocked by default:

![Remote sample](https://upload.wikimedia.org/wikipedia/commons/4/48/Markdown-mark.svg "Remote Markdown logo")

Open MDLook and enable "Allow Remote Images" to verify the same network image can load in Quick Look.
