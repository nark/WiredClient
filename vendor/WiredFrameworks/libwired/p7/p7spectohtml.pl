#!/usr/bin/perl

use strict;
use XML::Parser;
use Data::Dumper;


sub main {
	my($file) = @_;

	my $parser = XML::Parser->new(Style => "Tree");
	my $tree = $parser->parsefile($file);

	my $protocol = $tree->[1];
	my $info = $protocol->[0];
	$info->{"file"} = $file;

	my %fields;
	my %collections;
	my %messages;

	my @fields;
	my @messages;
	my @transactions;
	my @broadcasts;

	for(my $i = 0; $i < @$protocol; $i++) {
		my $node = $protocol->[$i];

		if($node eq "p7:documentation") {
			$info->{"documentation"} = documentation($protocol->[$i + 1]->[2]);
		}
		elsif($node eq "p7:collections") {
			for(my $j = 0; $j < @{$protocol->[$i + 1]}; $j++) {
				if($protocol->[$i + 1]->[$j] eq "p7:collection") {
					my $collectionnode = $protocol->[$i + 1]->[$j + 1];
					my $collection = $collectionnode->[0];
					
					my @fields;
					
					for(my $k = 0; $k < @{$collectionnode}; $k++) {
						if($collectionnode->[$k] eq "p7:member") {
							push(@fields, $collectionnode->[$k + 1]->[0]->{"field"});
						}
					}
					
					$collections{$collection->{"name"}} = \@fields;
				}
			}
		}
	}

	for(my $i = 0; $i < @$protocol; $i++) {
		my $node = $protocol->[$i];
		
		if($node eq "p7:fields") {
			for(my $j = 0; $j < @{$protocol->[$i + 1]}; $j++) {
				if($protocol->[$i + 1]->[$j] eq "p7:field") {
					my $fieldnode = $protocol->[$i + 1]->[$j + 1];
					my $field = $fieldnode->[0];

					my @enums;

					for(my $k = 0; $k < @{$fieldnode}; $k++) {
						if($fieldnode->[$k] eq "p7:enum") {
							push(@enums, $fieldnode->[$k + 1]->[0]);
						}
						elsif($fieldnode->[$k] eq "p7:documentation") {
							$field->{"documentation"} = documentation($fieldnode->[$k + 1]->[2]);
						}
					}

					$field->{"enums"} = \@enums;
					$field->{"formattedtype"} = type($field->{"type"});
					$field->{"formattedlisttype"} = type($field->{"listtype"}) if $field->{"listtype"};
					$field->{"messages"} = [];

					$fields{$field->{"name"}} = $field;

					push(@fields, $field);
				}
			}
		}
	}

	for(my $i = 0; $i < @$protocol; $i++) {
		my $node = $protocol->[$i];
		
		if($node eq "p7:messages") {
			for(my $j = 0; $j < @{$protocol->[$i + 1]}; $j++) {
				if($protocol->[$i + 1]->[$j] eq "p7:message") {
					my $messagenode = $protocol->[$i + 1]->[$j + 1];
					my $message = $messagenode->[0];

					my @required_parameters;
					my @optional_parameters;

					for(my $k = 0; $k < @{$messagenode}; $k++) {
						if($messagenode->[$k] eq "p7:parameter") {
							$messagenode->[$k + 1]->[0]->{"use"} ||= "optional";

							foreach my $parameter ($messagenode->[$k + 1]->[0]) {
								my $fields = $collections{$parameter->{"collection"}};

								if($fields) {
									foreach my $field (@$fields) {
										my $collection_parameter;

										$collection_parameter->{"field"} = $fields{$field};
										$collection_parameter->{"version"} = $parameter->{"version"};
										$collection_parameter->{"use"} = $parameter->{"use"};

										if($collection_parameter->{"use"} eq "optional") {
											push(@optional_parameters, $collection_parameter);
										} else {
											push(@required_parameters, $collection_parameter);
										}

										push(@{$collection_parameter->{"field"}->{"messages"}}, $message->{"name"});
									}
								} else {
									$parameter->{"field"} = $fields{$parameter->{"field"}};

									if($parameter->{"use"} eq "optional") {
										push(@optional_parameters, $parameter);
									} else {
										push(@required_parameters, $parameter);
									}
									
									push(@{$parameter->{"field"}->{"messages"}}, $message->{"name"});
								}
							}
						}
						elsif($messagenode->[$k] eq "p7:documentation") {
							$message->{"documentation"} = documentation($messagenode->[$k + 1]->[2]);
						}
					}

					$message->{"required_parameters"} = \@required_parameters;
					$message->{"optional_parameters"} = \@optional_parameters;
					$message->{"transactions"} = [];
					$message->{"broadcasts"} = [];
					
					$messages{$message->{"name"}} = $message;

					push(@messages, $message);
				}
			}
		}
	}

	for(my $i = 0; $i < @$protocol; $i++) {
		my $node = $protocol->[$i];
		
		if($node eq "p7:transactions") {
			for(my $j = 0; $j < @{$protocol->[$i + 1]}; $j++) {
				if($protocol->[$i + 1]->[$j] eq "p7:transaction") {
					my $transactionnode = $protocol->[$i + 1]->[$j + 1];
					my $transaction = $transactionnode->[0];

					my @replies;
					my $index1 = 0;
					my $index2 = 0;

					for(my $k = 0; $k < @{$transactionnode}; $k++) {
						if($transactionnode->[$k] =~ /^p7:reply|p7:and|p7:or/) {
							my $replynode = $transactionnode->[$k + 1];

							if($transactionnode->[$k] eq "p7:or") {
								for(my $l = 0; $l < @{$replynode}; $l++) {
									$index2 = 0;

									if($replynode->[$l] eq "p7:and") {
										for(my $m = 0; $m < @{$replynode->[$l + 1]}; $m++) {
											if($replynode->[$l + 1]->[$m] eq "p7:reply") {
												$replies[$index1]->[$index2] = $replynode->[$l + 1]->[$m + 1]->[0];
												$replies[$index1]->[$index2]->{"message"} = $messages{$replies[$index1]->[$index2]->{"message"}};
												$replies[$index1]->[$index2]->{"use"} ||= "optional";
												
												push(@{$replies[$index1]->[$index2]->{"message"}->{"transactions"}}, $transaction->{"message"});
												
												$index2++;
											}
										}

										$index1++;
									}
									elsif($replynode->[$l] eq "p7:reply") {
										$replies[$index1]->[$index2] = $replynode->[$l + 1]->[0];
										$replies[$index1]->[$index2]->{"message"} = $messages{$replies[$index1]->[$index2]->{"message"}};
										$replies[$index1]->[$index2]->{"use"} ||= "optional";
										
										push(@{$replies[$index1]->[$index2]->{"message"}->{"transactions"}}, $transaction->{"message"});

										$index1++;
									}
								}
							}
							elsif($transactionnode->[$k] eq "p7:reply") {
								$replies[$index1]->[$index2] = $replynode->[0];
								$replies[$index1]->[$index2]->{"message"} = $messages{$replies[$index1]->[$index2]->{"message"}};
								$replies[$index1]->[$index2]->{"use"} ||= "optional";

								push(@{$replies[$index1]->[$index2]->{"message"}->{"transactions"}}, $transaction->{"message"});
								
								$index2++;
							}
						}
						elsif($transactionnode->[$k] eq "p7:documentation") {
							$transaction->{"documentation"} = documentation($transactionnode->[$k + 1]->[2]);
						}
					}

					$transaction->{"use"} ||= "optional";
					$transaction->{"formattedoriginator"} = originator($transaction->{"originator"});
					$transaction->{"replies"} = \@replies;

					push(@{$messages{$transaction->{"message"}}->{"transactions"}}, $transaction->{"message"});

					push(@transactions, $transaction);
				}
			}
		}
		elsif($node eq "p7:broadcasts") {
			for(my $j = 0; $j < @{$protocol->[$i + 1]}; $j++) {
				if($protocol->[$i + 1]->[$j] eq "p7:broadcast") {
					my $broadcastnode = $protocol->[$i + 1]->[$j + 1];
					my $broadcast = $broadcastnode->[0];

					for(my $k = 0; $k < @{$broadcastnode}; $k++) {
						if($broadcastnode->[$k] eq "p7:documentation") {
							$broadcast->{"documentation"} = documentation($broadcastnode->[$k + 1]->[2]);
						}
					}
					
					push(@{$messages{$broadcast->{"message"}}->{"broadcasts"}}, $broadcast->{"message"});
					
					push(@broadcasts, $broadcast);
				}
			}
		}
	}

	printhtmlheader($info);

	printheader($info, \@fields, \@messages, \@transactions, \@broadcasts);
	printfields(\@fields);
	printmessages(\@messages);
	printtransactions(\@transactions);
	printbroadcasts(\@broadcasts);
	
	printhtmlfooter();
}


