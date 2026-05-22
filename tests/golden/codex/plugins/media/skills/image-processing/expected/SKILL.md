---
name: image-processing
description:
  Validate SVG inputs and convert SVG, PNG, JPEG, or WebP files through the nils-cli `image-processing` command.
---

# Image Processing

## Contract

Prereqs:

- `image-processing` is installed from the released nils-cli package and available on `PATH`.
- Input and output paths are explicit.
- Existing output files are preserved unless `--overwrite` is intentional.

Inputs:

- One SVG, PNG, JPEG, JPG, or WebP input path.
- Output format `png`, `webp`, or `jpg`.
- Optional width, height, dry-run, overwrite, or report mode.

Outputs:

- Converted raster file, SVG validation report, or JSON-friendly processing report.

Failure modes:

- Input format is unsupported or unreadable.
- Output exists and overwrite was not allowed.
- SVG validation fails or conversion backend reports an error.

## Entrypoint

Use the released CLI directly:

```bash
image-processing convert --in icon.svg --to png --out icon.png
image-processing convert --in photo.jpg --to webp --out photo.webp --width 1200
image-processing svg-validate --in icon.svg --out validated.svg --json
```

## Workflow

1. Validate SVGs before conversion when the file came from an untrusted or generated source.
2. Use `--dry-run` or `--report` when planning a batch change.
3. Choose explicit dimensions only when the requested output size is known.
4. Report command failures and avoid silently substituting a different output format.

## Boundary

`image-processing` owns validation and conversion mechanics. The caller owns deciding whether the edited media should be committed, regenerated, or treated as a temporary artifact.
