## ZMK DTSI DSL (EDN/Hiccup style)

This document describes a DSL that emits ZMK Devicetree (`.dtsi/.keymap`) files.

### Goals
- Express tree-shaped Devicetree in declarative EDN.
- Reduce boilerplate (duplicate labels/node names, `compatible`, etc.).
- Provide sugar for common ZMK constructs (phandle links, layers, combos).


## Basic forms

### Node
- General form: `[tag attrs? children*]`
- `tag` — a keyword (may be namespaced).
- `attrs` — a map of Devicetree properties; optional.
- `children` — nested nodes.

Example:

```edn
[:behaviors
  [:hml {:#binding-cells 2 :flavor "balanced"}]
  [:hmr {:#binding-cells 2 :flavor "balanced"}]]
```

Equivalent “long” form with empty attrs:

```edn
[:behaviors {}
  [:hml {:#binding-cells 2 :flavor "balanced"}]
  [:hmr {:#binding-cells 2 :flavor "balanced"}]]
```

Render:

```dts
behaviors {
    hml {
        #binding-cells = <2>;
        flavor = "balanced";
    };
    hmr {
        #binding-cells = <2>;
        flavor = "balanced";
    };
};
```


### Devicetree root
The `:/` tag corresponds to the root `/ { ... };`. `attrs` is optional; if the root has no attributes, you can omit the empty `{}`.

Short form:
```edn
[:/ 
  [:behaviors ...]
  [:macros ...]]
```

Equivalent form with empty `attrs`:
```edn
[:/ {}
  [:behaviors {} ...]
  [:macros {} ...]]
```

```dts
/ {
    behaviors { ... };
    macros { ... };
};
```


## `compatible` via namespaced tag

If a tag has a namespace, it is automatically mapped to `compatible = "ns,name"`:

```edn
[:zmk/behavior-hold-tap
  {:node-id :hml
   :#binding-cells 2 :flavor "balanced"}]
```

```dts
hml: hml {
    compatible = "zmk,behavior-hold-tap";
    #binding-cells = <2>;
    flavor = "balanced";
};
```

Additional `compatible` values can be provided as a vector of strings (Devicetree uses a list of strings, not a single string with multiple commas):

```edn
[:zmk/behavior-hold-tap
  {:node-id :hml
   :compatible ["zmk,behavior-hold-tap" "zmk,behavior"]}]
```

```dts
hml: hml {
    compatible = "zmk,behavior-hold-tap", "zmk,behavior";
};
```


## Node identifier, label and name

- Identifier is provided via `:node-id` in attrs — it yields both the label and the node name.
- If `:node-id` is omitted, the tag’s local name can be used; for container nodes (e.g. `:/`, `:behaviors`, `:macros`, `:combos`, `:zmk/keymap`) the label is not emitted.
- Override the displayed name with `:name`.
- Disable the label with `:label false`.

Examples:

```edn
[:zmk/behavior-macro
  {:node-id :u_macro_s_bt_sel_0
   :#binding-cells 0 :wait-ms 0
   :bindings [[:& bt BT_SEL 0] [:& bt BT_CLR]]}]
```

```dts
u_macro_s_bt_sel_0: u_macro_s_bt_sel_0 {
    compatible = "zmk,behavior-macro";
    #binding-cells = <0>;
    wait-ms = <0>;
    bindings = < &bt BT_SEL 0 &bt BT_CLR >;
};
```

```edn
[:some/node {:node-id :node_id :label false :name :pretty}]
```

```dts
pretty {
    compatible = "some,node";
};
```


## Properties (attrs) and rendering

- Strings: `"..."` → `"..."`.
- Numbers → as Devicetree cells in angle brackets: `<1500>`, `<0>`, `<40>`.
- Symbols/keywords → rendered as names.
- Flags (boolean true) → `prop;` (no `=`).  
  Example: `{:hold-trigger-on-release true}` → `hold-trigger-on-release;`
- Vectors → in angle brackets: `< ... >`.  
  Example: `{:layers [BAS GM]}` → `layers = < BAS GM >;`
- Bitwise OR: `[:or MOD_LSFT MOD_RSFT]` → `(MOD_LSFT|MOD_RSFT)`.

Example:

```edn
[:zmk/behavior-mod-morph
  {:node-id :s_bt_sel_0
   :#binding-cells 0
   :bindings [[:& bt BT_SEL 0] :u_macro_s_bt_sel_0] ; reference to a node label
   :mods [:or MOD_LSFT MOD_RSFT]}]
```

```dts
s_bt_sel_0: s_bt_sel_0 {
    compatible = "zmk,behavior-mod-morph";
    #binding-cells = <0>;
    bindings = < &bt BT_SEL 0 &u_macro_s_bt_sel_0 >;
    mods = < (MOD_LSFT|MOD_RSFT) >;
};
```


## Phandle links (operator `:&`)

Primary link form is a vector with the `:&` operator. Additionally, a short form with a combined keyword is supported (pattern seen in Hiccup-like DSLs):

- `[:& kp H]`       → `&kp H`
- `[:&kp H]`        → `&kp H`
- `[:& bt BT_SEL 0]` → `&bt BT_SEL 0`