sub documentation {
	my($documentation) = @_;

	$documentation =~ s/ +/ /g;
	$documentation =~ s/\t+/\t/g;
	$documentation =~ s/^[ \t]//mg;
	$documentation =~ s/[ \t]$//mg;
	$documentation =~ s/\n\n/<br \/>\n<br \/>\n/g;

	$documentation =~ s/\[field:(.+?)\]/<a href="#field,\1">\1<\/a>/g;
	$documentation =~ s/\[enum:(.+?)\]/<a href="#enum,\1">\1<\/a>/g;
	$documentation =~ s/\[message:(.+?)\]/<a href="#message,\1">\1<\/a>/g;
	$documentation =~ s/\[broadcast:(.+?)\]/<a href="#broadcast,\1">\1<\/a>/g;

	return $documentation;
}


sub type {
	my($type) = @_;

	return "Boolean" if $type eq "bool";
	return "Enumerated value" if $type eq "enum";
	return "Signed 32-bit integer" if $type eq "int32";
	return "Unsigned 32-bit integer" if $type eq "uint32";
	return "Signed 64-bit integer" if $type eq "int64";
	return "Unsigned 64-bit integer" if $type eq "uint64";
	return "Floating Point number" if $type eq "double";
	return "String" if $type eq "string";
	return "UUID" if $type eq "uuid";
	return "Date" if $type eq "date";
	return "Data" if $type eq "data";
	return "Out-of-band data" if $type eq "oobdata";
	return "List" if $type eq "list";
}


