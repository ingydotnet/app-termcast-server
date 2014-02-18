package Reflex::Role::Writing;
{
  $Reflex::Role::Writing::VERSION = '0.099';
}
# vim: ts=2 sw=2 noexpandtab

use Reflex::Role;
use Reflex::Event::Error;

attribute_parameter att_handle    => "handle";
callback_parameter  cb_error      => qw( on att_handle error );
method_parameter    method_flush  => qw( flush att_handle _ );
method_parameter    method_put    => qw( put att_handle _ );

role {
	my $p = shift;

	my $att_handle    = $p->att_handle();
	my $cb_error      = $p->cb_error();

	requires $att_handle, $cb_error;

	my $method_flush  = $p->method_flush();

	has out_buffer => (
		is      => 'rw',
		isa     => 'ScalarRef',
		default => sub { my $x = ""; \$x },
	);

	method $method_flush => sub {
		my ($self, $arg) = @_;

		my $out_buffer = $self->out_buffer();
		my $octet_count = syswrite($self->$att_handle(), $$out_buffer);

		# Hard error.
		unless (defined $octet_count) {
			$self->$cb_error(
				Reflex::Event::Error->new(
					_emitters => [ $self ],
					number    => ($! + 0),
					string    => "$!",
					function  => "syswrite",
				)
			);
			return;
		}

		# Remove what we wrote.
		substr($$out_buffer, 0, $octet_count, "");

		# Pause writes if it all was flushed.
		return length $$out_buffer;
	};

	method $p->method_put() => sub {
		my ($self, @chunks) = @_;

		# TODO - Benchmark string vs. array buffering?
		# Stack Overflow suggests that string buffering is more efficient,
		# but it doesn't discuss the relative efficiencies of substr() vs.
		# shift to remove the buffer's head.
		# http://stackoverflow.com/questions/813752/how-can-i-pre-allocate-a-string-in-perl

		use bytes;

		my $out_buffer = $self->out_buffer();
		if (length $$out_buffer) {
			$$out_buffer .= $_ foreach @chunks;
			return 2;
		}

		# Try to flush 'em all.
		while (@chunks) {
			my $next = shift @chunks;
			my $octet_count = syswrite($self->$att_handle(), $next);

			# Hard error.
			unless (defined $octet_count) {
				$self->$cb_error(
					Reflex::Event::Error->new(
						_emitters => [ $self ],
						number    => ($! + 0),
						string    => "$!",
						function  => "syswrite",
					)
				);
				return;
			}

			# Wrote it all!  Whooooo!
			next if $octet_count == length $next;

			# Wrote less than all.  Save the rest, and turn on write
			# multiplexing.
			$$out_buffer = substr($next, $octet_count);
			$$out_buffer .= $_ foreach @chunks;

			return 1;
		}

		# Flushed it all.  Yay!
		return 0;
	};
};

1;



=pod

=for :stopwords Rocco Caputo

=encoding UTF-8

=head1 NAME

Reflex::Role::Writing - add buffered non-blocking syswrite() to a class

=head1 VERSION

This document describes version 0.099, released on April 21, 2013.

=head1 SYNOPSIS

