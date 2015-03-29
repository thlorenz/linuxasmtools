
#
# usage:  make doc
#
 
# the following variables are probably ok

#local = $(shell pwd)
#home = $(HOME)
#SHELL = /bin/bash
#here = $(shell pwd)



doc:
	find . -depth -name '*~' -exec rm -f '{}' \;
# Due to a ongoing problem where weex uploads all packages,
# the following have been disabled.
# "make release" must build the releases for web page first.
#	./delete_if "out/*.gz" ../release
#	./delete_if "out/*.deb" ../release
#	./delete_if "out/*.rpm" ../release
#	./copy -n ".gz" "../release/*.gz" "out/*.gz"
#	./copy -n ".deb" "../release/*.deb" "out/*.deb"
#	./copy -n ".rpm" "../release/*.rpm" "out/*.rpm"
#	./tool/domenu
#	./tool/domenux