sub originator {
	my($type) = @_;

	return "Client" if $type eq "client";
	return "Server" if $type eq "server";
	return "Both" if $type eq "both";
}


sub printhtmlheader {
	my($info) = @_;
	
	print <<EOF;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
	
<!-- baka baka minna baka -->
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<title>$info->{"name"} $info->{"version"} Documentation</title>
	<link rel="stylesheet" type="text/css" href="http://www.zankasoftware.com/css/index.css">
</head>
<body>
EOF
}


sub printheader {
	my($info, $fields, $messages, $transactions, $broadcasts) = @_;

	print <<EOF;
<span class="protocoltitle">$info->{"name"} $info->{"version"}</span>

<br />
<br />

<code class="protocol">&lt;p7:protocol xmlns:p7="$info->{"xmlns:p7"}"
             xmlns:xsi="$info->{"xmlns:xsi"}"
             xsi:schemaLocation="$info->{"xsi:schemaLocation"}"
             name="$info->{"name"}"
             version="$info->{"version"}" /&gt;</code>

<br />

Automatically generated from <a href="$info->{"file"}">$info->{"file"}</a>.

<br />
<br />

<span class="protocolsectiontitle">Overview</span><br />
<hr class="protocol" />

$info->{"documentation"}

<br />
<br />

<span class="protocolsectiontitle">Fields</span><br />
<hr class="protocol" />

<blockquote>
EOF

	foreach my $field (@$fields) {
		print <<EOF;
<a href="#field,$field->{"name"}">$field->{"name"}</a><br />
EOF
	}

	print <<EOF;
</blockquote>

<br />
<br />

<span class="protocolsectiontitle">Messages</span><br />
<hr class="protocol" />

<blockquote>
EOF

	foreach my $message (@$messages) {
		print <<EOF;
<a href="#message,$message->{"name"}">$message->{"name"}</a><br />
EOF
	}

	print <<EOF;
</blockquote>

<br />
<br />

<span class="protocolsectiontitle">Transactions</span><br />
<hr class="protocol" />

<blockquote>
EOF

	foreach my $transaction (@$transactions) {
		print <<EOF;
<a href="#transaction,$transaction->{"message"}">$transaction->{"message"}</a><br />
EOF
	}

	print <<EOF;
</blockquote>

<br />
<br />

<span class="protocolsectiontitle">Broadcasts</span><br />
<hr class="protocol" />

<blockquote>
EOF

	foreach my $broadcast (@$broadcasts) {
		print <<EOF;
<a href="#broadcast,$broadcast->{"message"}">$broadcast->{"message"}</a><br />
EOF
	}

	print <<EOF;
</blockquote>
<br />
<br />
<br />
EOF
}



