BUILD_DIR := ./build
.PHONY: trojan-gfw trojan-go
all: trojan-gfw trojan-go

clean:
	rm -rf $(BUILD_DIR)

trojan-gfw:
	mkdir -p $(BUILD_DIR)
	# -j flag will tore just the name of a saved file (junk the path), and do not store directory names.
	zip -rj $(BUILD_DIR)/payload_trojan_gfw.zip ./trojan-gfw

trojan-go:
	mkdir -p $(BUILD_DIR)
	zip -rj $(BUILD_DIR)/payload_trojan_go.zip ./trojan-go