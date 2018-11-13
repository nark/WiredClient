#!/usr/bin/perl -w

use strict;
use IO::Socket;
use XML::Simple;
use Digest::SHA1;
use POSIX;


sub main {
	my($hostname, $port) = @_;
	
	$port ||= 4871;

	if(!$hostname) {
		print "Usage: wiredclient.pl hostname [port]\n";
		
		exit(2);
	}
	
	my $socket = p7connect($hostname, $port);
	
	print "Performing Wired handshake...\n";
	
	my($os_name, undef, $os_version, undef, $arch) = uname();

	p7sendmessage($socket, "wired.client_info",
		{ name => "wired.info.application.name", content => "$0" },
		{ name => "wired.info.application.version", content => "1.0" },
		{ name => "wired.info.application.build", content => "1" },
		{ name => "wired.info.os.name", content => $os_name },
		{ name => "wired.info.os.version", content => $os_version },
		{ name => "wired.info.arch", content => $arch },
		{ name => "wired.info.supports_rsrc", content => "false"}
	);
	
	my $message = p7readmessage($socket);
	
	print "Connected to \"$message->{'p7:field'}->{'wired.info.name'}->{'content'}\"\n";
	print "Logging in as guest...\n";
	
	p7sendmessage($socket, "wired.send_login",
		{ name => "wired.user.login", content => "guest" },
		{ name => "wired.user.password", content => Digest::SHA1::sha1_hex("") }
	);
	
	$message = p7readmessage($socket);
	
	print "Logged in with user ID $message->{'p7:field'}->{'content'}\n";

	$message = p7readmessage($socket);
	
	print "Listing files at /...\n";
	
	p7sendmessage($socket, "wired.file.list_directory",
		{ name => "wired.file.path", content => "/" }
	);
	
	while(($message = p7readmessage($socket))) {
		if($message->{"name"} eq "wired.file.file_list") {
			print "\t$message->{'p7:field'}->{'wired.file.path'}->{'content'}\n";
		}
		elsif($message->{"name"} eq "wired.file.file_list.done") {
			last;
		}
		else {
			print "Unhandled message $message->{name} received\n";
		}
	}
	
	print "Exiting\n";
}


sub p7connect {
	my($hostname, $port) = @_;
	
	print "Connecting to $hostname:$port...\n";
	
	my $socket = IO::Socket::INET->new(
		PeerAddr => $hostname,
		PeerPort => $port,
		Proto => "tcp"
	) || die "$!\n";
	
	print "Connected, performing P7 handshake...\n";
	
	p7sendmessage($socket, "p7.handshake.client_handshake",
		{ name => "p7.handshake.version", content => "1.0" },
		{ name => "p7.handshake.protocol.name", content => "Wired" },
		{ name => "p7.handshake.protocol.version", content => "2.0b55" },
	);
	
	my $message = p7readmessage($socket);
	
	if($message->{"name"} ne "p7.handshake.server_handshake") {
		die "Unexpected message $message->{'name'} from server\n";
	}
	
	print "Connected to P7 server with protocol $message->{'p7:field'}->{'p7.handshake.protocol.name'}->{'content'} $message->{'p7:field'}->{'p7.handshake.protocol.version'}->{'content'}\n";

	p7sendmessage($socket, "p7.handshake.acknowledge");
	
	if($message->{"p7:field"}->{"p7.handshake.compatibility_check"}) {
		my $specification;
		
		open(FH, "wired.xml") or die "wired.xml: $!";
		while(<FH>) {
			$specification .= $_;
		}
		close(FH);

		print $specification;
		
		p7sendmessage($socket, "p7.compatibility_check.specification",
			{ name => "p7.compatibility_check.specification", content => $specification },
		);
		
		$message = p7readmessage($socket);
		
		if($message->{"name"} ne "p7.compatibility_check.status") {
			die "Unexpected message $message->{'name'} from server\n";
		}
		
		if($message->{"p7:field"}->{"content"} != 1) {
			die "Local protocol incompatible with server protocol\n";
		}
	}
	
	return $socket;
}


sub p7sendmessage {
	my $socket = shift;
	my $name = shift;
	
	my $tree;
	$tree->{"name"} = $name;
	$tree->{"xmlns:p7"} = "http://www.zankasoftware.com/P7/Message";
	$tree->{"p7:field"} = \@_;
	
	my $xml = XMLout($tree, "RootName" => "p7:message", XMLDecl => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
	
	#print "$xml";

	print $socket "$xml\r\n";
}


sub p7readmessage {
	my($socket) = @_;
	
	my $xml;
	my $message;
	
	while(<$socket>) {
		$xml .= $_;
		
		if($xml =~ /\r\n$/) {
			$message = XMLin($xml);
			
			last;
		}
	}

	print $xml;
	
	if(!$message) {
		die "No message received from server\n";
	}
	elsif($message->{"name"} eq "wired.error") {
		die "Received Wired error $message->{'p7:field'}->{'content'} $xml\n";
	}
	
	return $message;
}


main($ARGV[0], $ARGV[1]);
