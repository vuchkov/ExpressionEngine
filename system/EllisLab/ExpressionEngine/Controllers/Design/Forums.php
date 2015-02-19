<?php

namespace EllisLab\ExpressionEngine\Controllers\Design;

use EllisLab\ExpressionEngine\Controllers\Design\AbstractDesign as AbstractDesignController;
use EllisLab\ExpressionEngine\Library\CP\Table;
use EllisLab\ExpressionEngine\Library\CP\URL;

/**
 * ExpressionEngine - by EllisLab
 *
 * @package		ExpressionEngine
 * @author		EllisLab Dev Team
 * @copyright	Copyright (c) 2003 - 2015, EllisLab, Inc.
 * @license		http://ellislab.com/expressionengine/user-guide/license.html
 * @link		http://ellislab.com
 * @since		Version 3.0
 * @filesource
 */

// ------------------------------------------------------------------------

/**
 * ExpressionEngine CP Design\Forums Class
 *
 * @package		ExpressionEngine
 * @subpackage	Control Panel
 * @category	Control Panel
 * @author		EllisLab Dev Team
 * @link		http://ellislab.com
 */
class Forums extends AbstractDesignController {

	/**
	 * Constructor
	 */
	function __construct()
	{
		parent::__construct();

		if (ee()->config->item('forum_is_installed') != "y")
		{
			show_404();
		}

		if ( ! ee()->cp->allowed_group('can_access_design'))
		{
			show_error(lang('unauthorized_access'));
		}

		$this->stdHeader();

		ee()->lang->loadfile('specialty_tmp');
	}

	public function index($theme = 'default')
	{
		$base_path = PATH_ADDONS_THEMES . '/forum_themes/' . ee()->security->sanitize_filename($theme);

		if ( ! is_dir($base_path))
		{
			show_error(lang('unable_to_find_templates'));
		}

		$this->load->helper('directory');

		$vars = array();

		$base_url = new URL('design/forums/index/' . $theme, ee()->session->session_id());

		$table = Table::create(array('autosort' => TRUE, 'subheadings' => TRUE));
		$table->setColumns(
			array(
				'template',
				'manage' => array(
					'type'	=> Table::COL_TOOLBAR
				),
			)
		);

		$data = array();
		foreach (directory_map($base_path, TRUE) as $dir)
		{
			$path = $base_path . '/' . $dir;

			foreach (directory_map($path, TRUE) as $file)
			{
				if (strpos($file, '.') !== FALSE)
				{
					$human = ucwords(str_replace('_', ' ', substr($file, 0, -strlen(strrchr($file, '.')))));
					$data[$dir][] = array(
						(lang($human) == FALSE) ? $human : lang($human),
						array('toolbar_items' => array(
							'edit' => array(
								'href' => cp_url('design/forums/edit/' . $theme . '/' . $dir . '/' . $human),
								'title' => lang('edit')
							),
						))
					);
				}
			}

		}

		$table->setData($data);

		$vars['table'] = $table->viewData($base_url);
		$vars['form_url'] = $vars['table']['base_url'];

		ee()->load->model('member_model');

		$themes = array();
		foreach (directory_map(PATH_ADDONS_THEMES . '/forum_themes/', TRUE) as $dir)
		{
			if (is_dir(PATH_ADDONS_THEMES . '/forum_themes/' . $dir))
			{
				$themes[cp_url('design/forums/index/' . $dir)] = ucfirst(str_replace("_", " ", $dir));
			}
		}

		$vars['themes'] = form_dropdown('theme', $themes, cp_url('design/forums/index/' . $theme));

		$this->sidebarMenu('forums');
		ee()->view->cp_page_title = lang('template_manager');
		ee()->view->cp_heading = lang('forum_templates');

		ee()->javascript->change("select[name=\'theme\']", 'window.location.href = $(this).val()');

		ee()->view->cp_breadcrumbs = array(
			cp_url('addons/settings/forum') => lang('forum_manager'),
		);

		ee()->cp->render('design/forums/index', $vars);
	}

	public function edit($theme, $dir, $file)
	{
		$path = PATH_ADDONS_THEMES . '/forum_themes/'
			.ee()->security->sanitize_filename($theme)
			.'/'
			.ee()->security->sanitize_filename($dir)
			.'/'
			.ee()->security->sanitize_filename($file . '.html');

		if ( ! file_exists($path))
		{
			show_error(lang('unable_to_find_template_file'));
		}

		$template_name = ucwords(str_replace('_', ' ', $file));

		if ( ! empty($_POST))
		{
			if ( ! write_file($path, ee()->input->post('template_data')))
			{
				show_error(lang('error_opening_template'));
			}
			else
			{
				ee()->functions->clear_caching('all');

				$alert = ee('Alert')->makeInline('template-form')
					->asSuccess()
					->withTitle(lang('update_template_success'))
					->addToBody(sprintf(lang('update_template_success_desc'), $template_name));

				if (ee()->input->post('submit') == 'finish')
				{
					$alert->defer();
					ee()->functions->redirect(cp_url('design/forums'));
				}

				$alert->now();
			}
		}

		if ( ! is_really_writable($path))
		{
			ee('Alert')->makeInline('message-warning')
				->asWarning()
				->cannotClose()
				->withTitle(lang('file_not_writable'))
				->addToBody(lang('file_writing_instructions'))
				->now();
		}

		$fp = fopen($path, 'r');
		$fstat = fstat($fp);
		fclose($fp);

		$vars = array(
			'form_url'      => cp_url('design/forums/edit/' . $theme . '/' . $dir . '/' . $file),
			'edit_date'     => ee()->localize->human_time($fstat['mtime']),
			'template_data' => file_get_contents($path),
		);

		$this->loadCodeMirrorAssets();

		ee()->view->cp_page_title = sprintf(lang('edit_template'), $template_name);
		ee()->view->cp_breadcrumbs = array(
			cp_url('design') => lang('template_manager'),
			cp_url('design/forums/') => sprintf(lang('breadcrumb_group'), lang('forums'))
		);

		ee()->cp->render('design/forums/edit', $vars);
	}
}
// EOF