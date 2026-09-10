<?php
/**
 * PHP 8 compatibility shim for the intentionally outdated DVWP plugins.
 *
 * Loaded via auto_prepend_file (see otherz/php.ini) so the removed PHP
 * functions below exist inside every request, including under wp-cli.
 * Only defines what the engine no longer provides.
 */

if ( ! function_exists( 'create_function' ) ) {
    function create_function( $args, $code ) {
        return eval( 'return function(' . $args . ') {' . $code . '};' );
    }
}

if ( ! function_exists( 'each' ) ) {
    function each( &$array ) {
        $key = key( $array );
        if ( null === $key ) {
            return false;
        }
        $value = current( $array );
        next( $array );
        return array( 0 => $key, 'key' => $key, 1 => $value, 'value' => $value );
    }
}