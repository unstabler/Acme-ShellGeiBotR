#!/usr/bin/env perl6
use v6;
use Log::Async;
use Acme::ShellGeiBotR;

logger.send-to($*ERR);

my $bot = ShellGeiBotR.new(
    host => 'mastodon-instance.net',
    token => 'bot-token',
    docker-image => 'docker-image'
);

await $bot.dance;