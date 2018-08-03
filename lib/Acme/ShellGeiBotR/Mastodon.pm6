unit module Acme::ShellGeiBotR::Mastodon;

use JSON::Tiny;
use Cro::HTTP::Client;

class Tootable is export {
    has Str $.status is required;
    has Str $.in-reply-to-id;
    has Str @.media-ids = ();
    has Bool $.sensitive = False;
    has Str $.spoiler-text;
    has Str $.visibility = 'unlisted';

    method serialize() {
        return %(
            self.^attributes.grep({ .get_value(self).defined }).map({
                .name.Str.substr(2).subst('-', '_', :g) => .get_value(self)
            })
        );
    }
}

class MastodonClient is export {
    has Str $.host is required;
    has Str $.token;

    has Cro::HTTP::Client $.http-client = Cro::HTTP::Client.new(
        content-type => 'application/json'
    );

    method post-status(Tootable $toot) {
        my $response = await $!http-client.post(
            $!host.fmt('https://%s/api/v1/statuses'),
            headers => [
                # TODO: 더 나은 방법이 있는데!
                authorization => $!token.fmt('Bearer %s')
            ],
            body => $toot.serialize
        );
    }
}

class StreamListener is export {
    has MastodonClient $.client;
}