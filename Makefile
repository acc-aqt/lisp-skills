.PHONY: check check-export

check: check-export

check-export:
	sh tests/export/test.sh
