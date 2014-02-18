use strict;
use warnings;
package Search::GIN::Extract;
BEGIN {
  $Search::GIN::Extract::VERSION = '0.08';
}
# ABSTRACT:

use Moose::Role;

use namespace::clean -except => 'meta';

requires 'extract_values';

1;



=pod

=head1 NAME

Search::GIN::Extract - use Moose::Role;

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
