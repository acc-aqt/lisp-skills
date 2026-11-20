IMAGE ?= lisp-skills-allegro

.PHONY: check check-lisp-check check-examples check-export check-issue-form docker-check export

check: check-lisp-check check-examples check-export check-issue-form

check-lisp-check:
	sh tests/lisp-check/test.sh

check-examples:
	sh tests/examples/test.sh

check-export:
	sh tests/export/test.sh

check-issue-form:
	sh tests/issue-form/test.sh

docker-check:
	docker run --rm --platform linux/amd64 -v "$(CURDIR)":/work $(IMAGE) make check

export:
	sh scripts/export-rules
