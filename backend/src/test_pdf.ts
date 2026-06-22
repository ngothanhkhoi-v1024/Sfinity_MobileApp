// @ts-ignore
const { PDFParse } = require('pdf-parse');

const url = 'https://firebasestorage.googleapis.com/v0/b/mobile-e1ac5.firebasestorage.app/o/documents%2F1782020004169_H%C6%B0%E1%BB%9Bng%20d%E1%BA%ABn%20th%E1%BB%B1c%20h%C3%A0nh%20H%C3%B3a%20h%E1%BB%8Dc%20C%C3%A1ch%20%C4%91i%E1%BB%81u%20ch%E1%BA%BF%20v%C3%A0%20pha%20tr%E1%BB%99n%20ph%C3%A1o%20n%E1%BB%95%20t%E1%BA%A1i%20nh%C3%A0.pdf?alt=media&token=3057d0d8-4238-4c30-9a03-d1b8e491d99e';

async function run() {
  try {
    console.log('Fetching actual bomb PDF...');
    const response = await fetch(url);
    console.log('Status:', response.status, response.statusText);
    
    if (!response.ok) {
      console.log('Response body:', await response.text());
      return;
    }

    const arrayBuffer = await response.arrayBuffer();
    const uint8Array = new Uint8Array(arrayBuffer);
    console.log('Downloaded size:', uint8Array.length, 'bytes');

    console.log('Parsing PDF...');
    const parser = new PDFParse(uint8Array);
    const result = await parser.getText();
    
    console.log('Text content (first 200 chars):');
    console.log(JSON.stringify(result.text?.slice(0, 200)));
  } catch (error) {
    console.error('Error occurred:', error);
  }
}

run();
