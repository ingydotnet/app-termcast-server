use strict;
use warnings;
package Search::GIN::Keys::Join;
BEGIN {
  $Search::GIN::Keys::Join::VERSION = '0.08';
}
# ABSTRACT:

use Moose::Role;

sub join_keys {
    my ( $self, @keys ) = @_;
    map { $self->join_key($_) } @keys;
}

sub join_key {
    my ( $self, @key ) = @_;
    no warnings 'uninitialized';
    join ":", map { ref($_) ? @$_ : $_ } @key;
}

1;



=pod

=head1 NAME

Search::GIN::Keys::Join - use Moose::Role;

=head1 VERSION

version 0.08

=head1 AUTHOR

Yuval Kogman <nothingmuch@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

