FILES := $(shell find contents -type f) metadata.json

prokc: $(FILES)
	zip -FS -r -v prokc.plasmoid contents metadata.json

clean:
	rm -f prokc.plasmoid
