# Copyright (c) Facebook, Inc. and its affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

TESTS_DIR = ../../..

CLANG_OPTIONS = -c $(OBJC_CLANG_OPTIONS) -fobjc-arc
INFER_OPTIONS = --config-gating-only --debug-exceptions \
  --config-gating-method 'ConfigGating\.getConfigFlag:' \
  --config-gating-method 'Config\.isEnabled:' \
  --config-gating-method 'Config\.getValue:' \
  --config-gating-report-ungated
INFERPRINT_OPTIONS = --issues-tests

SOURCES = $(wildcard *.m)

include $(TESTS_DIR)/clang.make
include $(TESTS_DIR)/objc.make

infer-out/report.json: $(MAKEFILE_LIST)
