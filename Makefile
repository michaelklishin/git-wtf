DESTDIR = /usr/local/bin

.PHONY: default configure install

default: configure

configure: git-alias git-sh-alias

git-alias:
	git config --global alias.wtf '!git-wtf'

git-sh-alias:
	echo -e "\n# git-wtf\ngitalias wtf='git wtf'" >> ~/.gitshrc

install:
	install git-wtf ${DESTDIR}