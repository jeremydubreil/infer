# Copyright (c) Facebook, Inc. and its affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

TESTS_DIR=../../..

INFER_OPTIONS = --frontend-tests --dump-textual --project-root $(TESTS_DIR)

SOURCES = $(realpath $(wildcard *.swift.ll))

CLEAN_EXTRA = *.test.sil

include $(TESTS_DIR)/base.make

.NOTPARALLEL:

default: test

%.test.sil: %.ll
	$(QUIET)$(call silent_on_success,Testing handcrafted LL capture in $(TEST_REL_DIR),\
	  $(INFER_BIN) capture $(INFER_OPTIONS) --llvm-bitcode-file $< --llvm-bitcode-source $* )


capture: $(SOURCES:.ll=.test.sil)

.PHONY: print
print: capture

.PHONY: test
test: capture
	$(QUIET)error=0; for file in $(SOURCES) ; do \
	  base=$${file%.ll}; \
	  diff -u "$$base.sil" "$$base.test.sil" || error=1 ; \
	done ; \
	if [ $$error = 1 ]; then exit 1; fi

.PHONY: replace
replace: capture
	$(QUIET)for file in $(SOURCES) ; do \
	  base=$${file%.ll}; \
	  mv $$base.test.sil $$base.sil ; \
	done

.PHONY: clean
clean:
	$(REMOVE_DIR) infer-out *.test.sil $(CLEAN_EXTRA)
