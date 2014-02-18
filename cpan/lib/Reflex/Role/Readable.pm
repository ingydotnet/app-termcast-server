package Reflex::Role::Readable;
{
  $Reflex::Role::Readable::VERSION = '0.099';
}
# vim: ts=2 sw=2 noexpandtab

use Reflex::Role;
use Reflex::Event::FileHandle;

# TODO - Reflex::Role::Readable and Writable are nearly identical.
# Can they be abstracted further?  Possibly composed as parameterized
# instances of a common base role?

use Scalar::Util qw(weaken);

attribute_parameter att_handle    => "handle";
attribute_parameter att_active    => "active";
callback_parameter  cb_ready      => qw( on att_handle readable );
method_parameter    method_pause  => qw( pause att_handle readable );
method_parameter    method_resume => qw( resume att_handle readable );
method_parameter    method_stop   => qw( stop att_handle readable );

role {
	my $p = shift;

	my $att_active = $p->att_active();
	my $att_handle = $p->att_handle();
	my $cb_name    = $p->cb_ready();

	requires $att_active, $att_handle, $cb_name;

	my $setup_name = "_setup_${att_handle}_readable";

	method $setup_name => sub {
		my ($self, $arg) = @_;

		# Must be run in the right POE session.
		return unless $self->call_gate($setup_name, $arg);

		my $envelope = [ $self, $cb_name, 'Reflex::Event::FileHandle' ];
		weaken $envelope->[0];

		$POE::Kernel::poe_kernel->select_read(
			$self->$att_handle(), 'select_ready', $envelope,
		);

		return if $self->$att_active();

		$POE::Kernel::poe_kernel->select_pause_read($self->$att_handle());
	};

	my $method_pause = $p->method_pause();
	method $method_pause => sub {
		my $self = shift;
		return unless $self->call_gate($method_pause);
		$POE::Kernel::poe_kernel->select_pause_read($self->$att_handle());
	};

	my $method_resume = $p->method_resume();
	method $p->method_resume => sub {
		my $self = shift;
		return unless $self->call_gate($method_resume);
		$POE::Kernel::poe_kernel->select_resume_read($self->$att_handle());
	};

	my $method_stop = $p->method_stop();
	method $method_stop => sub {
		my $self = shift;
		return unless $self->call_gate($method_stop);
		$POE::Kernel::poe_kernel->select_read($self->$att_handle(), undef);
	};

	# Work around a Moose edge case.
	sub BUILD {}

	after BUILD => sub {
		my ($self, $arg) = @_;
		$self->$setup_name($arg);
	};

	# Work around a Moose edge case.
	sub DEMOLISH {}

	# Turn off watcher during destruction.
	after DEMOLISH => sub {
		my $self = shift;
		$self->$method_stop();
	};
};

1;



=pod

=for :stopwords Rocco Caputo

=encoding UTF-8

=head1 NAME

Reflex::Role::Readable - add readable-watching behavior to a class

=head1 VERSION

This document describes version 0.099, released on April 21, 2013.

=head1 SYNOPSIS

	use Moose;

	has socket => ( is => 'rw', isa => 'FileHandle', required => 1 );

	with 'Reflex::Role::Readable' => {
		handle   => 'socket',
		cb_ready => 'on_socket_readable',
		active   => 1,
	};

	sub on_socket_readable {
		my ($self, $arg) = @_;
		print "Data is ready on socket $arg->{handle}.\n";
		$self->pause_socket_readabe();
	}

=head1 DESCRIPTION

Reflex::Role::Readable is a Moose parameterized role that adds
readable-watching behavior for Reflex-based classes.  In the SYNOPSIS,
a filehandle named "socket" is watched for readability.  The method
on_socket_readable() is called when data becomes available.

TODO - Explain the difference between role-based and object-based
composition.

=head2 Required Role Parameters

=head3 handle

The C<handle> parameter must contain the name of the attribute that
holds the handle to watch.  The name indirection allows the role to
generate unique methods by default.  For example, a handle named "XYZ"
would generates these methods by default:

	cb_ready      => "on_XYZ_readable",
	method_pause  => "pause_XYZ_readable",
	method_resume => "resume_XYZ_readable",
	method_stop   => "stop_XYZ_readable",

This naming convention allows the role to be used for more than one
handle in the same class.  Each handle will have its own name, and the
mixed in methods associated with them will also be unique.

=head2 Optional Role Parameters

=head3 active

C<active> specifies whether the Reflex::Role::Readable watcher should
be enabled when it's initialized.  All Reflex watchers are enabled by
default.  Set it to a false value, preferably 0, to initialize the
watcher in an inactive or paused mode.

Readability watchers may be paused and resumed.  See C<method_pause>
and C<method_resume> for ways to override the default method names.

=head3 cb_ready

C<cb_ready> names the $self method that will be called whenever
C<handle> has data to be read.  By default, it's the catenation of
"on_", the C<handle> name, and "_readable".  A handle named "XYZ" will
by default trigger on_XYZ_readable() callbacks.

	handle => "socket",  # on_socket_readable()
	handle => "XYZ",     # on_XYZ_readable()

All Reflex parameterized role callbacks are invoked with two
parameters: $self and an anonymous hashref of named values specific to
the callback.  C<cb_ready> callbacks include a single named value,
C<handle>, that contains the filehandle from which has become ready
for reading.

C<handle> is the handle itself, not the handle attribute's name.

=head3 method_pause

C<method_pause> sets the name of the method that may be used to pause
the watcher.  It is "pause_${handle}_readable" by default.

=head3 method_resume

C<method_resume> may be used to resume paused readability watchers, or
to activate them if they are started in an inactive state.

=head3 method_stop

C<method_stop> may be used to stop readability watchers.  These
watchers may not be restarted once they've been stopped.  If you want
to pause and resume watching, see C<method_pause> and
C<method_resume>.

=head1 EXAMPLES

TODO - I'm sure there are some.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Reflex|Reflex>

=item *

L<Reflex>

=item *

L<Reflex::Role::Writable>

=item *

L<Reflex::Role::Streaming>

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

