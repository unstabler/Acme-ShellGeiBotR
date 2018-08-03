unit module Acme::ShellGeiBotR;

use Digest::SHA;
use JSON::Fast;
use XML;
use HTML::Escape;
use Acme::ShellGeiBotR::HTML::Escape;
use Acme::ShellGeiBotR::Mastodon;

use Log::Async;

class ShellGei {
    has Str $.docker-image;
    has $.toot;
    has Str $.script;
    has Str $.reply-to;

    method new($docker-image, $toot) {
        my $script = unescape-html(from-xml($toot<content>)[0].Str); # FIXME
        return self.bless(
            docker-image => $docker-image,
            toot => $toot,
            script => $script,
            reply-to => $toot<id>
        );
    }

    method execute() returns Tootable {
        my $name = sha256($!reply-to.encode('utf8-c8')).list.fmt("%02x", '');
        my $path = $name.fmt('/tmp/SHELLGEI_%s.sh');
        spurt $path, $!script;
        
        my $process = run(
            'docker', 'run', '--net=none', '--rm',
            '--name', $name,
            '-v', ($path, $path).join(':'),
            $!docker-image,
            'bash', $path,
            :out
        );

        my $stdout = $process.out.lines.join("\n");
        $process.out.close();

        return Tootable.new(
            status => sprintf("@%s %s\n%s", $!toot<account><acct>, $stdout, $!toot<uri>),
            in-reply-to-id => $!reply-to
        );
    }
}

class ShellGeiBotR is export {
    has Str $.host  is required;
    has Str $.token is required;
    has Str $.docker-image is required;

    method dance() {
        my $client = MastodonClient.new(
            host => $!host,
            token => $!token
        );
        my $stream-listener = StreamListener.new(client => $client);
        
        $stream-listener.connect;
        react {
            whenever $stream-listener.home -> $event {
                given ($event<event>) {
                    when 'update' {
                        try {
                            CATCH {
                                default { fatal .Str; }
                            }

                            my $payload = from-json($event<payload>);
                            if (self.needs-process($payload<tags>)) {
                                info 'creating new ShellGei object';
                                my $shellgei = ShellGei.new($!docker-image, $payload);
                                debug sprintf('executing %s', $shellgei.script);
                                my $tootable = $shellgei.execute();
                                $client.post-status($tootable);   
                            }
                        }
                    }
                    when 'notification' {
                        # TODO: follow-back when payload.type eq 'follow'
                    }
                }
            }
        }
    }

    method needs-process($tags) {
        my @extracted_tags = $tags.map({ $_<name> });
        return qw/シェル芸 셸예능 shellgei/.grep({ @extracted_tags.contains($_) })[].elems > 0;
    }
}