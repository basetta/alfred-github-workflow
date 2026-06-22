BUNDLE := github-alfred.alfredworkflow
SRC_DIR := workflow
SRC_FILES := info.plist repos.sh open_or_focus.applescript switch_list.sh switch_do.sh icon.png repo.png

.PHONY: build clean install

build: $(BUNDLE)

$(BUNDLE): $(addprefix $(SRC_DIR)/,$(SRC_FILES))
	cd $(SRC_DIR) && zip -r ../$(BUNDLE) $(SRC_FILES) -x "*.DS_Store"

clean:
	rm -f $(BUNDLE)

install: build
	open $(BUNDLE)
