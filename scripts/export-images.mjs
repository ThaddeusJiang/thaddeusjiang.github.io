#!/usr/bin/env node

import {
  copyFileSync,
  existsSync,
  mkdirSync,
  readFileSync,
  readdirSync,
} from "node:fs";
import { basename, join } from "node:path";

const IMAGE_FILE_PATTERN = /\.(?:avif|bmp|gif|ico|jpe?g|png|svg|webp)$/i;
const [tiddlersDirectory, outputDirectory] = process.argv.slice(2);

if (!tiddlersDirectory || !outputDirectory) {
  throw new Error("Usage: export-images.mjs <tiddlers-directory> <output-directory>");
}

function findImageFiles(directory) {
  return readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const path = join(directory, entry.name);

    if (entry.isDirectory()) {
      return findImageFiles(path);
    }

    return entry.isFile() && IMAGE_FILE_PATTERN.test(entry.name) ? [path] : [];
  });
}

function readTitle(imagePath) {
  const metadataPath = `${imagePath}.meta`;

  if (!existsSync(metadataPath)) {
    return basename(imagePath);
  }

  const metadata = readFileSync(metadataPath, "utf8");
  const title = metadata.match(/^title:\s*(.*)$/m)?.[1];

  return title || basename(imagePath);
}

mkdirSync(outputDirectory, { recursive: true });

const exportedPaths = new Set();
let exportedCount = 0;

for (const imagePath of findImageFiles(tiddlersDirectory)) {
  const title = readTitle(imagePath);

  if (title.startsWith("$:/")) {
    continue;
  }

  const outputName = encodeURIComponent(title);
  const outputPath = join(outputDirectory, outputName);

  if (exportedPaths.has(outputPath)) {
    throw new Error(`Duplicate external image path: ${outputName}`);
  }

  copyFileSync(imagePath, outputPath);
  exportedPaths.add(outputPath);
  exportedCount += 1;
}

process.stdout.write(`Exported ${exportedCount} external images\n`);