sub printfields {
	my($fields) = @_;

	print <<EOF;
<a class="protocolsectiontitle" name="fields">Fields</span>
<hr class="protocol" />

<br />
EOF

	foreach my $field (@$fields) {
		print <<EOF;
<a name="field,$field->{"name"}"><span class="protocolitemtitle">$field->{"name"}</span></a>

<br />
<br />
		
EOF
		
		if(@{$field->{"enums"}} > 0) {
			print <<EOF;
<code class="protocol">&lt;p7:field name="$field->{"name"}" type="$field->{"type"}" id="$field->{"id"}"&gt;
EOF

			foreach my $enum (@{$field->{"enums"}}) {
				print <<EOF;
    &lt;p7:enum name="$enum->{"name"}" value="$enum->{"value"}" /&gt;
EOF
			}
			
			print <<EOF;
&lt;/p7:field&gt;</code>
EOF
		} else {
			print <<EOF;
<code class="protocol">&lt;p7:field name="$field->{"name"}" type="$field->{"type"}" id="$field->{"id"}" /&gt;</code>
EOF
		}
		
		print <<EOF;
<br />
		
$field->{"documentation"}

<br />
<br />

<span class="protocolitemsubtitle">ID</span><br />
$field->{"id"}

<br />
<br />

<span class="protocolitemsubtitle">Type</span><br />
$field->{"formattedtype"}

<br />
<br />

EOF

		if($field->{"type"} eq "list") {
			print <<EOF;
<span class="protocolitemsubtitle">List Type</span><br />
$field->{"formattedlisttype"}

<br />
<br />

EOF
		}

		if(@{$field->{"enums"}} > 0) {
			print <<EOF;
<span class="protocolitemsubtitle">Values</span><br />
EOF

			foreach my $enum (@{$field->{"enums"}}) {
				print <<EOF;
<a name="enum,$enum->{"name"}" href="#enum,$enum->{"name"}" class="protocolanchor">$enum->{"name"} = $enum->{"value"}</a><br />
<blockquote>Available in version $enum->{"version"} and later.</blockquote>
EOF
			}

			print <<EOF;
<br />
EOF
		}
		
		print <<EOF;
<span class="protocolitemsubtitle">Included in Messages</span><br />
EOF
		
		foreach my $message (@{$field->{"messages"}}) {
			print <<EOF;
<a href="#message,$message">$message</a><br />
EOF
		}

		print <<EOF;
<br />

<span class="protocolitemsubtitle">Availability</span><br />
Available in version $field->{"version"} and later.

<br />
<br />
<br />
EOF
	}

	print <<EOF;
<br />
EOF
}



