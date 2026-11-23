IMAGE ?= lisp-skills-allegro

.PHONY: check check-lisp-check check-lisp-image check-examples check-mutants check-export check-issue-form docker-check export

check: check-lisp-check check-lisp-image check-examples check-mutants check-export check-issue-form

check-lisp-check:
	sh tests/lisp-check/test.sh

check-lisp-image:
	sh tests/lisp-image/test.sh

check-examples:
	sh tests/examples/test.sh

check-mutants:
	sh tests/mutants/test.sh

check-export:
	sh tests/export/test.sh

check-issue-form:
	sh tests/issue-form/test.sh

docker-check:
	docker run --rm --init --platform linux/amd64 -v "$(CURDIR)":/work $(IMAGE) make check

export:
	sh scripts/export-rules
