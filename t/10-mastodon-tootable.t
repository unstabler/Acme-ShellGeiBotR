use v6.c;
use Test;
use lib 'lib';

use Acme::ShellGeiBotR::Mastodon;

plan 6;

my Tootable $toot = Tootable.new(
    status => 'Hello, World!'
);

ok $toot.status eq 'Hello, World!';
ok !$toot.in-reply-to-id.defined;

my Tootable $toot2 = Tootable.new(
    status => '@cheesekun@twingyeo.kr Goodbye, World! =3 =3',
    in-reply-to-id => '1234'
);

ok $toot2.in-reply-to-id.defined;
ok $toot2.in-reply-to-id eq '1234';

my %serialized = $toot.serialize;
ok %serialized.keys.grep({ .match('-', :g) }).list.elems == 0;
ok %serialized.keys.grep({ .match(/^[ '$'|'@'|'%' ] '!'/, :g) }).list.elems == 0;

done-testing;