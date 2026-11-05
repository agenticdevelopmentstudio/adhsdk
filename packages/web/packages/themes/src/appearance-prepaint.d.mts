export declare const APPEARANCE_STORAGE_KEY: "adh:appearance"
export declare const ENUM_PREF_DEFAULTS: {
  readonly reduceMotion: "auto"
  readonly contrast: "default"
  readonly textSize: "default"
  readonly spacing: "compact"
}
export declare const BOOL_PREFS: readonly ["focusOutlines", "underlineLinks"]
export declare const APPEARANCE_PREPAINT_SCRIPT: string
/** A Vite plugin (structurally typed, so this package needs no vite dependency). */
export declare function appearancePrepaint(): {
  name: string
  transformIndexHtml: () => { tag: "script"; children: string; injectTo: "head" }[]
}
