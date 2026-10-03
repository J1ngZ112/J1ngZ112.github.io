# Gallery photos

Put photos for the gallery in this folder.

Use paths like `/gallery/photos/my-photo.jpg` in `content/page/gallery/index.md`:

```yaml
image: "/gallery/photos/my-photo.jpg"
```

Supported formats include JPG, JPEG, PNG, and WebP. HEIC/HEIF is not recommended because Chrome and Firefox may not display it. On macOS, convert a HEIC photo before adding it to the gallery:

```sh
sips -s format jpeg my-photo.HEIC --out my-photo.jpg
```

Then reference the converted file in `content/page/gallery/index.md`:

```yaml
image: "/gallery/photos/my-photo.jpg"
```