sub printmessages {
	my($messages) = @_;

	print <<EOF;
<a class="protocolsectiontitle" name="messages">Messages</span>
<hr class="protocol" />

<br />
EOF

	foreach my $message (@$messages) {
		print <<EOF;
<a name="message,$message->{"name"}" href="#message,$message->{"name"}" class="protocolanchor"><span class="protocolitemtitle">$message->{"name"}</span></a>

<br />
<br />

<code class="protocol">&lt;p7:message name="$message->{"name"}" id="$message->{"id"}" version="$message->{"version"}"&gt;
EOF
			
		foreach my $parameter ((@{$message->{"required_parameters"}}, @{$message->{"optional_parameters"}})) {
			print <<EOF;
    &lt;p7:parameter field="$parameter->{"field"}->{"name"}" use="$parameter->{"use"}" version="$parameter->{"version"}" /&gt;
EOF
		}
			
		print <<EOF;
&lt;/p7:message&gt;</code>
		
<br />
		
$message->{"documentation"}

<br />
<br />

<span class="protocolitemsubtitle">ID</span><br />
$message->{"id"}

<br />
EOF

		if(@{$message->{"required_parameters"}} > 0) {
			print <<EOF;
<br />

<span class="protocolitemsubtitle">Required Parameters</span><br />
EOF

			printparameters($message->{"required_parameters"});
		}

		if(@{$message->{"optional_parameters"}} > 0) {
			print <<EOF;
<br />

<span class="protocolitemsubtitle">Optional Parameters</span><br />
EOF

			printparameters($message->{"optional_parameters"});
		}
		
		if(@{$message->{"transactions"}}) {
			print <<EOF;
<br />

<span class="protocolitemsubtitle">Included in Transactions</span><br />
EOF
		
			foreach my $transaction (@{$message->{"transactions"}}) {
				print <<EOF;
<a href="#transaction,$transaction">$transaction</a><br />
EOF
			}
		}

		if(@{$message->{"broadcasts"}}) {
			print <<EOF;
<br />

<span class="protocolitemsubtitle">Included in Broadcasts</span><br />
EOF
			
			foreach my $broadcast (@{$message->{"broadcasts"}}) {
				print <<EOF;
<a href="#broadcast,$broadcast">$broadcast</a><br />
EOF
			}
		}
		
		print <<EOF;
<br />

<span class="protocolitemsubtitle">Availability</span><br />
Available in version $message->{"version"} and later.

<br />
<br />
<br />
EOF
	}

	print <<EOF;
<br />
EOF
}



sub printparameters {
	my($parameters) = @_;

	foreach my $parameter (@$parameters) {
		print <<EOF;
<a href="#field,$parameter->{"field"}->{"name"}">$parameter->{"field"}->{"name"}</a><br />
<blockquote>Available in version $parameter->{"version"} and later.</blockquote>
EOF
	}
}



