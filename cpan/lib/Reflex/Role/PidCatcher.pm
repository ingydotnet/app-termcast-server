package Reflex::Role::PidCatcher;
{
  $Reflex::Role::PidCatcher::VERSION = '0.099';
}
# vim: ts=2 sw=2 noexpandtab

use Reflex::Role;

use Scalar::Util qw(weaken);
use Reflex::Event::SigChild;

attribute_parameter att_active    => "active";
attribute_parameter att_pid       => "pid";
callback_parameter  cb_exit       => qw( on att_pid exit );
method_parameter    method_pause  => qw( pause att_pid _ );
method_parameter    method_resume => qw( resume att_pid _ );
method_parameter    method_start  => qw( start att_pid _ );
method_parameter    method_stop   => qw( stop att_pid _ );

# A session may only watch a distinct pid once.
# So we must map each distinct pid to all the interested objects.
# This is class scoped data.
#
# TODO - We could put this closer to the POE::Session and obviate the
# need for the deliver() redirector.

my %callbacks;

sub deliver {
	my ($class, $signal_name, $pid, $exit, @etc) = @_;

	# If nobody's watching us, then why did we do it in the road?
	# TODO - Diagnostic warning/error?
	return unless exists $callbacks{$pid};

	# Deliver the signal.
	# TODO - map() magic to speed this up?

	foreach my $callback_recs (values %{$callbacks{$pid}}) {
		foreach my $callback_rec (values %$callback_recs) {
			my ($object, $method) = @$callback_rec;

			$object->$method(
				Reflex::Event::SigChild->new(
					_emitters => [ $object ],
					signal    => $signal_name,
					pid       => $pid,
					exit      => $exit,
				)
			);
		}
	}
}

# The role itself.

role {
	my $p = shift;

	my $att_active    = $p->att_active();
	my $att_pid       = $p->att_pid();
	my $cb_exit       = $p->cb_exit();

	requires $att_active, $att_pid, $cb_exit;

	my $method_start  = $p->method_start();
	my $method_stop   = $p->method_stop();
	my $method_pause  = $p->method_pause();
	my $method_resume = $p->method_resume();

	# Work around a Moose edge case.
	sub BUILD {}

	after BUILD => sub {
		my $self = shift();
		return unless $self->$att_active();
		$self->$method_start();
		return;
	};

	# Work around a Moose edge case.
	sub DEMOLISH {}

	after DEMOLISH => sub {
		shift()->$method_stop();
	};

	method $method_start => sub {
		my $self = shift;

		my $pid_value = $self->$att_pid();

		# Register this object with that PID.
		$callbacks{$pid_value}->{$self->session_id()}->{$self} = [
			$self, $cb_exit
		];
		weaken $callbacks{$pid_value}->{$self->session_id()}->{$self}->[0];

		# First time this object is watching that PID?  Start the
		# watcher.  Otherwise, a watcher should already be going.

		return if (
			(scalar keys %{$callbacks{$pid_value}->{$self->session_id()}}) > 1
		);

		$self->$method_resume();
	};

	method $method_pause => sub {
		my $self = shift;

		# Be in the session associated with this object.
		return unless $self->call_gate($method_pause);

		$POE::Kernel::poe_kernel->sig_child($self->$att_pid(), undef);
	};

	method $method_resume => sub {
		my $self = shift;

		# Be in the session associated with this object.
		return unless $self->call_gate($method_resume);

		$POE::Kernel::poe_kernel->sig_child(
			$self->$att_pid(), "signal_happened", ref($self)
		);
	};

	method $method_stop => sub {
		my $self = shift;

		my $pid_value = $self->$att_pid();

		# Nothing to do?
		return unless exists $callbacks{$pid_value}->{$self->session_id()};

		# Unregister this object with that signal.
		my $sw = $callbacks{$pid_value}->{$self->session_id()};
		return unless delete $sw->{$self};

		# Deactivate the signal watcher if this was the last object.
		unless (scalar keys %$sw) {
			delete $callbacks{$pid_value}->{$self->session_id()};
			delete $callbacks{$pid_value} unless (
				scalar keys %{$callbacks{$pid_value}}
			);
			$self->$method_pause();
		}
	};
};



=pod

=for :stopwords Rocco Caputo

=encoding UTF-8

=head1 NAME

Reflex::Role::PidCatcher - add async process reaping behavior to a class

=head1 VERSION

This document describes version 0.099, released on April 21, 2013.

=head1 SYNOPSIS

	package Reflex::PID;

	use Moose;
	extends 'Reflex::Base';

	has pid => (
		is        => 'ro',
		isa       => 'Int',
		required  => 1,
	);

	has active => (
		is      => 'ro',
		isa     => 'Bool',
		default => 1,
	);

	with 'Reflex::Role::PidCatcher' => {
		pid						=> 'pid',
		active        => 'active',
		cb_exit       => 'on_exit',
		method_start  => 'start',
		method_stop   => 'stop',
		method_pause  => 'pause',
		method_resume => 'resume',
	};

	1;

=head1 DESCRIPTION

Reflex::Role::PidCatcher is a Moose parameterized role that adds
asynchronous child process reaping behavior to Reflex based classes.
The SYNOPSIS is the entire implementation of Reflex::PID, a simple
class that allows Reflex::Role::PidCatcher to be used as an object.

=head2 Required Role Parameters

None.  All role parameters as of this writing have what we hope are
sensible defaults.  Please let us know if they don't seem all that
sensible.

=head2 Optional Role Parameters

=head3 pid

C<pid> sets the name of an attribute that will contain the process ID
to wait for.  Process IDs must be integers.

=head3 active

C<active> specifies whether Reflex::Role::PidCatcher should be created
in the active, process-watching state.  All Reflex watchers are
enabled by default.  Set it to a false value, preferably 0, to
initialize the catcher in an inactive or paused mode.

Process watchers may currently be paused and resumed, but this
functionality may be dropped later.  It's not good to leave child
processes hanging.  See C<method_pause> and C<method_resume> for ways
to override the default method names.

=head3 cb_exit

C<cb_exit> names the $self method that will be called when the child
process identified in C<<$self->$pid()>> exits.  It defaults to
"on_%s_exit", where %s is the name of the PID attribute.  For example,
it will be "on_transcoder_exit" if the process ID is stored in a
"transcoder" attribute.

=head3 method_start

C<method_start> sets the name of the method that may be used to start
watching for a process exit.  It's "start_%s" by default, where %s is
the name of the process ID's attribute.

Reflex::Role::PidCatcher will automatically start watching for its
process ID if the value of C<active>'s attribute is true.

=head3 method_stop

C<method_stop> may be used to permanently stop a process ID watcher.
Stopped watchers cannot be restarted, so use C<method_pause> if you
need to temporarily disable them instead.  C<method_resume> may be
used to resume them again.

Process ID catchers will automatically stop watching for process exit
upon DEMOLISH.

=head3 method_pause

C<method_pause> sets the name of the method that may be used to pause
process catching.  It is "pause_%s" by default, where %s is the name
of the PID attribute.

=head3 method_resume

C<method_resume> sets the name of the method that may be used to
resume process reaping.  It is "resume_%s" by default, where %s is the
name of the attribute holding the process ID.

=head1 EXAMPLES

Reflex::Role::PidCatcher was initially written to support Reflex::PID,
so there aren't many examples of the role's use by itself.

L<Reflex::POE::Wheel::Run> actualy uses Reflex::PID.

eg/eg-07-wheel-run.pl uses Reflex::POE::Wheel::Run.

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

L<Reflex::Signal>

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

