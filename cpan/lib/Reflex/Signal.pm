package Reflex::Signal;
{
  $Reflex::Signal::VERSION = '0.099';
}
# vim: ts=2 sw=2 noexpandtab

use Moose;
extends 'Reflex::Base';
use Reflex::Callbacks qw(make_emitter);

has signal => (
	is        => 'ro',
	isa       => 'Str',
	required  => 1,
);

has active => (
	is      => 'ro',
	isa     => 'Bool',
	default => 1,
);

with 'Reflex::Role::SigCatcher' => {
	att_signal    => 'signal',
	att_active    => 'active',
	cb_signal     => make_emitter(on_signal => "signal"),
	method_start  => 'start',
	method_stop   => 'stop',
	method_pause  => 'pause',
	method_resume => 'resume',
};

__PACKAGE__->meta->make_immutable;

1;



=pod

=for :stopwords Rocco Caputo

=encoding UTF-8

=head1 NAME

Reflex::Signal - receive callbacks when signals arrive

=head1 VERSION

This document describes version 0.099, released on April 21, 2013.

=head1 SYNOPSIS

eg/eg-39-signals.pl

	use warnings;
	use strict;

	use Reflex::Signal;
	use Reflex::Callbacks qw(cb_coderef);
	use ExampleHelpers qw(eg_say);

	eg_say("Process $$ is waiting for SIGUSR1 and SIGUSR2.");

	my $usr1 = Reflex::Signal->new(
		signal    => "USR1",
		on_signal => cb_coderef { eg_say("Got SIGUSR1.") },
	);

	my $usr2 = Reflex::Signal->new( signal => "USR2" );
	while ($usr2->next()) {
		eg_say("Got SIGUSR2.");
	}

=head1 DESCRIPTION

Reflex::Signal waits for signals from the operating system.  It
may invoke callback functions and/or be used as a promise of new
signals depending on the application's needs.

Reflex::Signal is almost entirely implemented in
Reflex::Role::SigCatcher.
That role's documentation contains important details that won't be
covered here.

Reflex::Signal is not suitable for SIGCHLD use.  The specialized
Reflex::PID class is used for that, and it will automatically wait()
for processes and return their exit statuses.

=head2 Public Attributes

=head3 signal

Reflex:Signal's C<signal> attribute defines the name of the signal
to catch.  Names are as those in %SIG, namely with the leading "SIG"
scraped off.

=head3 active

The C<active> attribute controls whether the signal catcher will be
started in an actively catching state.  It defaults to true; set it to
false if you'd like to activate the signal catcher later.

=head2 Public Methods

=head3 start

Reflex::Signal's start() method may be used to initialize signal
catchers and start them watching for signals.  start() will be called
automatically if the signal catcher is started in the active state,
which it is by default.

Signal catchers may not be stopped, paused or resumed until they have
been started.

=head3 stop

The stop() method stops and finalizes the signal catcher.  It's
automatically called at DEMOLISH time, just in case it hasn't already
been.

=head3 pause

pause() pauses the signal catcher without finalizing it.  This is a
lighter-weight, non-final version of stop().

=head3 resume

resume() resumes a paused signal catcher without re-initializing it.
This is a lighter-weight, non-initial version of start().

=head2 Callbacks

=head3 on_signal

The on_signal() callback notifies the user when the watched signal has
been caught.  It includes no parameters of note.

=head3 on_data

on_data() will be called whenever Reflex::Stream receives data.  It
will include one named parameter in $_[1], "data", containing raw
octets received from the stream.

	sub on_data {
		my ($self, $param) = @_;
		print "Got data: $param->{data}\n";
	}

The default on_data() callback will emit a "data" event.

=head3 on_error

on_error() will be called if an error occurs reading from or writing
to the stream's handle.  Its parameters are the usual for Reflex:

	sub on_error {
		my ($self, $param) = @_;
		print "$param->{errfun} error $param->{errnum}: $param->{errstr}\n";
	}

The default on_error() callback will emit a "error" event.
It will also call stopped().

When overriding this callback, please be sure to call stopped(), which
is provided by Reflex::Role::Collectible.  Calling stopped() is vital
for collectible objects to be released from memory when managed by
Reflex::Collection.

=head2 Public Events

Reflex::Stream emits stream-related events, naturally.

=head3 closed

The "closed" event indicates that the stream is closed.  This is most
often caused by the remote end of a socket closing their connection.

See L</on_closed> for more details.

=head3 data

The "data" event is emitted when a stream produces data to work with.
It includes a single parameter, also "data", containing the raw octets
read from the handle.

See L</on_data> for more details.

=head3 error

Reflex::Stream emits "error" when any of a number of calls fails.

See L</on_error> for more details.

=head1 EXAMPLES

eg/EchoStream.pm in the distribution is the same EchoStream that
appears in the SYNOPSIS.

eg/eg-38-promise-client.pl shows a lengthy inline usage of
Reflex::Stream and a few other classes.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Reflex|Reflex>

=item *

L<Reflex>

=item *

L<Reflex::Role::SigCatcher>

=item *

L<Reflex::Role::PidCatcher>

=item *

L<Reflex::PID>

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