sub printtransactions {
	my($transactions) = @_;

	print <<EOF;
<a class="protocolsectiontitle" name="transactions">Transactions</span>
<hr class="protocol" />

<br />
EOF

	foreach my $transaction (@$transactions) {
		print <<EOF;
<a name="transaction,$transaction->{"message"}" href="#transaction,$transaction->{"message"}" class="protocolanchor"><span class="protocolitemtitle">$transaction->{"message"}</span></a>

<br />
<br />
EOF
		
		print <<EOF;
<code class="protocol">&lt;p7:transaction message="$transaction->{"message"}" originator="$transaction->{"originator"}" use="$transaction->{"use"}" version="$transaction->{"version"}"&gt;
EOF

		my $replies1 = $transaction->{"replies"};

		if(@{$replies1} > 1) {
			print <<EOF;
    &lt;p7:or&gt;
EOF
		}
		
		for(my $index1 = 0; $index1 < @$replies1; $index1++) {
			my $replies2 = $replies1->[$index1];
			
			if(@{$replies1} > 1 && @{$replies2} > 1) {
				print <<EOF;
        &lt;p7:and&gt;
EOF
			}
			
			for(my $index2 = 0; $index2 < @$replies2; $index2++) {
				my $reply = $replies1->[$index1]->[$index2];
				
				my $indent = " " x (4 + (4 * (@{$replies1} > 1)) + (4 * (@{$replies2} > 1)));
				
				print <<EOF;
$indent&lt;p7:reply message="$reply->{"message"}->{"name"}" count="$reply->{"count"}" use="$reply->{"use"}" /&gt;
EOF
			}
			
			if(@{$replies2} > 1) {
				print <<EOF;
        &lt;/p7:and&gt;
EOF
			}
		}
		
		if(@{$replies1} > 1) {
			print <<EOF;
    &lt;/p7:or&gt;
EOF
		}

		print <<EOF;
&lt;/p7:transaction&gt;</code>

<br />

$transaction->{"documentation"}

<br />
<br />

<span class="protocolitemsubtitle">Message</span><br />
<a href="#message,$transaction->{"message"}">$transaction->{"message"}</a>

<br />
<br />

<span class="protocolitemsubtitle">Originator</span><br />
$transaction->{"formattedoriginator"}

<br />
<br />

<span class="protocolitemsubtitle">Replies</span><br />
EOF

		for(my $index1 = 0; $index1 < @$replies1; $index1++) {
			my $replies2 = $replies1->[$index1];

			for(my $index2 = 0; $index2 < @$replies2; $index2++) {
				my $reply = $replies1->[$index1]->[$index2];
				my $count;

				if($reply->{"count"} eq "?") {
					$count = "Zero or one";
				}
				elsif($reply->{"count"} eq "*") {
					$count = "Zero or more";
				}
				elsif($reply->{"count"} eq "+") {
					$count = "One or more";
				}
				elsif($reply->{"count"} eq "1") {
					$count = "One";
				}
				else {
					$count = $reply->{"count"};
				}

				print <<EOF;
$count <a href="#message,$reply->{"message"}->{"name"}">$reply->{"message"}->{"name"}</a> ($reply->{"use"})<br />
<blockquote>Available in version $reply->{"version"} and later.</blockquote>
EOF
			}

			if($index1 < @$replies1 - 1) {
				print <<EOF;
<br /><i>or</i><br /><br />
EOF
			}
		}

		print <<EOF;
<br />

<span class="protocolitemsubtitle">Availability</span><br />
Available in version $transaction->{"version"} and later.

<br />
<br />
<br />
EOF
	}

	print <<EOF;
<br />
EOF
}



sub printbroadcasts {
	my($broadcasts) = @_;

	print <<EOF;
<a class="protocolsectiontitle" name="broadcasts">Broadcasts</span>
<hr class="protocol" />

<br />
EOF

	foreach my $broadcast (@$broadcasts) {
		print <<EOF;
<a name="broadcast,$broadcast->{"message"}" href="#broadcast,$broadcast->{"message"}" class="protocolanchor"><span class="protocolitemtitle">$broadcast->{"message"}</span></a>

<br />
<br />

<code class="protocol">&lt;p7:broadcast message="$broadcast->{"message"}" version="$broadcast->{"version"}" /&gt;</code>

<br />

$broadcast->{"documentation"}

<br />
<br />

<span class="protocolitemsubtitle">Message</span><br />
<a href="#message,$broadcast->{"message"}">$broadcast->{"message"}</a><br />
EOF

		print <<EOF;
<br />

<span class="protocolitemsubtitle">Availability</span><br />
Available in version $broadcast->{"version"} and later.
EOF

		if($broadcast != $broadcasts->[-1]) {
			print <<EOF;
<br />
<br />
<br />
EOF
		}
	}
}



sub printhtmlfooter {
	print <<EOF;
</body>
</html>
EOF
}



main($ARGV[0]);
