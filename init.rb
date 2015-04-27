
require 'redmine'
require 'redmine/i18n'

require 'redmine_stealth'

unless RedmineStealth::USE_UJS
  require 'redmine_ext/menu_manager_extensions'
end

if Rails::VERSION::MAJOR >= 3
  require 'redmine_stealth/mail_interceptor'
else
  require 'action_mailer_ext/base_extensions'
end

require 'redmine_stealth/hooks'
require 'redmine_stealth/application_helper_extensions'
require 'redmine_stealth/user_extensions'

Redmine::Plugin.register :redmine_stealth do

  extend Redmine::I18n

  plugin_locale_glob = File.join(File.dirname(__FILE__), 'config', 'locales', '*.yml')
  ::I18n.load_path += Dir.glob(plugin_locale_glob)

  menu_options = {
      :html => {
          'id' => 'stealth_toggle',
          'data-failure-message' => l(RedmineStealth::MESSAGE_TOGGLE_FAILED)
      }
  }

  name        'Redmine Stealth Plugin'
  author      'Riley Lynch, Undev'
  description 'This plugin enables the Redmine administrator to disable email notifications temporarily.'
  version     '0.6.0'
  url 'https://github.com/Undev/redmine_stealth_modified'

  permission :toggle_stealth_mode, :stealth => :toggle

  toggle_url = { :controller => 'stealth', :action => 'toggle' }

  decide_toggle_display = lambda do |*_|
    can_toggle = false
    if user = ::User.current
      can_toggle = user.allowed_to?(toggle_url, nil, :global => true) && user.stealth_allowed?
    end
    can_toggle
  end

  stealth_menuitem_captioner = lambda do |project|
    is_cloaked = RedmineStealth.cloaked?
    RedmineStealth.status_label(is_cloaked)
  end

  if RedmineStealth::USE_UJS
    menu_options[:html].update('remote' => true, 'method' => :post)
  else
    menu_options[:remote] = {
        :method => :post,
        :failure => 'RedmineStealth.notifyFailure();',
        :with => %q{(function() {
        var $toggle = $('stealth_toggle');
        var params = $toggle.readAttribute('data-params-toggle');
        return params ? ('toggle=' + params) : '';
      })()}
    }
  end

  menu :account_menu, :stealth, toggle_url, {
      :first    => true,
      :if       => decide_toggle_display,
      :caption  => stealth_menuitem_captioner
  }.merge(menu_options)

end

