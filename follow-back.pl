#!/usr/bin/perl
# following back my twitter followers
# get consumer keys and access token from http://dev.twitter.com/apps/new
use utf8;
use strict;
use warnings;
use Net::Twitter;
use YAML::Tiny;

sub usage{
	die "Usage: $0 config.yaml\n";
}

usage() unless defined $ARGV[0];
usage() unless -f $ARGV[0];

my $config = (YAML::Tiny->read($ARGV[0]))->[0];

my $twitter = Net::Twitter->new(
	traits => [qw(API::REST OAuth)],
	consumer_key => $config->{consumer_key},
	consumer_secret => $config->{consumer_secret},
	access_token => $config->{access_token},
	access_token_secret => $config->{access_token_secret}
	);
die 'Auth failed: ' . $config->{username} unless $twitter->authorized;
 
my $cr = $twitter->verify_credentials;
my $own_id = $cr->{id};
 
my $nextc = -1; # paging default.
my $following = {};
 
do{
	my $list = $twitter->friends_ids({id=>$own_id, cursor => $nextc});
	$nextc = $list->{next_cursor};
	for my $id (@{$list->{ids}}){
		$following->{$id}++;
	}
}while($nextc != 0);

$nextc = -1;
my $followers = {};
 
do{
	my $list = $twitter->followers_ids({id=>$own_id, cursor => $nextc});
	$nextc = $list->{next_cursor};
	for my $id (@{$list->{ids}}){
		$followers->{$id}++;
	}
}while($nextc != 0);

for my $id (keys %{$followers}){
	next if $following->{$id};
	# next if protected
	if(my $f = $twitter->create_friend($id)){
		print "$f->{screen_name} ($id)\n";
	}
}
exit;
