{ pkgs, ... }:

let
  officePython = pkgs.python3.withPackages (ps: with ps; [
    # PDF extraction/manipulation and OCR wrappers
    pymupdf
    pypdf
    pdf2image
    pytesseract

    # Office Open XML parsing/editing
    python-docx
    openpyxl
    python-pptx

    # Markitdown-based extraction used by office skills
    markitdown

    # Image support for thumbnails/OCR pipelines
    pillow
  ]);
in
{
  environment.systemPackages = with pkgs; [
    officePython

    # PDF/text extraction and slide rendering helpers
    poppler-utils
    pandoc

    # DOC/DOCX/PPTX conversion/rendering via soffice/libreoffice
    libreoffice

    # OCR engine used through pytesseract; language data can be added later if needed
    tesseract

    # JS-based document generation libraries used by Anthropic docx/pptx skills
    nodejs
  ];
}
