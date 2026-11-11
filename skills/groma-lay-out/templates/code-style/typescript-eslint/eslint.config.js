// ESLint flat config with typescript-eslint: https://typescript-eslint.io/getting-started
import { defineConfig } from "eslint/config";
import js from "@eslint/js";
import tseslint from "typescript-eslint";

export default defineConfig(js.configs.recommended, tseslint.configs.recommended);
