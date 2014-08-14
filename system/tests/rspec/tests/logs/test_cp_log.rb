require './bootstrap.rb'

feature 'CP Log' do

  before(:each) do
	cp_session

	@page = CpLog.new
	@page.generate_data(count: 150, timestamp_min: 26)
	@page.generate_data(count: 35, member_id: 2, username: 'johndoe', timestamp_min: 25)
	add_member(username: 'johndoe')
	@page.load

	# These should always be true at all times if not something has gone wrong
	@page.displayed?
	@page.title.text.should eq 'Control Panel Access Logs'
	@page.should have_phrase_search
	@page.should have_submit_button
	@page.should have_username_filter
	# @page.should have_site_filter # This will not be present if MSM is diabled or we are running Core
	@page.should have_date_filter
	@page.should have_perpage_filter
  end

  it 'shows the Control Panel Access Logs page' do
	@page.should have_remove_all
	@page.should have_pagination

	@page.perpage_filter.text.should eq "show (50)"

	@page.should have(6).pages
	@page.pages.map {|name| name.text}.should == ["First", "1", "2", "3", "Next", "Last"]

	@page.should have(50).items # Default is 50 per page
  end

  # Confirming phrase search
  it 'searches by phrases' do
  	our_action = "Rspec entry for search"

  	@page.generate_data(count: 1, timestamp_max: 0, action: our_action)
  	@page.load

	# Be sane and make sure it's there before we search for it
	@page.should have_text our_action

	@page.phrase_search.set "Rspec"
	@page.submit_button.click
	no_php_js_errors

	@page.phrase_search.value.should eq "Rspec"
	@page.should have_text our_action
	@page.should have(1).items
  end

  # Confirming individual filter behavior
  it 'filters by username' do
	@page.username_filter.click
	@page.wait_until_username_filter_menu_visible
	@page.username_filter_menu.click_link "johndoe"
	no_php_js_errors

	@page.username_filter.text.should eq "username (johndoe)"
	@page.should have(35).items
	@page.should_not have_pagination
  end

  it 'filters by custom username' do
	@page.username_filter.click
	@page.wait_until_username_manual_filter_visible
	@page.username_manual_filter.set "johndoe"
	@page.submit_button.click
	no_php_js_errors

	@page.username_filter.text.should eq "username (johndoe)"
	@page.should have(35).items
	@page.should_not have_pagination
  end

  # @TODO Need data for extra site in order to filter by it
  # it 'filters by site' do
  #	  @page.site_filter.select "foobarbaz"
  #	  @page.submit_button.click
  #
  #	  @page.should have(x).items
  # end

  # Since this logs in a user we should have 1 entry!
  it 'filters by date' do
	@page.date_filter.click
	@page.wait_until_date_filter_menu_visible
	@page.date_filter_menu.click_link "Last 24 Hours"
	no_php_js_errors

	@page.date_filter.text.should eq "date (Last 24 Hours)"
	@page.should have(1).items
  end

  it 'can change page size' do
	@page.perpage_filter.click
	@page.wait_until_perpage_filter_menu_visible
	@page.perpage_filter_menu.click_link "25"
	no_php_js_errors

	@page.perpage_filter.text.should eq "show (25)"
	@page.should have(25).items
	@page.should have_pagination
	@page.should have(6).pages
	@page.pages.map {|name| name.text}.should == ["First", "1", "2", "3", "Next", "Last"]
  end

  it 'can set a custom limit' do
	@page.perpage_filter.click
	@page.wait_until_perpage_manual_filter_visible
	@page.perpage_manual_filter.set "42"
	@page.submit_button.click
	no_php_js_errors

	@page.perpage_filter.text.should eq "show (42)"
	@page.should have(42).items
	@page.should have_pagination
	@page.should have(6).pages
	@page.pages.map {|name| name.text}.should == ["First", "1", "2", "3", "Next", "Last"]
  end

  # Confirming combining filters work
  it 'can combine username and page size filters' do
	@page.perpage_filter.click
	@page.wait_until_perpage_filter_menu_visible
	@page.perpage_filter_menu.click_link "150"
	no_php_js_errors

	# First, confirm we have both 'admin' and 'johndoe' on same page
	@page.perpage_filter.has_select?('perpage', :selected => "150 results")
	@page.should have(150).items
	@page.should have_pagination
	@page.should have_text "johndoe"
	@page.should have_text "admin"

	# Now, combine the filters
	@page.username_filter.click
	@page.wait_until_username_filter_menu_visible
	@page.username_filter_menu.click_link "johndoe"
	no_php_js_errors

	@page.perpage_filter.text.should eq "show (150)"
	@page.username_filter.text.should eq "username (johndoe)"
	@page.should have(35).items
	@page.should_not have_pagination
	@page.items.should_not have_text "admin"
  end

  it 'can combine phrase search with filters' do
	@page.perpage_filter.click
	@page.wait_until_perpage_filter_menu_visible
	@page.perpage_filter_menu.click_link "150"
	no_php_js_errors

  	# First, confirm we have both 'admin' and 'johndoe' on same page
	@page.perpage_filter.text.should eq "show (150)"
  	@page.should have(150).items
  	@page.should have_pagination
  	@page.should have_text "johndoe"
  	@page.should have_text "admin"

	# Now, combine the filters
	@page.phrase_search.set "johndoe"
	@page.submit_button.click
	no_php_js_errors

	@page.perpage_filter.text.should eq "show (150)"
	@page.phrase_search.value.should eq "johndoe"
	@page.should have(35).items
	@page.should_not have_pagination
	@page.items.should_not have_text "admin"
  end

  # Confirming the log deletion action
  it 'can remove a single entry' do
	our_action = "Rspec entry to be deleted"

	@page.generate_data(count: 1, timestamp_max: 0, action: our_action)
	@page.load

	log = @page.find('section.item-wrap div.item', :text => our_action)
	log.find('li.remove a').click
	no_php_js_errors

	@page.should have_alert
	@page.should have_no_content our_action
  end

  it 'can remove all entries' do
	@page.remove_all.click
	no_php_js_errors

	@page.should have_alert
	@page.should have_no_results
	@page.should_not have_pagination
  end

  # Confirming Pagination behavior
  it 'shows the Prev button when on page 2' do
	click_link "Next"
	no_php_js_errors

	@page.should have_pagination
	@page.should have(7).pages
	@page.pages.map {|name| name.text}.should == ["First", "Previous", "1", "2", "3", "Next", "Last"]
  end

  it 'does not show Next on the last page' do
	click_link "Last"
	no_php_js_errors

	@page.should have_pagination
	@page.should have(6).pages
	@page.pages.map {|name| name.text}.should == ["First", "Previous", "2", "3", "4", "Last"]
  end

