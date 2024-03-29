install-worldlib:
	git submodule update --init --recursive
	cp -r World/src/. Sources/WorldLib/
	patch -p1 < fix-world-header-path.patch

clean-worldlib:
	rm -rf Sources/WorldLib/*.cpp
	rm -r Sources/WorldLib/world

lint:
	swift run --package-path ./tools swiftlint autocorrect --format
	swift run --package-path ./tools swiftlint
