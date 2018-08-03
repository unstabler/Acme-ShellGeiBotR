unit module Acme::ShellGeiBotR::Mastodon;

use Cro::HTTP::Client;
use Cro::WebSocket::Client;

use Log::Async;

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
        content-type => 'application/json',
    );

    method post-status(Tootable $toot) {
        return await $!http-client.post(
            $!host.fmt('https://%s/api/v1/statuses'),
            headers => [
                # TODO: 더 나은 방법이 있는데!
                authorization => $!token.fmt('Bearer %s')
            ],
            body => $toot.serialize
        );
    }

    method instance-info() {
        return await $!http-client.get(
            $!host.fmt('https://%s/api/v1/instance')
        );
    }
}

class StreamListener is export {
    has MastodonClient $.client;
    has Supplier $.home = Supplier.new;

    # ㅁㄴㅇㄹㅁㄴㅇㄹㅁㄴㅇㄹㄴㅁㅇㄹㄴㅇ 
    # https://github.com/tootsuite/mastodon/issues/3049
    method connect() {
        my %instance-info = await $!client.instance-info.body;
        my $stream-base-url = %instance-info<urls><streaming_api>;
        my $endpoint = sprintf('%s/api/v1/streaming?stream=user&access_token=%s', $stream-base-url, $!client.token);

        my $client = Cro::WebSocket::Client.new(
            uri => $endpoint,
            body-parsers => Cro::WebSocket::BodyParser::JSON
        );

        debug sprintf('creating connection to %s', $endpoint);
        my $connection = await $client.connect;

        return start {
            debug 'connected to stream';
            react {
                whenever $connection.receiver -> $message {
                    given ($message.opcode) {
                        when Cro::WebSocket::Message::Text {
                            my $body = await $message.body;

                            debug sprintf('event received: %s', $body<event>);
                            $!home.emit($body);
                        }
                        when Cro::WebSocket::Message::Close {
                            fatal "connection closed;";
                        }
                    }
                }
            }
        }
    }
}