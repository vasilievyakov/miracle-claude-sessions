.PHONY: build install run clean

build:
	swift build -c release

install: build
	mkdir -p ~/Applications
	cp -f .build/release/ClaudeSessions ~/Applications/ClaudeSessions

run: build
	.build/release/ClaudeSessions

clean:
	swift package clean
