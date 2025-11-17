/*
 * helper.h
 *
 * Convenience macros simplifying ZMK's keymap configuration.
 * See https://github.com/urob/zmk-helpers for documentation.
 */

#pragma once

#define ZMK_HELPER_STRINGIFY(x) #x

// Preprocessor mechanism to overload macros, cf. https://stackoverflow.com/a/27051616/6114651
#define VARGS_(_10, _9, _8, _7, _6, _5, _4, _3, _2, _1, N, ...) N
#define VARGS(...) VARGS_(__VA_ARGS__, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
#define CONCAT_(a, b) a##b
#define CONCAT(a, b) CONCAT_(a, b)

/* ZMK_BEHAVIOR */

#define ZMK_BEHAVIOR_CORE_hold_tap        compatible = "zmk,behavior-hold-tap";        #binding-cells = <2>

#define ZMK_BEHAVIOR(name, type, ...) \
    / { \
        behaviors { \
            name: name { \
                ZMK_BEHAVIOR_CORE_ ## type; \
                __VA_ARGS__ \
            }; \
        }; \
    };

