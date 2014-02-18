use strict;
use warnings;
package Search::GIN::Driver::Pack;
BEGIN {
  $Search::GIN::Driver::Pack::VERSION = '0.08';
}
# ABSTRACT:

use Moose::Role;

with qw(
    Search::GIN::Driver::Pack::Values
    Search::GIN::Driver::Pack::IDs
);

1;



=pod

=head1 NAME

Search::GIN::Driver::Pack - use Moose::Role;

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
