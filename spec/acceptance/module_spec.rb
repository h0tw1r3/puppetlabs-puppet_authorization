# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'module' do
  let(:pp) do
    <<~PP
    puppet_authorization { '/tmp/auth_no_hdr_certinfo.conf':
      version                => 1,
      allow_header_cert_info => false,
    }

    $auth_file = '/tmp/auth.conf'

    puppet_authorization { $auth_file:
      version                => 2,
      allow_header_cert_info => true,
    }

    puppet_authorization::rule { 'allow all authenticated for environments':
      ensure               => present,
      match_request_path   => '/puppet/v3/environments',
      match_request_type   => 'path',
      match_request_method => ['get','post'],
      allow                => '*',
      path                 => $auth_file,
    }

    puppet_authorization::rule { 'allow admin and own nodes for catalog':
      ensure               => present,
      match_request_path   => '^/puppet/v3/catalog/([^/]+)$',
      match_request_type   => 'regex',
      match_request_method => ['get','post'],
      allow                => ['admin.host.com', '$1', '/admins\.com$/'],
      path                 => $auth_file,
    }

    puppet_authorization::rule { 'allow everyone for certificate':
      ensure                => present,
      match_request_path    => '/puppet-ca/v1/certificate',
      match_request_type    => 'path',
      match_request_method  => 'get',
      allow_unauthenticated => true,
      path                  => $auth_file,
    }

    puppet_authorization::rule { 'deny all catalog for protected environments':
      ensure                     => present,
      match_request_path         => '/puppet/v3/catalog/',
      match_request_type         => 'path',
      match_request_query_params => {
      'environment' => ['secure', 'private'] },
      deny                       => '*',
      path                       => $auth_file,
      sort_order                 => 100,
    }

    puppet_authorization::rule { 'deny some shadowed by environment allow all':
      ensure             => present,
      match_request_path => '/puppet/v3/environments',
      match_request_type => 'path',
      deny               => ['denyone.host.com','/\.denydomain\.org$/'],
      path               => $auth_file,
      sort_order         => 750,
    }
    PP
  end

  it 'applies idempotently' do
    idempotent_apply(pp, debug: ENV.key?('DEBUG'))
  end
end
