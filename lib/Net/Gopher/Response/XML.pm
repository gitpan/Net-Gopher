# Copyright 2003 by William G. Davis.
# 
# This module defines and exports on demand functions used to dynamcically
# generate XML for Gopher and Gopher+ responses. You really don't need to be
# looking in here unless you plan on hacking Net::Gopher.

package Net::Gopher::Response::XML;

use 5.005;
use warnings;
use strict;
use vars qw(@EXPORT_OK);
use base 'Exporter';
use Net::Gopher::Constants qw(:request :item_types);
use Net::Gopher::Utility '%ITEM_DESCRIPTIONS';

@EXPORT_OK = qw(
	gen_block_xml
	gen_menu_xml
	gen_text_xml
);







################################################################################
#
#	Function
#		gen_block_xml($response, $writer)
#
#	Purpose
#		This method generates XML for Gopher+ item/directory attribute
#		information blocks.
#
#	Parameters
#		$response - A Net::Gopher::Response object.
#		$writer   - An XML::Writer object.
#

sub gen_block_xml
{
	my ($response, $writer) = @_;



	# if we don't do this, we get a ton of "Use of unitialized..." errors:
	local $^W = 0;

	if ($response->request->request_type == ITEM_ATTRIBUTE_REQUEST)
	{
		$writer->startTag('response',
			description => 'item attribute information request',
			url         => $response->request->as_url
		);
	}
	else
	{
		$writer->startTag('response',
			description => 'directory attribute information request',
			url         => $response->request->as_url
		);
	}



	my @items = ($response->request->request_type == ITEM_ATTRIBUTE_REQUEST)
				? [ $response->get_blocks ]
				:   $response->get_blocks;

	foreach my $item (@items)
	{
		$writer->startTag('item');

		foreach my $block (@$item)
		{
			$writer->startTag('block', name => $block->name);

			if ($block->name eq '+ASK')
			{
				foreach my $query ($block->extract_ask_queries)
				{
					$writer->startTag('query');
					$writer->dataElement(
						'type', $query->{'type'}
					);
					$writer->dataElement(
						'question', $query->{'question'}
					);

					foreach my $answer (@{$query->{'defaults'}})
					{
						$writer->dataElement(
							'default-answer', $answer
						);
					}

					$writer->endTag('query');
				}
			}
			elsif ($block->name eq '+INFO')
			{
				my ($type, $display, $selector,
				    $host, $port, $gopher_plus) =
						$block->extract_description;

				$writer->dataElement('item-type', $type);
				$writer->dataElement(
					'display-string', $display
				);
				$writer->dataElement(
					'selector-string', $selector
				);
				$writer->dataElement('host', $host);
				$writer->dataElement('port', $port);
				$writer->dataElement(
					'gopher-plus-string', $gopher_plus
				);
			}
			elsif ($block->name eq '+VIEWS')
			{
				foreach my $view ($block->extract_views)
				{
					$writer->startTag('view');
					$writer->dataElement(
						'mime-type', $view->{'type'}
					);
					$writer->dataElement(
						'language', $view->{'language'}
					);
					$writer->dataElement(
						'country', $view->{'country'}
					);
					$writer->dataElement(
						'bytes', $view->{'size'}
					);
					$writer->endTag('view');
				}
			}
			elsif ($block->is_attributes)
			{
				my %attributes = $block->attributes_as_hash;

				while (my ($name, $value) = each %attributes)
				{
					$writer->dataElement(
						'attribute',
						$value, name => $name
					);
				}
			}
			else
			{
				$writer->characters($block->value)
			}

			$writer->endTag('block');
		}

		$writer->endTag('item');
	}



	$writer->endTag('response');
}





################################################################################
#
#	Function
#		gen_menu_xml($response, $writer)
#
#	Purpose
#		This method generates XML for Gopher and Gopher+ menus.
#
#	Parameters
#		$response - A Net::Gopher::Response object.
#		$writer   - An XML::Writer object.
#

sub gen_menu_xml
{
	my ($response, $writer) = @_;



	local $^W = 0;

	$writer->startTag('response',
		'item-type' => $response->request->item_type,
		description =>
			exists $ITEM_DESCRIPTIONS{$response->request->item_type}
				? $ITEM_DESCRIPTIONS{$response->request->item_type}
				: 'unknown item',
		url         => $response->request->as_url
	);

	foreach my $menu_item ($response->extract_items)
	{
		if ($menu_item->item_type eq INLINE_TEXT_TYPE)
		{
			$writer->dataElement('inline-text', $menu_item->display);
		}
		else
		{
			$writer->startTag('item', url => $menu_item->as_url);
			$writer->dataElement('item-type', $menu_item->item_type);
			$writer->dataElement('display-string', $menu_item->display);
			$writer->dataElement('selector-string', $menu_item->selector);
			$writer->dataElement('host', $menu_item->host);
			$writer->dataElement('port', $menu_item->port);
			$writer->dataElement(
				'gopher-plus-string', $menu_item->gopher_plus);
			$writer->endTag('item');
		}
	}



	$writer->endTag('response');
}





################################################################################
#
#	Function
#		gen_text_xml($response, $writer)
#
#	Purpose
#		This method generates XML for text items.
#
#	Parameters
#		$response - A Net::Gopher::Response object.
#		$writer   - An XML::Writer object.
#

sub gen_text_xml
{
	my ($response, $writer) = @_;


	
	local $^W = 0;

	$writer->startTag('response',
		'item-type' => $response->request->item_type,
		description =>
			exists $ITEM_DESCRIPTIONS{$response->request->item_type}
				? $ITEM_DESCRIPTIONS{$response->request->item_type}
				: 'unknown item',
		url         => $response->request->as_url,
	);
	$writer->dataElement('content', $response->content);
	$writer->endTag('response');
}

1;
