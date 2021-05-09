
install-worldlib:
	git submodule update --init --recursive
	cp -r World/src/. Sources/WorldLib/