TODO - Changed again.  It would be stellar if I could include a
different bit of code as a synopsis or something, huh?

	package OutputStreaming;
	use Reflex::Role;

	attribute_parameter handle       => "handle";
	callback_parameter  cb_error     => qw( on handle error );
	method_parameter    method_put   => qw( put handle _ );
	method_parameter    method_stop  => qw( stop handle _ );
	method_parameter    method_flush => qw( _flush handle writable );

	role {
		my $p = shift;

		my $att_handle         = $p->handle();
		my $cb_error  = $p->cb_error();

		with 'Reflex::Role::Writing' => {
			handle        => $att_handle,
			cb_error      => $p->cb_error(),
			method_put    => $p->method_put(),
			method_flush  => $p->method_flush(),
		};

		with 'Reflex::Role::Writable' => {
			handle        => $att_handle,
			cb_ready      => $p->method_flush(),
		};

=head1 DESCRIPTION

Reflex::Role::Readable implements a standard nonblocking sysread()
feature so that it may be added to classes as needed.

There's a lot going on in the SYNOPSIS.

Reflex::Role::Writing defines methods that will perform non-blocking,
buffered syswrite() on a named "handle".  It has a single callback,
"cb_error", that is invoked if syswrite() ever returns an error.  It
defines a method, "method_put", that is used to write new data to the
handle---or buffer data if it can't be written immediately.
"method_flush" is defined to flush buffered data when possible.

Reflex::Role::Writable implements the other side of the
Writable/Writing contract.  It wastches a "handle" and invokes
"cb_ready" whenever the opportunity to write new data arises.  It
defines a few methods, two of which allow the watcher to be paused and
resumed.

The Writable and Writing roles are generally complementary.  Their
defaults allow them to fit together more succinctly than (and less
understandably than) shown in the SYNOPSIS.

=head2 Attribute Role Parameters

=head3 handle

C<handle> names an attribute holding the handle to be watched for
writable readiness.

=head2 Callback Role Parameters

=head3 cb_error

C<cb_error> names the $self method that will be called whenever the
stream produces an error.  By default, this method will be the
catenation of "on_", the C<handle> name, and "_error".  As in
on_XYZ_error(), if the handle is named "XYZ".  The role defines a
default callback that will emit an "error" event with cb_error()'s
parameters, then will call stopped() so that streams managed by
Reflex::Collection will be automatically cleaned up after stopping.

C<cb_error> callbacks receive two parameters, $self and an anonymous
hashref of named values specific to the callback.  Reflex error
callbacks include three standard values.  C<errfun> contains a
single word description of the function that failed.  C<errnum>
contains the numeric value of C<$!> at the time of failure.  C<errstr>
holds the stringified version of C<$!>.

Values of C<$!> are passed as parameters since the global variable may
change before the callback can be invoked.

When overriding this callback, please be sure to call stopped(), which
is provided by Reflex::Role::Collectible.  Calling stopped() is vital
for collectible objects to be released from memory when managed by
Reflex::Collection.

=head2 Method Role Parameters

=head3 method_put

This role genrates a method to write data to the handle in the
"handle" attribute.  The "method_put" role parameter specifies the
name of this generated method.  The method's name will be
"put_${handle_name}" by default.

The generated method will immediately attempt to write data if the
role's buffer is empty.  If the buffer contains data, however, then
the new data will be appended there to maintain the ordering of data
in the stream.  Any data that could not be written during "method_put"
will be added to the buffer as well.

The "method_put" implementation will call "method_resume_writable" to
enable background flushing, as needed.

The generated "method_put" will return a numeric code representing the
current state of the role's output buffer.  Undef if syswrite failed,
after "cb_error" has been called.  It returns 0 if the buffer is still
empty after the syswrite().  It returns 1 if the buffer begins to
contain data, or 2 if the buffer already contained data and now holds
more.

The return code is intended to control Reflex::Role::Writable, via
some glue code in the class or role that consumes both.  When
"method_put" returns 1, the consumer should begin triggering
"method_flush" calls on writability callbacks.  The consumer should
stop writability callbacks when "method_flush" returns 0 (no more
octets in the buffer).

=head3 method_flush

This role generates a method to flush data that had to be buffered by
previous "method_put" calls.  It's designed to be used with some kind
of callback system, such as Reflex::Role::Writable's callbacks.

The "method_flush" implementation returns undef on error.  It will
return the number of octets remaining in the buffer, or zero if the
buffer has been completely flushed.

The "method_flush" return value may be used to disable writability
watchers, such as the one provided by Reflex::Role::Writable.  See the
source for Reflex::Role::Streaming for an up-to-date example.

=head1 TODO

There's always something.

=head1 EXAMPLES

Reflex::Role::Streaming is an up-to-date example.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Reflex|Reflex>

=item *

L<Reflex>

=item *

L<Reflex::Role>

=item *

L<Reflex::Role::Writable>

=item *

L<Reflex::Role::Readable>

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

