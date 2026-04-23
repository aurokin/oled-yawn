BIN      := oled-yawn
PREFIX   ?= $(HOME)/.local/bin
CONFIG   ?= release

BUILD_BIN := .build/$(CONFIG)/$(BIN)

build:
	swift build -c $(CONFIG)
	cp $(BUILD_BIN) $(BIN)

$(BIN): build

test:
	swift test

lint:
	./scripts/lint.sh

install: $(BIN)
	install -d $(PREFIX)
	install -m 0755 $(BIN) $(PREFIX)/$(BIN)

clean:
	rm -rf .build $(BIN)

.PHONY: build test lint install clean
