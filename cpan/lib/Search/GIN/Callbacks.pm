use strict;
use warnings;
package Search::GIN::Callbacks;
BEGIN {
  $Search::GIN::Callbacks::VERSION = '0.08';
}
# ABSTRACT: Provide callbacks

use Moose::Role;

with qw(Search::GIN::Core);

foreach my $cb (
    qw(objects_to_ids extract_values extract_query compare_values
        consistent ids_to_objects) ) {
    has "${cb}_callback" => (
        isa => "CodeRef",
        is  => "rw",
        required => 1,
    );

    eval "sub $cb { \$self->${cb}_callback->(@_) }";
}

1;



=pod

=head1 NAME

Search::GIN::Callbacks - Provide callbacks

=head1 VERSION

version 0.08

=head1 DESCRIPTION

This role provides a few callbacks for L<Search::GIN>.

=head1 AUTHOR

Yuval Kogman <nothingmuch@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

