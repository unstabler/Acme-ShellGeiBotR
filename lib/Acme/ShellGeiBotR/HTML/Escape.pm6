unit module Acme::ShellGeiBotR::HTML::Escape;

sub unescape-html(Str $escaped) returns Str is export {
    my Pair @translations = [
        # Named entities
        "&amp;" => "&",
        "&apos;" => "'",
        "&cent;" => "¢",
        "&copy;" => "©",
        "&euro;" => "€",
        "&gt;" => ">",
        "&lt;" => "<",
        "&pound;" => "£",
        "&quot;" => "\"",
        "&reg;" => "®",
        "&yen;" => "¥",

        # Numbered entities
        "&#39;" => "'",
        "&#96;" => "`",
        "&#123;" => '{',
        "&#125;" => '}',
    ];

    my Str @old;
    my Str @new;

    for @translations -> $translation {
        @old.push($translation.key);
        @new.push($translation.value);
    }

    $escaped.trans(@old => @new);
}

=begin pod

=head1 NAME

Acme::ShellGeiBotR::HTML::Escape

= COPYRIGHT AND LICENSE

    Copyright 2017- moznion <moznion@gmail.com>

    This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod