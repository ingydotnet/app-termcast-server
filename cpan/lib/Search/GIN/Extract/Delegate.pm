use strict;
use warnings;
package Search::GIN::Extract::Delegate;
BEGIN {
  $Search::GIN::Extract::Delegate::VERSION = '0.08';
}
# ABSTRACT:

use Moose::Role;
use namespace::clean -except => 'meta';

has extract => (
    does => "Search::GIN::Extract",
    is   => "ro",
    required => 1,
    # handles => "Search::GIN::Extract"
);

sub extract_values { shift->extract->extract_values(@_) }

1;



=pod

=head1 NAME

Search::GIN::Extract::Delegate - use Moose::Role;

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
