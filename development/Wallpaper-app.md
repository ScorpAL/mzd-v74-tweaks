# Wallpaper app plan

Development branch: wallpaper, based on development. This is a design proposal,
not an implemented tweak or an additional supported firmware claim.

## Application

Add a Wallpaper entry under the original Mazda Applications menu. AutoX System
Tools demonstrates the relevant systemApp.js application-list and selection
hooks. Preserve other application entries and modifications. The installed app
must work without a USB drive; USB is needed only to import images.

The app provides USB image selection/import, a managed image gallery, a single
wallpaper or a selected slideshow, a configurable change interval, image deletion
and restoration of the original Mazda background. Define what happens when an
active image is deleted so no setting points to a missing file.

## Storage proposal

Prefer /tmp/mnt/data_persist over Resources for mutable images and settings.
Existing vehicle evidence shows this persistent partition mounted read-write;
Resources is normally read-only. Validate the actual mount and available space
before imports. Do not silently fall back to RAM or another partition.

Provisional directory: /tmp/mnt/data_persist/mzd-tweaks/wallpaper/, with images/
and settings.conf. The final path has not yet been agreed.

Provisional limits: 50 MiB total collection, 50 images and 2 MiB per image.
After each import, retain at least the greater of 64 MiB or 10% of partition
capacity as available space. Include staging files in space accounting, serialize
imports and recheck actual size/space before publishing each validated file.
Reject imports that exceed a limit; never automatically delete existing images.

## Required image dimensions — first version

Only import images whose decoded width and height exactly match the original
Mazda background asset used by this tweak on the supported firmware. Verify that
asset and its dimensions before implementation; do not infer the required size
solely from display resolution. Pixel dimensions are the criterion, not DPI
metadata, filename, compressed file size or aspect ratio alone.

Initially consider JPEG and PNG only, subject to verified CMU decoder support.
Read the actual image format/dimensions before copying it into the collection;
reject unreadable or invalid images and files with different dimensions. Show
the required and detected dimensions in the rejection message. A rejected image
must not remain in the managed collection. File-size and collection limits still
apply independently to images with correct dimensions.

The first version performs no resizing or cropping. A later optional import step
may resize and crop if suitable image-processing tools are verified on the CMU.
That step must produce and validate exactly the required output dimensions before
publishing the image. Do not assume such tools are present or add a dependency
for the first version.

## Runtime and lifecycle

Reuse the factory Lua runtime and the established JavaScript-to-shell contract.
The installed app needs its own persistent startup/lifecycle independent of the
USB installer. Review the background update hook separately from menu integration.
Keep slideshow changes in RAM/UI; persist only imports, deletions and changed
settings. Include owned app payload and startup/menu hooks in normal uninstall
and Restore originals; explicitly decide whether user images are kept or removed.