Inside property vectors this appears in `< ... >`:

```edn
{:bindings [[:& kp H]
            [:& hmr RALT L]
            [:& bt BT_SEL 0]]}
```

```dts
bindings = < &kp H &hmr RALT L &bt BT_SEL 0 >;
```


## Layers and keymap

For `zmk,keymap` there is a container node `:zmk/keymap` and a layer sugar `[:layer "NAME" {...}]`:

```edn
[:zmk/keymap {}
  [:layer "BASE"
    {:display-name "BASE"
     :bindings
     [[[:&kp BSLH] [:&kp Q] [:&kp W] [:&kp E] [:&kp R] [:&kp T]
       [:&kp Y] [:&kp U] [:&kp I] [:&kp O] [:&kp P] [:&kp LBKT]]

      [[:&kp CAPS] [:&hml LCTRL A] [:&hml LALT S] [:&hml LGUI D] [:&hml LSHFT F] [:&kp G]
       [:&kp H] [:&hmr RSHFT J] [:&hmr RGUI K] [:&hmr RALT L] [:&hmr RCTRL SC] [:&kp SQT]]

      [___ [:&kp Z] [:&kp X] [:&kp C] [:&hml GLOBE V] [:&kp B]
       [:&kp N] [:&hmr GLOBE M] [:&kp COMMA] [:&kp DOT] [:&kp FSLH] [:&kp RBKT]]

      [nil nil nil
       [:&lt MOS ESC] [:&t NV TAB] [:&lt SM SPACE] [:&lt NM RET] [:&lt FUN BSPC] [:&lt CFG DEL]]]}]]
```

```dts
keymap {
    compatible = "zmk,keymap";
    layer_BASE {
        display-name = "BASE";
        bindings = <
            &kp BSLH   &kp Q   &kp W   &kp E   &kp R   &kp T    &kp Y   &kp U   &kp I   &kp O   &kp P   &kp LBKT
            &kp CAPS   &hml LCTRL A  &hml LALT S  &hml LGUI D  &hml LSHFT F  &kp G   &kp H   &hmr RSHFT J  &hmr RGUI K  &hmr RALT L  &hmr RCTRL SC  &kp SQT
            ___        &kp Z   &kp X   &kp C   &hml GLOBE V    &kp B    &kp N   &hmr GLOBE M  &kp COMMA  &kp DOT  &kp FSLH  &kp RBKT
                           &lt MOS ESC  &lt NV TAB  &lt SM SPACE  &lt NM RET  &lt FUN BSPC  &lt CFG DEL
        >;
    };
};
```

Note: `nil` entries inside the matrix are ignored when printing rows (useful for alignment).


## Combos

```edn
[:zmk/combos {}
  [:combo_bas_inner_thmbs
    {:timeout-ms 18
     :bindings [[:& to GM]]
     :key-positions [LH0 RH0]
     :layers [BAS]
     :require-prior-idle-ms 0}]]
```

```dts
combos {
    compatible = "zmk,combos";
    combo_bas_inner_thmbs {
        timeout-ms = <18>;
        bindings = < &to GM >;
        key-positions = < LH0 RH0 >;
        layers = < BAS >;
        require-prior-idle-ms = <0>;
    };
};
```


## `#include` and `#define`

### Includes

```edn
[:includes "<behaviors.dtsi>" "<dt-bindings/zmk/keys.h>"]
```

```dts
#include <behaviors.dtsi>
#include <dt-bindings/zmk/keys.h>
```

### Defines (macros)

```edn
[:def QUICK_TAP_MS 175]
[:def ___ &none]
[:def _v_ &trans]
```

```dts
#define QUICK_TAP_MS 175
#define ___ &none
#define _v_ &trans
```


## Flags, arrays, and alignment

- Any property with value `true` is rendered as a flag: `prop;`
- Vectors — inside `< ... >`
- Column alignment for large bindings matrices can be tuned in the emitter; visually only.


## Validation

The DSL can be validated with malli schemas (via JVM Clojure or a babashka pod). Recommended pod: `pod-babashka-malli` ([repository](https://github.com/babashka/pod-babashka-malli)).


## Cheat sheet

- Node: `[tag attrs? children*]`
- Root: `[:/ {} ...]`
- Auto‑`compatible`: `:ns/name` → `"ns,name"`
- Identifier: via `:node-id` in attrs — yields label and node name
- Disable label: `{:label false}`; rename: `{:name :foo}`
- Flag: `prop = true` → `prop;`
- Array: `[:a :b]` → `< a b >`
- OR: `[:or A B]` → `(A|B)`
- Phandle: `[:& kp H]` or `[:&kp H]` → `&kp H`
- `#include`: `[:includes "<file1>" ...]`
- `#define`: `[:def NAME VALUE]`


## Devicetree notes

- `compatible` is a list of strings `"vendor,device"`. Multiple values are a list of strings: `"zmk,foo", "zmk,bar"` (not `"zmk,foo,bar"`).
- `&name` is a phandle reference to the node with that label.
- The number and meaning of arguments after `&node` are defined by that node’s `#binding-cells` property.


