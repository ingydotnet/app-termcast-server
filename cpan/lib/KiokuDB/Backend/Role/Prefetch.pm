package KiokuDB::Backend::Role::Prefetch;
BEGIN {
  $KiokuDB::Backend::Role::Prefetch::AUTHORITY = 'cpan:NUFFIN';
}
{
  $KiokuDB::Backend::Role::Prefetch::VERSION = '0.56';
}
use Moose::Role;

use namespace::clean -except => 'meta';

requires 'prefetch';

__PACKAGE__

__END__

=pod

=head1 NAME

KiokuDB::Backend::Role::Prefetch

=head1 VERSION

version 0.56

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
