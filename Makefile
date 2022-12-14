BUILD := build
packages := intermissions two_loops three_loops blurer
REPO_intermissions = https://info-beamer.com/package/21456.git
REPO_two_loops = https://info-beamer.com/package/21265.git
REPO_three_loops = https://info-beamer.com/package/21563.git
REPO_blurer = https://info-beamer.com/package/35518.git

all: $(packages)

$(packages):
	rm -rf $(BUILD)/$@
	mkdir -p $(BUILD)/$@
	cp packages/$@/* $(BUILD)/$@/
	cp assets/* $(BUILD)/$@/
	cp overlay/overlay.squashfs $(BUILD)/$@/
	cp service.py $(BUILD)/$@/service
	cd $(BUILD)/$@ && \
		git init && \
		git add . && \
		git commit -a -m 'add files' && \
		git remote add beamer $(REPO_$@) && \
		git push --set-upstream beamer master --force

.PHONY: clean
clean:
	rm -rf $(BUILD)
