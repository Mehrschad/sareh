# سره — کارهای همیشگی.
#
#   make bootstrap   یک بار، پس از clone
#   make check       همان چیزی که CI اجرا می‌کند
#   make run         اجرای اپ

.DEFAULT_GOAL := help
.PHONY: help bootstrap content-sync fonts tokens validate design core app check run clean

APP        := app
CONTENT    := content
APP_ASSETS := $(APP)/assets/content
FONT_DIR   := design/fonts

help: ## این فهرست
	@grep -hE '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

bootstrap: content-sync fonts ## نصبِ همه‌چیز پس از clone
	cargo fetch
	cd $(APP) && flutter pub get
	@echo "✓ آماده. حالا: make check"

content-sync: ## کپیِ content/ به دارایی‌های اپ
	@# content/ بیرونِ بسته‌ی Flutter است تا یک منبعِ حقیقت بیشتر نداشته باشیم؛
	@# Flutter نمی‌تواند به بیرونِ بسته اشاره کند، پس اینجا کپی می‌شود.
	@rm -rf $(APP_ASSETS)
	@mkdir -p $(APP_ASSETS)
	@cp -r $(CONTENT)/words $(CONTENT)/lessons $(CONTENT)/corpus $(APP_ASSETS)/
	@cp $(CONTENT)/NO_EQUIVALENT.yaml $(APP_ASSETS)/
	@echo "✓ $$(find $(APP_ASSETS)/words -name '*.yaml' | wc -l | tr -d ' ') واژه همگام شد."

fonts: ## گرفتنِ قلم‌ها (پروانه‌شان جداست، پس در مخزن نیستند)
	@mkdir -p $(FONT_DIR)
	@if [ -f "$(FONT_DIR)/Vazirmatn-Regular.ttf" ]; then \
		echo "✓ قلم‌ها هستند."; \
	else \
		echo "قلم‌ها را دستی بگذارید در $(FONT_DIR)/ :"; \
		echo "  وزیرمتن (SIL OFL)  https://github.com/rastikerdar/vazirmatn"; \
		echo "  مربا    (SIL OFL)  https://github.com/sahaf-io/Morabba"; \
		echo "  استعداد (SIL OFL)  https://github.com/aminabedi68/Estedad"; \
	fi

tokens: ## بازتولیدِ tokens.g.dart از tokens.json
	dart run tools/gen_tokens.dart

validate: ## سنجشِ محتوا — طرح‌واره، منبع، تکراری، ارجاعِ درس‌ها
	cargo run --release -p sareh-tools --bin validate_words -- --stats

design: ## سنجشِ کنتراست و توکن‌های هارد‌کد
	python3 tools/check_design.py

core: ## آزمون و لینتِ هسته‌ی Rust
	cargo fmt --all --check
	cargo clippy --workspace --all-targets -- -D warnings
	cargo test --workspace

app: content-sync ## تحلیل و آزمونِ اپ
	cd $(APP) && flutter analyze && flutter test

check: validate design core app ## همه‌ی سنجش‌های CI
	@echo "✓ همه‌چیز تمیز است."

run: content-sync ## اجرای اپ
	cd $(APP) && flutter run

clean: ## پاک‌کردنِ خروجی‌های ساخت
	cargo clean
	cd $(APP) && flutter clean
	rm -rf $(APP_ASSETS)
