require 'tempfile'

Puppet::Type.type(:openldap_ppolicy).provide(:olc) do
  defaultfor :operatingsystem => :debian

  # Provider commands
  commands :ldapsearch => 'ldapsearch', :ldapadd => 'ldapadd'

  mk_resource_methods

  def self.instances
    instances = []
    suffixes  = []

    # Get all databases
    databases = ldapsearch('-Q', '-LLL', '-Y', 'EXTERNAL', '-b', 'cn=config', '-H', 'ldapi:///', "(olcDbDirectory=*)").split("\n\n")

    # Extract every database suffix
    databases.each do |block|
      db_attrs = block.gsub("\n ", "").split("\n")
      db_attrs.each do |line|
        if line =~ /^olcSuffix: /
          suffix = line.split(' ')[1]
          suffixes << suffix
        end
      end
    end

    # Parse every database suffix
    suffixes.each do |suffix|

      # Password policy
      ppolicy = ldapsearch('-Q', '-LLL', '-Y', 'EXTERNAL', '-b', suffix, '-H', 'ldapi:///', "(entryDN:=cn=default,ou=policies,#{suffix})")

      # Does the policy exist
      unless ppolicy.empty?
        instances << new(
          :name   => suffix,
          :ensure => :present
        )
      end
    end
    instances
  end

  def self.prefetch(resources)
    trees = instances
    resources.keys.each do |name|
      if provider = trees.find{ |tree| tree.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create

    # Ppolicy LDIF
    t  = Tempfile.new("ldap_ppolicy")

    # Generate the ppolicy LDIF
    t << "dn: cn=default,ou=policies,#{resource[:name]}\n"
    t << "objectClass: top\n"
    t << "objectClass: person\n"
    t << "objectClass: pwdPolicy\n"
    t << "cn: default\n"
    t << "sn: Default Password Policy\n"
    t << "pwdAttribute: userPassword\n"
    t << "pwdAllowUserChange: TRUE\n"
    t << "pwdCheckQuality: 1\n"
    t << "pwdExpireWarning: 600\n"
    t << "pwdFailureCountInterval: 30\n"
    t << "pwdGraceAuthNLimit: 5\n"
    t << "pwdInHistory: 5\n"
    t << "pwdLockout: FALSE\n"
    t << "pwdLockoutDuration: 0\n"
    t << "pwdMaxAge: 0\n"
    t << "pwdMaxFailure: 5\n"
    t << "pwdMinAge: 0\n"
    t << "pwdMinLength: 5\n"
    t << "pwdMustChange: FALSE\n"
    t << "pwdSafeModify: FALSE\n"
    t.close()

    # Create the ppolicy
    ldapadd('-Y', 'EXTERNAL', '-H', 'ldapi:///', '-f', t.path)
  end

  def exists?
    @property_hash[:ensure] == :present
  end
end
