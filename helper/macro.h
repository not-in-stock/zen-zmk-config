
#define U_MACRO_VA_ARGS(macro, ...) macro(__VA_ARGS__)
#define U_MACRO(name,...) \
/ { \
  macros { \
    name: name { \
      label = ZMK_HELPER_STRINGIFY(ZM_ ## name); \
      compatible = "zmk,behavior-macro"; \
      #binding-cells = <0>; \
      __VA_ARGS__ \
    }; \
  }; \
};

#define SHIFT_FUNCTION(NAME, BINDING, SHIFT_BINDING) \
/ { \
  behaviors { \
    NAME: NAME { \
      compatible = "zmk,behavior-mod-morph"; \
      label = ZMK_HELPER_STRINGIFY(NAME); \
      #binding-cells = <0>; \
      bindings = <BINDING>, <SHIFT_BINDING>; \
      mods = <(MOD_LSFT|MOD_RSFT)>; \
    }; \
  }; \
};

#define SHIFT_MACRO(NAME, BINDING, SHIFT_BINDING) \
U_MACRO(u_macro_ ## NAME, wait-ms = <0>; bindings = <SHIFT_BINDING>;) \
SHIFT_FUNCTION(NAME, BINDING, &u_macro_ ## NAME)
