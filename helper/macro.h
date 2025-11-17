#define U_MACRO(name,...) \
/ { \
  macros { \
    name: name { \
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
      #binding-cells = <0>; \
      bindings = <BINDING>, <SHIFT_BINDING>; \
      mods = <(MOD_LSFT|MOD_RSFT)>; \
    }; \
  }; \
};
