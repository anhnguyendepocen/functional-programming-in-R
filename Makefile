BUILD_DIR := gen

PANDOC := pandoc

PANDOC_OPTS_ALL :=  -S --toc \
					--top-level-division=chapter \
					--filter pandoc-fignos
PANDOC_PDF_OPTS := $(PANDOC_OPTS_ALL) \
					--default-image-extension=pdf \
					--variable links-as-notes \
					--template=templates/latex-template.tex
PANDOC_PRINT_OPTS := $(PANDOC_PDF_OPTS) --no-highlight
PANDOC_EPUB_OPTS := $(PANDOC_OPTS_ALL) \
					--default-image-extension=png \
					-t epub3 --toc-depth=1 \
					--epub-cover-image=cover.png

#CHAPTERS := 000_header.md \
			06_point_free_programming.md \
			07_conclusions.md

CHAPTERS := 000_header.md \
			00_Introduction.md \
			01_functions_in_R.md \
			02_pure_functional_programming.md \
			03_scope_and_closures.md \
			04_higher_order_functions.md \
			05_filter_map_and_reduce.md \
			06_point_free_programming.md \
			07_conclusions.md


book.pdf: pdf_book.md templates/latex-template.tex
	$(PANDOC) $(PANDOC_PDF_OPTS) -o $@ pdf_book.md

print_book.pdf: pdf_book.md templates/latex-template.tex
		$(PANDOC) $(PANDOC_PRINT_OPTS) -o $@ pdf_book.md

book.epub: ebook.md
	$(PANDOC) $(PANDOC_EPUB_OPTS) -o $@ ebook.md

book.mobi: book.epub
	./kindlegen book.epub -o book.mobi

pdf_book.md: $(CHAPTERS) Makefile
	cat $(CHAPTERS) | gpp -DPDF > pdf_book.Rmd
	./runknitr.sh pdf_book.Rmd
	rm pdf_book.Rmd

ebook.md: $(CHAPTERS) Makefile
	cat $(CHAPTERS) | gpp -DEPDF > ebook.Rmd
	./runknitr.sh ebook.Rmd
	rm ebook.Rmd

all: book.pdf book.epub book.mobi

%.md: %.Rmd
	./runknitr.sh $<

clean:
	rm book.pdf book.epub book.mobi pdf_book.Rmd ebook.Rmd
	rm pdf_book.md ebook.md
