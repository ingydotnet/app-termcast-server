package Reflex::UdpPeer;
{
  $Reflex::UdpPeer::VERSION = '0.099';
}
# vim: ts=2 sw=2 noexpandtab

use Moose;
extends 'Reflex::Base';
use Reflex::Callbacks qw(make_emitter make_terminal_emitter);

has socket => (
	is        => 'rw',
	isa       => 'Maybe[FileHandle]',
	required  => 1,
);

has active => (
	is        => 'rw',
	isa       => 'Bool',
	default   => 1,
);

with 'Reflex::Role::Recving' => {
	att_handle  => 'socket',
	att_active  => 'active',
	method_send => 'send',
	method_stop => 'stop',
	cb_datagram => make_emitter(on_datagram => "datagram"),
	cb_error    => make_terminal_emitter(on_error => "error"),
};

__PACKAGE__->meta->make_immutable;

1;



=pod

=for :stopwords Rocco Caputo

=encoding UTF-8

=head1 NAME

Reflex::UdpPeer - Base class for non-blocking UDP networking peers.

=head1 VERSION

This document describes version 0.099, released on April 21, 2013.

=head1 SYNOPSIS

TODO - Rewritten.  Need to rewrite docs, too.

Inherit it.

	package Reflex::Udp::Echo;
	use Moose;
	extends 'Reflex::UdpPeer';

	sub on_socket_datagram {
		my ($self, $datagram) = @_;
		my $data = $datagram->octets();

		if ($data =~ /^\s*shutdown\s*$/) {
			$self->stop_socket_readable();
			return;
		}

		$self->send(
			datagram => $data,
			peer     => $datagram->peer(),
		);
	}

	sub on_socket_error {
		my ($self, $error) = @_;
		warn(
			$error->function(),
			" error ", $error->number(),
			": ", $error->string(),
		);
		$self->destruct();
	}

Use it as a helper.

	package Reflex::Udp::Echo;
	use Moose;
	extends 'Reflex::Base';
	use Reflex::UdpPeer;

	has port => ( isa => 'Int', is => 'ro' );

	watches peer => (
		isa     => 'Maybe[Reflex::UdpPeer]',
		setup   => sub {
			my $self = shift;
			Reflex::UdpPeer->new(
				socket => IO::Socket::INET->new(
					LocalPort => $self->port(),
					Proto     => 'udp',
				)
			)
		},
	);

	sub on_peer_datagram {
		my ($self, $args) = @_;
		my $data = $args->{datagram};

		if ($data =~ /^\s*shutdown\s*$/) {
			$self->peer(undef);
			return;
		}

		$self->peer()->send(
			datagram    => $data,
			remote_addr => $args->{remote_addr},
		);
	}

	sub on_peer_error {
		my ($self, $args) = @_;
		warn "$args->{op} error $args->{errnum}: $args->{errstr}";
		$self->peer(undef);
	}

Compose objects with its base role.

	# See L<Reflex::Role::Recving>.

Use it as a promise (like a condvar), or set callbacks in its
constructor.

	# TODO - Make an example.

=head1 DESCRIPTION

Reflex::UdpPeer is a base class for UDP network peers.  It waits for
datagrams on a socket, automatically receives them when they arrive,
and emits "datagram" events containing the data and senders'
addresses.  It also provides a send() method that handles errors.

However, all this is done by its implementation, which is over in
Reflex::Role::UdpPeer.  The documentation won't be repeated here, so
further details will be found with the role.  Code and docs together,
you know.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Reflex|Reflex>

=item *

L<Moose::Manual::Concepts>

=item *

L<Reflex>

=item *

L<Reflex::Base>

=item *

L<Reflex::Role::UdpPeer>

=item *

L<Reflex/ACKNOWLEDGEMENTS>

=item *

L<Reflex/ASSISTANCE>

=item *

L<Reflex/AUTHORS>

=item *

L<Reflex/BUGS>

=item *

L<Reflex/BUGS>

=item *

L<Reflex/CONTRIBUTORS>

=item *

L<Reflex/COPYRIGHT>

=item *

L<Reflex/LICENSE>

=item *

L<Reflex/TODO>

=back

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Reflex>.

=head1 AUTHOR

Rocco Caputo <rcaputo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Rocco Caputo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Reflex/>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut


__END__

