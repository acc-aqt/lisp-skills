.PHONY: check check-export check-issue-form

check: check-export check-issue-form

check-export:
	sh tests/export/test.sh

check-issue-form:
	sh tests/issue-form/test.sh
