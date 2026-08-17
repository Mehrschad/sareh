# سره — کارهای همیشگی.
#
#   make bootstrap   یک بار، پس از clone
#   make check       همان چیزی که CI اجرا می‌کند
#   make run         اجرای اپ

.DEFAULT_GOAL := help
.PHONY: help bootstrap bridge content-sync fonts tokens validate design core app check run clean

APP        := app
CONTENT    := content
APP_ASSETS := $(APP)/assets/content
FONT_DIR   := design/fonts

help: ## این فهرست
	@grep -hE '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

bootstrap: content-sync fonts bridge ## نصبِ همه‌چیز پس از clone
	cd $(APP) && flutter pub get
	@echo "✓ آماده. حالا: make check"

bridge: ## تولیدِ چسبِ Dart↔Rust و ساختِ کتابخانه‌ی بومی
	@# خروجی در git نیست: کدِ تولیدشده به نسخه‌ی codegen گره خورده و
	@# نگه‌داشتنش در مخزن یعنی دو حقیقت.
	@command -v flutter_rust_bridge_codegen >/dev/null 2>&1 || { \
		echo "flutter_rust_bridge_codegen نیست. نصب:"; \
		echo "  cargo install flutter_rust_bridge_codegen --version ^2 --locked"; \
		exit 1; }
	flutter_rust_bridge_codegen generate
	@# آزمون‌ها کتابخانه را از target/ برمی‌دارند، پس همین‌جا ساخته می‌شود.
	cargo build --release -p sareh-core --features bridge
	@echo "✓ پل آماده است."

content-sync: ## کپیِ content/ به دارایی‌های اپ
	@# content/ بیرونِ بسته‌ی Flutter است تا یک منبعِ حقیقت بیشتر نداشته باشیم؛
	@# Flutter نمی‌تواند به بیرونِ بسته اشاره کند، پس اینجا کپی می‌شود.
	@rm -rf $(APP_ASSETS)
	@mkdir -p $(APP_ASSETS)
	@cp -r $(CONTENT)/words $(CONTENT)/lessons $(CONTENT)/corpus $(APP_ASSETS)/
	@cp $(CONTENT)/NO_EQUIVALENT.yaml $(APP_ASSETS)/
	@echo "✓ $$(find $(APP_ASSETS)/words -name '*.yaml' | wc -l | tr -d ' ') واژه همگام شد."

fonts: ## گرفتنِ قلم‌ها (پروانه‌شان جداست، پس در مخزن نیستند)
	@# هر دو زیر SIL OFL 1.1 اند و آزادانه پخش می‌شوند؛ در مخزن نیستند تا
	@# پروانه‌ی قلم با پروانه‌ی کد قاتی نشود. اینجا از خودِ مخزنِ سازنده
	@# گرفته می‌شوند، پس همیشه نسخه‌ی رسمی است.
	@mkdir -p $(FONT_DIR)
	@set -e; \
	for spec in \
		"rastikerdar/vazirmatn:Vazirmatn-Regular" \
		"rastikerdar/vazirmatn:Vazirmatn-Medium" \
		"rastikerdar/vazirmatn:Vazirmatn-SemiBold" \
		"rastikerdar/vazirmatn:Vazirmatn-Bold" \
		"aminabedi68/Estedad:Estedad-Regular" \
		"aminabedi68/Estedad:Estedad-Bold" \
		"aminabedi68/Estedad:Estedad-Black" ; \
	do \
		repo=$${spec%%:*}; name=$${spec##*:}; \
		if [ -f "$(FONT_DIR)/$$name.ttf" ]; then continue; fi; \
		echo "  گرفتنِ $$name…"; \
		curl -sSLf -o "$(FONT_DIR)/$$name.ttf" \
			"https://raw.githubusercontent.com/$$repo/master/fonts/ttf/$$name.ttf" \
			|| { echo "✗ $$name گرفته نشد"; rm -f "$(FONT_DIR)/$$name.ttf"; exit 1; }; \
	done; \
	echo "✓ قلم‌ها آماده‌اند (SIL OFL 1.1)."

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
