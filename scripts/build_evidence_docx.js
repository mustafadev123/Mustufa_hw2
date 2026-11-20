import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import {
  AlignmentType,
  Document,
  Footer,
  HeadingLevel,
  ImageRun,
  Packer,
  PageNumber,
  Paragraph,
  TextRun,
} from 'docx';
import { imageSize } from 'image-size';

const sourcePath = resolve('evidence/HW02_EVIDENCE.md');
const outputPath = resolve('submission/HW02_Muhammad_Mustufa_Evidence.docx');
const sourceDirectory = dirname(sourcePath);
const lines = readFileSync(sourcePath, 'utf8').split(/\r?\n/);

function plain(text) {
  return text
    .replace(/!\[([^\]]*)\]\([^)]*\)/g, '$1')
    .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '$1 ($2)')
    .replace(/\*\*([^*]+)\*\*/g, '$1')
    .replace(/`([^`]+)`/g, '$1')
    .replace(/^_([^_]+)_$/, '$1');
}

const children = [];
let inCode = false;
for (const line of lines) {
  if (line.startsWith('```')) {
    inCode = !inCode;
    continue;
  }
  const image = line.match(/^!\[([^\]]*)\]\(([^)]+)\)$/);
  if (image) {
    const path = join(sourceDirectory, image[2]);
    const data = readFileSync(path);
    const dimensions = imageSize(data);
    const width = 500;
    const height = Math.round((dimensions.height / dimensions.width) * width);
    children.push(new Paragraph({
      alignment: AlignmentType.CENTER,
      children: [new ImageRun({ data, transformation: { width, height }, type: 'png' })],
      spacing: { before: 120, after: 120 },
    }));
    continue;
  }
  const heading = line.match(/^(#{1,4})\s+(.+)$/);
  if (heading) {
    const levels = [HeadingLevel.TITLE, HeadingLevel.HEADING_1, HeadingLevel.HEADING_2, HeadingLevel.HEADING_3];
    children.push(new Paragraph({ text: plain(heading[2]), heading: levels[heading[1].length - 1] }));
    continue;
  }
  if (line.trim() === '---') {
    children.push(new Paragraph({ text: '________________________________________________________________' }));
    continue;
  }
  if (line.trim() === '') {
    children.push(new Paragraph({ text: '' }));
    continue;
  }
  const bullet = line.match(/^[-*]\s+(.+)$/);
  const numbered = line.match(/^\d+\.\s+(.+)$/);
  const table = line.startsWith('|');
  children.push(new Paragraph({
    children: [new TextRun({
      text: plain(table ? line.split('|').filter(Boolean).map((value) => value.trim()).join('  |  ') : (bullet?.[1] ?? numbered?.[1] ?? line)),
      font: inCode || table ? 'Consolas' : 'Aptos',
      size: inCode || table ? 18 : 22,
    })],
    bullet: bullet ? { level: 0 } : undefined,
    numbering: numbered ? { reference: 'evidence-numbering', level: 0 } : undefined,
    spacing: { after: 100, line: 276 },
  }));
}

const document = new Document({
  creator: 'Muhammad Mustufa',
  title: 'Homework 02 — Message Board Vault Hunt Evidence',
  description: 'Graduate reflection, test matrix, and evidence for CSC 4360 Homework 02.',
  numbering: {
    config: [{ reference: 'evidence-numbering', levels: [{ level: 0, format: 'decimal', text: '%1.', alignment: AlignmentType.START }] }],
  },
  styles: {
    default: { document: { run: { font: 'Aptos', size: 22 } } },
    paragraphStyles: [{ id: 'Title', name: 'Title', basedOn: 'Normal', next: 'Normal', run: { size: 36, bold: true, color: '5D4037' }, paragraph: { alignment: AlignmentType.CENTER, spacing: { after: 300 } } }],
  },
  sections: [{
    properties: { page: { margin: { top: 720, right: 720, bottom: 720, left: 720 } } },
    children,
    footers: { default: new Footer({ children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun('Muhammad Mustufa — HW02 — Page '), new TextRun({ children: [PageNumber.CURRENT] })] })] }) },
  }],
});

writeFileSync(outputPath, await Packer.toBuffer(document));
console.log(`Wrote ${outputPath}`);