it 'does not lose a filter value when paginating' do
	@page.perpage_filter.click
	@page.wait_until_perpage_filter_menu_visible
	@page.perpage_filter_menu.click_link "25"
	no_php_js_errors

	@page.perpage_filter.text.should eq "show (25)"
	@page.should have(25).items

	click_link "Next"
	no_php_js_errors

	@page.perpage_filter.text.should eq "show (25)"
	@page.should have(25).items
	@page.should have_pagination
	@page.should have(7).pages
	@page.pages.map {|name| name.text}.should == ["First", "Previous", "1", "2", "3", "Next", "Last"]
end

  it 'will paginate phrase search results' do
	@page.perpage_filter.click
	@page.wait_until_perpage_filter_menu_visible
	@page.perpage_filter_menu.click_link "25"
	no_php_js_errors

  	@page.phrase_search.set "johndoe"
  	@page.submit_button.click
	no_php_js_errors

  	# Page 1
  	@page.phrase_search.value.should eq "johndoe"
  	@page.items.should_not have_text "admin"
	@page.perpage_filter.text.should eq "show (25)"
  	@page.should have(25).items
  	@page.should have_pagination
  	@page.should have(5).pages
  	@page.pages.map {|name| name.text}.should == ["First", "1", "2", "Next", "Last"]

  	click_link "Next"
	no_php_js_errors

  	# Page 2
  	@page.phrase_search.value.should eq "johndoe"
  	@page.items.should_not have_text "admin"
	@page.perpage_filter.text.should eq "show (25)"
  	@page.should have(10).items
  	@page.should have_pagination
  	@page.should have(5).pages
  	@page.pages.map {|name| name.text}.should == ["First", "Previous", "1", "2", "Last"]
  end
end