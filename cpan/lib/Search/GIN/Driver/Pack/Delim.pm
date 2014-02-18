use strict;
use warnings;
package Search::GIN::Driver::Pack::Delim;
BEGIN {
  $Search::GIN::Driver::Pack::Delim::VERSION = '0.08';
}
# ABSTRACT:

use Moose::Role;

use namespace::clean -except => [qw(meta)];

sub pack_delim {
    my ( $self, @strings ) = @_;
    join("\0", @strings );
}

sub unpack_delim {
    my ( $self, $string ) = @_;
    split("\0", $string );
}

1;



=pod

=head1 NAME

Search::GIN::Driver::Pack::Delim - use Moose::Role;

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
