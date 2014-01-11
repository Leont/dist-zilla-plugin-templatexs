package Dist::Zilla::Plugin::TemplateXS;

use Moose;
with qw(Dist::Zilla::Role::FileGatherer Dist::Zilla::Role::TextTemplate);

use Path::Tiny;

use namespace::autoclean;

use Sub::Exporter::ForMethods;
use Data::Section 0.200002 { installer => Sub::Exporter::ForMethods::method_installer }, '-setup';
use Dist::Zilla::File::InMemory;
use Moose::Util::TypeConstraints;

has template => (
	is	=> 'ro',
	isa => 'Str',
	predicate => 'has_template',
);

has style => (
	is  => 'ro',
	isa => enum(['MakeMaker', 'ModuleBuild']),
	required => 1,
);

sub filename {
	my ($self, $name) = @_;
	my @module_parts = split /::/, $name;
	if ($self->style eq 'MakeMaker') {
		return path('lib', $module_parts[-1].'.xs');
	}
	elsif ($self->style eq 'ModuleBuild') {
		return path('lib', @module_parts) . '.xs';
	}
	else {
		confess 'Invalid style for XS file generation';
	}
}

sub content {
	my ($self, $name) = @_;
	my $template = $self->has_template ? path($self->template)->slurp_utf8 : ${ $self->section_data('Module.xs') };
	return $self->fill_in_string($template, { dist => \($self->zilla), name => $name });
}

sub gather_files {
	my $self = shift;
	(my $name = $self->zilla->name) =~ s/-/::/g;
	$self->add_file(Dist::Zilla::File::InMemory->new({ name => $self->filename($name), content => $self->content($name) }));
	return;
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: A simple xs-file-from-template plugin

__DATA__
__[ Module.xs ]__
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = {{ $name }}				PACKAGE = {{ $name }}

PROTOTYPES: DISABLED

