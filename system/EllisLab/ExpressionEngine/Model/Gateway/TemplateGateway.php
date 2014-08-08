<?php
namespace EllisLab\ExpressionEngine\Model\Gateway;

class TemplateGateway extends RowDataGateway {

	protected static $_table_name 		= 'templates';
	protected static $_primary_key 		= 'template_id';
	protected static $_related_gateways	= array(
		'site_id' => array(
			'gateway' => 'SiteGateway',
			'key'	 => 'site_id'
		),
		'group_id' => array(
			'gateway' => 'TemplateGroupGateway',
			'key'    => 'group_id'
		),
		'last_author_id' => array(
			'gateway' => 'MemberGateway',
			'key'	 => 'member_id'
		),
	);
	protected static $_validation_rules = array(
		'template_id' => 'required|isNatural',
		'site_id' => 'required|isNatural',
		'group_id' => 'required|isNatural',
		'template_name' => 'required|alphaDash'
	);


	// Properties
	protected $template_id;
	protected $site_id;
	protected $group_id;
	protected $template_name;
	protected $save_template_file;
	protected $template_type;
	protected $template_data;
	protected $template_notes;
	protected $edit_date;
	protected $last_author_id;
	protected $cache;
	protected $refresh;
	protected $no_auth_bounce;
	protected $enable_http_auth;
	protected $allow_php;
	protected $php_parse_location;
	protected $hits;


}