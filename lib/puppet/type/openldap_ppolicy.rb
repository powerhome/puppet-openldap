Puppet::Type.newtype(:openldap_ppolicy) do
  @doc = "Manages OpenLDAP password policy."

  ensurable

  newparam(:name, :namevar => true) do
    desc "The database suffix."
  end
end
