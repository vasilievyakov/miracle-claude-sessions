.PHONY: build install run clean test lint

TESTING_FLAGS = -Xswiftc -F/Library/Developer/CommandLineTools/Library/Developer/Frameworks \
	-Xlinker -rpath -Xlinker /Library/Developer/CommandLineTools/Library/Developer/Frameworks

build:
	swift build -c release

install: build
	mkdir -p ~/Applications
	cp -f .build/release/ClaudeSessions ~/Applications/ClaudeSessions

run: build
	.build/release/ClaudeSessions

test:
	swift test $(TESTING_FLAGS)

lint:
	swiftlint lint --strict

clean:
	swift package clean
